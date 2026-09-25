#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <limits.h>
#include "cJSON.h"

void *j_get(void *root, const char *path) {
    cJSON *node = root;
    if (!path || !*path) return node;
    char *parts = strdup(path), *part = parts, *next;
    if (!parts) return NULL;
    do {
        next = strchr(part, '.');
        if (next) *next++ = '\0';
        if (cJSON_IsArray(node)) {
            char *end;
            long index = strtol(part, &end, 10);
            node = (*part && !*end && index >= 0 && index <= 2147483647L) ? cJSON_GetArrayItem(node, (int)index) : NULL;
        } else node = cJSON_GetObjectItemCaseSensitive(node, part);
        part = next;
    } while (node && part);
    free(parts);
    return node;
}
int j_has(void *root, const char *path) { return j_get(root, path) != NULL; }
int j_type(void *root, const char *path) {
    cJSON *node = j_get(root,path);
    if (cJSON_IsBool(node)) return 1;
    if (cJSON_IsNumber(node)) return 2;
    if (cJSON_IsString(node)) return 3;
    if (cJSON_IsArray(node)) return 4;
    if (cJSON_IsObject(node)) return 5;
    return 0;
}
int j_number(void *root, const char *path, double *out) {
    cJSON *node=j_get(root,path);
    *out=cJSON_IsNumber(node) ? node->valuedouble : 0;
 return 0; }
int j_boolean(void *root,const char *path) { return cJSON_IsTrue(j_get(root,path)); }
static int padded(const char *s, char *out, int capacity) {
    if (capacity < 0 || !out) return -1;
    memset(out, ' ', (size_t)capacity);
    if (!s) return 0;
    size_t length = strlen(s);
    if (length > (size_t)capacity) return -1;
    memcpy(out, s, length);
    return 0;
}
int j_string(void *root, const char *path, char *out, int capacity) {
    return padded(cJSON_GetStringValue(j_get(root, path)), out, capacity);
}
int j_size(void *root,const char *path) { return cJSON_GetArraySize(j_get(root,path)); }
void *j_at(void *root,int index) { return cJSON_GetArrayItem(root,index); }
int j_key(void *node,char *out,int capacity) { return padded(node ? ((cJSON*)node)->string : NULL,out,capacity); }
void *j_object(void) { return cJSON_CreateObject(); }
void *j_array(void) { return cJSON_CreateArray(); }
void *j_clone(void *node) { return cJSON_Duplicate(node,1); }
int j_delete(void *node) { cJSON_Delete(node);  return 0; }
static int valid_path(const char *path) {
    return path && *path && *path != '.' && path[strlen(path) - 1] != '.' && !strstr(path, "..");
}

/* Transfers ownership of value on both success and failure. */
int j_set(void *root, const char *path, void *value) {
    if (!value || !cJSON_IsObject(root) || !valid_path(path)) {
        cJSON_Delete(value);
        return -1;
    }
    char *parts = strdup(path);
    if (!parts) { cJSON_Delete(value); return -1; }
    char *part = parts, *next;
    cJSON *node = root;
    int status = -1;
    while ((next = strchr(part, '.'))) {
        *next++ = 0;
        cJSON *child = cJSON_GetObjectItemCaseSensitive(node, part);
        if (!child) {
            child = cJSON_CreateObject();
            if (!child || !cJSON_AddItemToObject(node, part, child)) {
                cJSON_Delete(child);
                goto done;
            }
        }
        if (!cJSON_IsObject(child)) goto done;
        node = child;
        part = next;
    }
    int ok = cJSON_HasObjectItem(node, part)
        ? cJSON_ReplaceItemInObjectCaseSensitive(node, part, value)
        : cJSON_AddItemToObject(node, part, value);
    if (ok) { value = NULL; status = 0; }
done:
    cJSON_Delete(value);
    free(parts);
    return status;
}
int j_set_number(void *root, const char *path, const double *value) {
    return value && isfinite(*value) ? j_set(root, path, cJSON_CreateNumber(*value)) : -1;
}
int j_set_null(void *root, const char *path) {
    return j_set(root, path, cJSON_CreateNull());
}
int j_set_boolean(void *root, const char *path, int value) {
    return j_set(root, path, cJSON_CreateBool(value));
}
int j_set_string(void *root, const char *path, const char *value, int length) {
    if (!value || length < 0 || memchr(value, 0, (size_t)length)) return -1;
    char *text = malloc((size_t)length + 1);
    if (!text) return -1;
    memcpy(text, value, (size_t)length);
    text[length] = 0;
    cJSON *node = cJSON_CreateString(text);
    free(text);
    return j_set(root, path, node);
}
int j_remove(void *root, const char *path) {
    if (!cJSON_IsObject(root) || !valid_path(path)) return -1;
    char *copy = strdup(path);
    if (!copy) return -1;
    char *key = copy, *next;
    cJSON *node = root;
    while ((next = strchr(key, '.'))) {
        *next++ = 0;
        node = cJSON_GetObjectItemCaseSensitive(node, key);
        if (!cJSON_IsObject(node)) { free(copy); return -1; }
        key = next;
    }
    cJSON_DeleteItemFromObjectCaseSensitive(node, key);
    free(copy);
    return 0;
}
int j_append(void *array, void *value) {
    if (!cJSON_IsArray(array) || !value || !cJSON_AddItemToArray(array, value)) {
        cJSON_Delete(value);
        return -1;
    }
    return 0;
}
static int finite_json(const cJSON *node) {
    if (!node) return 0;
    if (cJSON_IsNumber(node) && !isfinite(node->valuedouble)) return 0;
    for (const cJSON *child = node->child; child; child = child->next) {
        if (!finite_json(child)) return 0;
        if (cJSON_IsObject(node)) {
            for (const cJSON *other = child->next; other; other = other->next)
                if (!strcmp(child->string, other->string)) return 0;
        }
    }
    return 1;
}
void *j_parse(const char *input, int length) {
    if (!input || length < 0) return NULL;
    char *text = malloc((size_t)length + 1);
    if (!text) return NULL;
    memcpy(text, input, (size_t)length);
    text[length] = 0;
    cJSON *result = memchr(text, 0, (size_t)length) ? NULL : cJSON_ParseWithOpts(text, NULL, 1);
    free(text);
    if (result && !finite_json(result)) { cJSON_Delete(result); result = NULL; }
    return result;
}
int j_print(void *node, char *out, int capacity) {
    if (padded(NULL, out, capacity) || !finite_json(node)) return -1;
    char *json = cJSON_PrintUnformatted(node);
    if (!json) return -1;
    int status = padded(json, out, capacity);
    free(json);
    return status;
}

int j_get_into(void *root,const char *path,void **out) { *out=j_get(root,path);return 0; }
void *j_read_file(const char *path) {
    FILE *file=fopen(path,"rb");if(!file)return NULL;
    if(fseek(file,0,SEEK_END)){fclose(file);return NULL;}
    long length=ftell(file);if(length<0 || fseek(file,0,SEEK_SET)){fclose(file);return NULL;}
    char *content=malloc((size_t)length+1);if(!content){fclose(file);return NULL;}
    size_t read=fread(content,1,(size_t)length,file);fclose(file);content[read]=0;
    cJSON *result=read==(size_t)length && length <= INT_MAX ? j_parse(content,(int)length) : NULL;
    free(content);return result;
}
int j_at_into(void *root,int index,void **out) { *out=j_at(root,index);return 0; }
int j_object_into(void **out) { *out=j_object();return *out ? 0 : -1; }
int j_array_into(void **out) { *out=j_array();return *out ? 0 : -1; }
int j_clone_into(void *node,void **out) { *out=j_clone(node);return *out ? 0 : -1; }
int j_parse_into(const char *input,int length,void **out) { *out=j_parse(input,length);return *out ? 0 : -1; }
int j_read_file_into(const char *path,void **out) { *out=j_read_file(path);return *out ? 0 : -1; }
int j_merge(void *target, void *source) {
    if (!cJSON_IsObject(target) || !cJSON_IsObject(source)) return -1;
    if (target == source) return 0;
    cJSON *snapshot = cJSON_Duplicate(source, 1);
    if (!snapshot) return -1;
    for (const cJSON *child = snapshot->child; child; child = child->next) {
        cJSON *value = cJSON_Duplicate(child, 1);
        if (!value) { cJSON_Delete(snapshot); return -1; }
        int ok = cJSON_HasObjectItem(target, child->string)
            ? cJSON_ReplaceItemInObjectCaseSensitive(target, child->string, value)
            : cJSON_AddItemToObject(target, child->string, value);
        if (!ok) { cJSON_Delete(value); cJSON_Delete(snapshot); return -1; }
    }
    cJSON_Delete(snapshot);
    return 0;
}

/* Compare JSON values without the epsilon tolerance used by cJSON_Compare. */
int j_equal(void *left, void *right) {
    cJSON *a = left, *b = right;
    if (!a || !b) return a == b;
    if ((a->type & 255) != (b->type & 255)) return 0;
    if (cJSON_IsNumber(a)) return a->valuedouble == b->valuedouble;
    if (cJSON_IsString(a)) return strcmp(a->valuestring, b->valuestring) == 0;
    if (cJSON_IsArray(a) || cJSON_IsObject(a)) {
        cJSON *x = a->child, *y = b->child;
        while (x && y) {
            if (cJSON_IsObject(a) && strcmp(x->string, y->string)) return 0;
            if (!j_equal(x, y)) return 0;
            x = x->next; y = y->next;
        }
        return !x && !y;
    }
    return 1;
}
