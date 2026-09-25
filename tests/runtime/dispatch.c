#include <assert.h>
#include <string.h>
#include <libcob.h>
#include "cJSON.h"

extern const char *bufo_dispatch(const char *);
static int calls;

cob_field *J__NUM(cob_field **slot, const int count, cob_field *root, cob_field *path) {
    (void)slot; (void)count; (void)root; (void)path;
    return NULL;
}
cob_field *J__STR(cob_field **slot, const int count, cob_field *root, cob_field *path) {
    return J__NUM(slot, count, root, path);
}
int BUFO__APP(void *request, void *response) {
    (void)request;
    ++calls;
    if (calls == 1) {
        const char *nested = bufo_dispatch("{}");
        assert(calls == 1);
        cJSON *error = cJSON_Parse(nested);
        assert(error && cJSON_IsFalse(cJSON_GetObjectItem(error, "ok")));
        assert(strstr(cJSON_GetStringValue(cJSON_GetObjectItem(error, "error")), "active call"));
        cJSON_Delete(error);
    }
    cJSON_AddBoolToObject(response, "ok", 1);
    return 0;
}
int main(void) {
    assert(!strcmp(bufo_dispatch("{}"), "{\"ok\":true}"));
    assert(calls == 1);
    assert(!strcmp(bufo_dispatch("{}"), "{\"ok\":true}"));
    assert(calls == 2);
    return 0;
}
