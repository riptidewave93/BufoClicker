#include "cJSON.h"
#include <assert.h>
#include <string.h>
int j_callback_roots(const cJSON *, cJSON *);
int main(void) {
    cJSON *context = cJSON_Parse("{\"a\":{\"$callback\":\"callback-1\"},\"nested\":[{\"$callback\":\"callback-1\"},{\"x\":{\"$callback\":\"callback-2\"}}],\"ordinary\":\"callback-3\",\"case\":{\"$callback\":\"Callback-1\"}}");
    cJSON *response = cJSON_CreateObject();
    assert(j_callback_roots(context, response) == 0);
    cJSON *roots = cJSON_GetObjectItemCaseSensitive(response, "callbackRoots");
    assert(cJSON_GetArraySize(roots) == 3);
    assert(strcmp(cJSON_GetArrayItem(roots, 0)->valuestring, "callback-1") == 0);
    assert(strcmp(cJSON_GetArrayItem(roots, 1)->valuestring, "callback-2") == 0);
    assert(j_callback_roots(NULL, response) == 0);
    assert(cJSON_GetArraySize(cJSON_GetObjectItemCaseSensitive(response, "callbackRoots")) == 0);
    cJSON_Delete(context);
    cJSON_Delete(response);
    return 0;
}
