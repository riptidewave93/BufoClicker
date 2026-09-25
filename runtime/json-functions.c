#include <stddef.h>
#include <libcob.h>
#include <string.h>
#include "cJSON.h"

extern void *j_get(void *, const char *);
extern int j_number(void *, const char *, double *);
extern int j_string(void *, const char *, char *, int);

static const cob_field_attr number_attribute = {
    COB_TYPE_NUMERIC_DOUBLE, 34, 17, COB_FLAG_HAVE_SIGN | COB_FLAG_IS_FP, NULL
};
static const cob_field_attr string_attribute = {
    COB_TYPE_ALPHANUMERIC, 0, 0, 0, NULL
};

/* The field is first so generated callers can free it through cob_field *.
   Capacity is separate from the logical string length across loop iterations. */
struct owned_return_field {
    cob_field field;
    size_t capacity;
};

static cob_field *return_field(cob_field **slot, size_t size,
                               const cob_field_attr *attribute) {
    struct owned_return_field *owned = (struct owned_return_field *)*slot;
    if (!owned) {
        owned = cob_malloc(sizeof(*owned));
        owned->field.data = cob_malloc(size);
        owned->capacity = size;
        *slot = &owned->field;
    } else if (owned->capacity < size) {
        cob_free(owned->field.data);
        owned->field.data = cob_malloc(size);
        owned->capacity = size;
    }
    owned->field.size = size;
    owned->field.attr = attribute;
    return &owned->field;
}

static void *arguments(int count, const cob_field *root, const cob_field *path,
                       char *path_text, size_t capacity) {
    path_text[0] = 0;
    if (count < 2 || !root || !path || root->size != sizeof(void *)) return NULL;
    size_t first = 0, last = path->size;
    while (first < last && path->data[first] == ' ') ++first;
    while (last > first && path->data[last - 1] == ' ') --last;
    if (last - first >= capacity) return NULL;
    memcpy(path_text, path->data + first, last - first);
    path_text[last - first] = 0;
    void *node;
    memcpy(&node, root->data, sizeof(node));
    return node;
}

cob_field *J__NUM(cob_field **slot, const int count, cob_field *root, cob_field *path) {
    cob_field *result = return_field(slot, sizeof(double), &number_attribute);
    char path_text[4096];
    void *node = arguments(count, root, path, path_text, sizeof(path_text));
    double value = 0;
    j_number(node, path_text, &value);
    memcpy(result->data, &value, sizeof(value));
    return result;
}

cob_field *J__STR(cob_field **slot, const int count, cob_field *root, cob_field *path) {
    char path_text[4096];
    void *node = arguments(count, root, path, path_text, sizeof(path_text));
    const char *text = cJSON_GetStringValue(j_get(node, path_text));
    size_t length = text ? strlen(text) : 0;
    if (length > 32768) length = 0;
    cob_field *result = return_field(slot, length ? length : 1, &string_attribute);
    if (length) memcpy(result->data, text, length);
    else result->data[0] = ' ';
    result->size = length ? length : 1;
    return result;
}
