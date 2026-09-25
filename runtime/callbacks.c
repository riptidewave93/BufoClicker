#include "cJSON.h"

/* Report callback handles retained by a JSON ownership graph. */
static int collect(const cJSON *node, cJSON *roots, cJSON *seen) {
    for (; node; node = node->next) {
        if (cJSON_IsObject(node)) {
            const cJSON *token = cJSON_GetObjectItemCaseSensitive(node, "$callback");
            if (cJSON_IsString(token) && !cJSON_GetObjectItemCaseSensitive(seen, token->valuestring)) {
                cJSON *copy = cJSON_CreateString(token->valuestring);
                if (!copy || !cJSON_AddItemToArray(roots, copy)) {
                    cJSON_Delete(copy);
                    return 0;
                }
                if (!cJSON_AddBoolToObject(seen, token->valuestring, 1)) return 0;
            }
        }
        if (node->child && !collect(node->child, roots, seen)) return 0;
    }
    return 1;
}

int j_callback_roots(const cJSON *context, cJSON *response) {
    cJSON *roots = cJSON_CreateArray(), *seen = cJSON_CreateObject();
    if (!roots || !seen || !collect(context, roots, seen)) {
        cJSON_Delete(roots);
        cJSON_Delete(seen);
        return -1;
    }
    cJSON_Delete(seen);
    cJSON_DeleteItemFromObjectCaseSensitive(response, "callbackRoots");
    if (!cJSON_AddItemToObject(response, "callbackRoots", roots)) {
        cJSON_Delete(roots);
        return -1;
    }
    return 0;
}
