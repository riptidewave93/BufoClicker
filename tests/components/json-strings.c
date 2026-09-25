#include <assert.h>
#include <malloc.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <libcob.h>
#include "cJSON.h"
extern cob_field *J__STR(cob_field **, int, cob_field *, cob_field *);
int main(void) {
    cob_init_nomain(0, NULL);
    cob_field *result = NULL;
    cJSON *node = cJSON_CreateObject();
    cob_field root = {sizeof(node), (unsigned char *)&node, NULL};
    cob_field path = {4, (unsigned char *)"text", NULL};
    cJSON_AddStringToObject(node, "text", "small");
    J__STR(&result, 2, &root, &path);
    assert(result->size == 5 && memcmp(result->data, "small", 5) == 0);
    assert(malloc_usable_size(result->data) <= 64);
    const size_t lengths[] = {32768, 0, 512, 1, 32769, 23};
    for (size_t i = 0; i < sizeof(lengths) / sizeof(*lengths); i++) {
        const size_t length = lengths[i];
        char *text = malloc(length + 1);
        memset(text, 'x', length); text[length] = 0;
        cJSON_ReplaceItemInObject(node, "text", cJSON_CreateString(text));
        J__STR(&result, 2, &root, &path);
        size_t expected = length && length <= 32768 ? length : 1;
        assert(result->size == expected);
        assert(result->data[0] == (length && length <= 32768 ? 'x' : ' '));
        if (length && length <= 32768) assert(memcmp(result->data, text, length) == 0);
        free(text);
    }
    cob_free(result->data); cob_free(result); cJSON_Delete(node);
    puts("JSTR exact initial allocation, growth, shrink and limits passed");
    return 0;
}
