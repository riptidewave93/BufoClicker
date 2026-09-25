#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libcob.h>
#include "cJSON.h"
extern int BUFO__GAME(void *, void *, void *);
extern cob_field *J__NUM(cob_field **, const int, cob_field *, cob_field *);
extern cob_field *J__STR(cob_field **, const int, cob_field *, cob_field *);
extern int j_read_file_into(const char *, void **);
extern int j_set_number(void *, const char *, const double *);
extern int j_merge(void *, void *);
const char *bufo_dispatch(const char *line) {
    static cJSON *context=NULL;
    static char *output=NULL;
    if(!context) {
    cob_init_nomain(0,NULL);
    static cob_module functions[2];
    functions[0].module_name="J__NUM"; functions[0].module_entry.funcvoid=(void*)J__NUM;
    functions[1].module_name="J__STR"; functions[1].module_entry.funcvoid=(void*)J__STR;
    cob_set_cancel(&functions[0]); cob_set_cancel(&functions[1]);
    context=cJSON_CreateObject(); cJSON *catalog=cJSON_CreateObject();
    const char *names[]={"generators","upgrades","achievements","bosses"};
    for(int i=0;i<4;i++) {
        char path[128]; snprintf(path,sizeof(path),"assets/data/%s.json",names[i]);
        void *data=NULL; j_read_file_into(path,&data);
        if(!data) return "{\"ok\":false,\"error\":\"catalog missing\"}";
        cJSON_AddItemToObject(catalog,names[i],data);
    }
    cJSON_AddItemToObject(context,"catalog",catalog);
    cJSON_AddItemToObject(context,"runtime",cJSON_CreateObject());
    cJSON_AddItemToObject(context,"events",cJSON_CreateArray());
    cJSON_AddItemToObject(context,"state",cJSON_CreateObject());
    }
    free(output); output=NULL;
        cJSON *request=cJSON_Parse(line), *response=cJSON_CreateObject();
        const cJSON *operation=cJSON_GetObjectItemCaseSensitive(request,"operation");
        if (!request || !cJSON_IsString(operation)) return "{\"ok\":false}";
        double now=cJSON_GetNumberValue(cJSON_GetObjectItemCaseSensitive(request,"now")), zero=0;
        j_set_number(context,"runtime.now",&now); j_set_number(context,"runtime.randomIndex",&zero);
        cJSON_ReplaceItemInObject(context,"events",cJSON_CreateArray());
        if(!strcmp(operation->valuestring,"test.context")) {
            cJSON_AddBoolToObject(response,"ok",1);
            cJSON_AddItemToObject(response,"result",cJSON_Duplicate(context,1));
        } else if(!strcmp(operation->valuestring,"test.replaceState")) {
            cJSON_ReplaceItemInObject(context,"state",cJSON_Duplicate(cJSON_GetObjectItemCaseSensitive(request,"args"),1));
            cJSON_AddBoolToObject(response,"ok",1);
        } else BUFO__GAME(request,context,response);
        output=cJSON_PrintUnformatted(response);
        cJSON_Delete(response); cJSON_Delete(request);
        return output;
}
#ifndef __EMSCRIPTEN__
int main(void) {
    char *line=NULL; size_t capacity=0;
    while(getline(&line,&capacity,stdin)>=0) { puts(bufo_dispatch(line)); fflush(stdout); }
    free(line); cob_tidy(); return 0;
}
#endif
