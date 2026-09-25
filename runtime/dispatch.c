#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libcob.h>
#include "cJSON.h"

extern void *j_parse(const char *, int);
extern int BUFO__APP(void *, void *);
extern cob_field *J__NUM(cob_field **, const int, cob_field *, cob_field *);
extern cob_field *J__STR(cob_field **, const int, cob_field *, cob_field *);

/* Register statically linked COBOL functions without a dynamic loader. */
static void register_functions(void) {
    static cob_module modules[2];
    modules[0].module_name = "J__NUM";
    modules[0].module_entry.funcvoid = (void *)J__NUM;
    modules[1].module_name = "J__STR";
    modules[1].module_entry.funcvoid = (void *)J__STR;
    for (int i = 0; i < 2; i++) cob_set_cancel(&modules[i]);
}

/* The caller must copy the result before the next dispatch. */
const char *bufo_dispatch(const char *input) {
    static int initialized = 0;
    static int active = 0;
    static char *output = NULL;
    if (active) return "{\"ok\":false,\"error\":\"Runtime dispatch cannot reenter an active call.\"}";
    active = 1;
    if (!initialized) {
        cob_init_nomain(0, NULL);
        register_functions();
        initialized = 1;
    }
    free(output);
    output = NULL;
    size_t length = input ? strlen(input) : 0;
    cJSON *request = input && length <= INT_MAX ? j_parse(input, (int)length) : NULL;
    cJSON *response = cJSON_CreateObject();
    if (!response) {
        cJSON_Delete(request);
        active = 0;
        return "{\"ok\":false,\"error\":\"Memory allocation failed\"}";
    }
    if (request) {
        BUFO__APP(request, response);
    } else {
        cJSON_AddBoolToObject(response, "ok", 0);
        cJSON_AddStringToObject(response, "error", "Invalid JSON");
    }
    output = cJSON_PrintUnformatted(response);
    cJSON_Delete(request);
    cJSON_Delete(response);
    active = 0;
    return output ? output : "{\"ok\":false,\"error\":\"JSON encoding failed\"}";
}

#ifndef __EMSCRIPTEN__
int main(void) {
    char *line = NULL;
    size_t capacity = 0;
    while (getline(&line, &capacity, stdin) >= 0) {
        puts(bufo_dispatch(line));
        fflush(stdout);
    }
    free(line);
    return 0;
}
#endif
