#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "cJSON.h"

#define TEXT_LIMIT (5u * 1024u * 1024u)
extern void *j_parse(const char *, int);

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
EM_JS(char *, storage_read_text, (const char *key, int *status), {
    try {
        const value = localStorage.getItem(UTF8ToString(key));
        HEAP32[status >> 2] = value === null ? 0 : 1;
        return value === null ? 0 : stringToNewUTF8(value);
    } catch (_) { HEAP32[status >> 2] = -1; return 0; }
});
EM_JS(int, storage_write_text, (const char *key, const char *value), {
    try { localStorage.setItem(UTF8ToString(key), UTF8ToString(value)); return 0; }
    catch (_) { return -1; }
});
EM_JS(int, storage_remove_text, (const char *key), {
    try { localStorage.removeItem(UTF8ToString(key)); return 0; }
    catch (_) { return -1; }
});
int h_storage_fault(int reads, int writes) { (void)reads; (void)writes; return -1; }
#else
struct entry { char *key, *value; struct entry *next; };
static struct entry *entries;
static int read_fault, write_fault;
static struct entry *lookup(const char *key) {
    for (struct entry *p = entries; p; p = p->next)
        if (!strcmp(p->key, key)) return p;
    return NULL;
}
static char *storage_read_text(const char *key, int *status) {
    if (read_fault) { *status = -1; return NULL; }
    struct entry *p = lookup(key);
    *status = p ? 1 : 0;
    return p ? strdup(p->value) : NULL;
}
static int storage_write_text(const char *key, const char *value) {
    if (write_fault) return -1;
    char *copy = strdup(value);
    if (!copy) return -1;
    struct entry *p = lookup(key);
    if (!p) {
        p = calloc(1, sizeof(*p));
        if (!p) { free(copy); return -1; }
        p->key = strdup(key);
        if (!p->key) { free(p); free(copy); return -1; }
        p->next = entries; entries = p;
    }
    free(p->value); p->value = copy;
    return 0;
}
static int storage_remove_text(const char *key) {
    if (write_fault) return -1;
    struct entry **link = &entries;
    while (*link) {
        struct entry *p = *link;
        if (!strcmp(p->key, key)) {
            *link = p->next;
            free(p->key); free(p->value); free(p); return 0;
        }
        link = &p->next;
    }
    return 0;
}
int h_storage_fault(int reads, int writes) {
    read_fault = reads; write_fault = writes; return 0;
}
#endif

/* Return an owned JSON string, preserving absent, empty and unreadable values. */
int h_storage_read(const char *key, void **out, int *status) {
    *out = NULL;
    char *text = storage_read_text(key, status);
    if (*status == 1 && (!text || strlen(text) > TEXT_LIMIT)) *status = -1;
    if (*status == 1) {
        *out = cJSON_CreateString(text);
        if (!*out) *status = -1;
    }
    free(text);
    return *status < 0 ? -1 : 0;
}
int h_storage_write(const char *key, void *raw) {
    const char *text = cJSON_GetStringValue(raw);
    return text && strlen(text) <= TEXT_LIMIT ? storage_write_text(key, text) : -1;
}
int h_storage_write_json(const char *key, void *value) {
    char *text = cJSON_PrintUnformatted(value);
    if (!text) return -1;
    int result = strlen(text) <= TEXT_LIMIT ? storage_write_text(key, text) : -1;
    free(text); return result;
}
int h_storage_remove(const char *key) { return storage_remove_text(key); }
int h_json_parse_value(void *raw, void **out) {
    const char *text = cJSON_GetStringValue(raw);
    *out = text && strlen(text) <= TEXT_LIMIT ? j_parse(text, (int)strlen(text)) : NULL;
    return *out ? 0 : -1;
}
int h_json_stringify_value(void *value, void **out) {
    char *text = cJSON_PrintUnformatted(value);
    *out = text ? cJSON_CreateString(text) : NULL;
    free(text); return *out ? 0 : -1;
}

static const char base64_alphabet[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static int uri_plain(unsigned char ch) {
    return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') ||
           (ch >= '0' && ch <= '9') || strchr("-_.!~*'()", ch) != NULL;
}
/* Match btoa(encodeURIComponent(text)) used by existing exports. */
int h_encode_uri64(void *input, void **out) {
    *out = NULL;
    const char *text = cJSON_GetStringValue(input);
    if (!text || strlen(text) > TEXT_LIMIT) return -1;
    size_t length = strlen(text), used = 0;
    char *uri = malloc(length * 3 + 1);
    if (!uri) return -1;
    static const char hex[] = "0123456789ABCDEF";
    for (size_t i = 0; i < length; ++i) {
        unsigned char ch = (unsigned char)text[i];
        if (uri_plain(ch)) uri[used++] = (char)ch;
        else { uri[used++] = '%'; uri[used++] = hex[ch >> 4]; uri[used++] = hex[ch & 15]; }
    }
    size_t encoded_length = 4 * ((used + 2) / 3);
    char *encoded = malloc(encoded_length + 1);
    if (!encoded) { free(uri); return -1; }
    size_t j = 0;
    for (size_t i = 0; i < used; i += 3) {
        unsigned value = (unsigned char)uri[i] << 16;
        if (i + 1 < used) value |= (unsigned char)uri[i + 1] << 8;
        if (i + 2 < used) value |= (unsigned char)uri[i + 2];
        encoded[j++] = base64_alphabet[value >> 18];
        encoded[j++] = base64_alphabet[(value >> 12) & 63];
        encoded[j++] = i + 1 < used ? base64_alphabet[(value >> 6) & 63] : '=';
        encoded[j++] = i + 2 < used ? base64_alphabet[value & 63] : '=';
    }
    encoded[j] = 0;
    *out = cJSON_CreateString(encoded);
    free(encoded); free(uri);
    return *out ? 0 : -1;
}
static int unhex(char ch) {
    if (ch >= '0' && ch <= '9') return ch - '0';
    if (ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
    if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
    return -1;
}
int h_decode_uri64(void *input, void **out) {
    *out = NULL;
    const char *text = cJSON_GetStringValue(input);
    if (!text || strlen(text) > TEXT_LIMIT * 4u) return -1;
    size_t length = strlen(text), used = 0;
    char *decoded = malloc(length + 1);
    if (!decoded) return -1;
    unsigned bits = 0; int available = 0, padding = 0, invalid = 0;
    for (size_t i = 0; i < length && !invalid; ++i) {
        unsigned char ch = (unsigned char)text[i];
        if (ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t') continue;
        if (ch == '=') { if (++padding > 2) invalid = 1; continue; }
        const char *found = strchr(base64_alphabet, ch);
        if (!ch || !found || padding) { invalid = 1; break; }
        bits = (bits << 6) | (unsigned)(found - base64_alphabet);
        available += 6;
        if (available >= 8) { available -= 8; decoded[used++] = (char)(bits >> available); }
    }
    if (available == 6 || (available && (bits & ((1u << available) - 1u)))) invalid = 1;
    decoded[used] = 0;
    size_t output_length = 0;
    for (size_t i = 0; i < used && !invalid; ++i) {
        unsigned char ch = (unsigned char)decoded[i];
        if (ch == '%') {
            if (i + 2 >= used || unhex(decoded[i + 1]) < 0 || unhex(decoded[i + 2]) < 0) {
                invalid = 1; break;
            }
            ch = (unsigned char)(unhex(decoded[i + 1]) * 16 + unhex(decoded[i + 2]));
            i += 2;
        }
        if (!ch) { invalid = 1; break; }
        decoded[output_length++] = (char)ch;
    }
    decoded[output_length] = 0;
    if (!invalid && output_length <= TEXT_LIMIT) *out = cJSON_CreateString(decoded);
    free(decoded);
    return *out ? 0 : -1;
}

#ifdef __EMSCRIPTEN__
EM_JS(int, h_storage_clear_all, (void), {
    try { localStorage.clear(); return 0; } catch (_) { return -1; }
});
EM_JS(int, h_storage_size, (double *out), {
    try {
        let size = 0;
        for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            if (key) size += key.length + (localStorage.getItem(key) || '').length;
        }
        HEAPF64[out >> 3] = size * 2; return 0;
    } catch (_) { HEAPF64[out >> 3] = 0; return -1; }
});
#else
int h_storage_clear_all(void) {
    if (write_fault) return -1;
    while (entries) {
        struct entry *next = entries->next;
        free(entries->key); free(entries->value); free(entries); entries = next;
    }
    return 0;
}
static size_t utf16_length(const char *text) {
    size_t count = 0;
    for (const unsigned char *p = (const unsigned char *)text; *p; p++) {
        if ((*p & 0xc0) != 0x80) count += *p >= 0xf0 ? 2 : 1;
    }
    return count;
}
int h_storage_size(double *out) {
    *out = 0;
    if (read_fault) return -1;
    for (struct entry *p = entries; p; p = p->next)
        *out += 2.0 * (utf16_length(p->key) + utf16_length(p->value));
    return 0;
}
#endif
int h_storage_available(void) {
    const char *key = "__storage_test__";
    if (storage_write_text(key, key)) return 0;
    int status = 0;
    char *value = storage_read_text(key, &status);
    int available = status == 1 && value && !strcmp(value, key);
    free(value);
    if (storage_remove_text(key)) available = 0;
    return available;
}
