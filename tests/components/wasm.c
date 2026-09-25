#include <stdlib.h>
#include <string.h>
#include <libcob.h>
#include "cJSON.h"
extern int BUFO__UI(void*,void*,void*);
extern int BUFO__COMPONENTS(void*,void*,void*);
extern cob_field *J__NUM(cob_field**,const int,cob_field*,cob_field*);
extern cob_field *J__STR(cob_field**,const int,cob_field*,cob_field*);
const char *bufo_dispatch(const char *input){
 static int initialized;static cJSON *ctx;static char *output;
 if(!initialized){cob_init_nomain(0,NULL);static cob_module m[2];m[0].module_name="J__NUM";m[0].module_entry.funcvoid=(void*)J__NUM;m[1].module_name="J__STR";m[1].module_entry.funcvoid=(void*)J__STR;cob_set_cancel(&m[0]);cob_set_cancel(&m[1]);ctx=cJSON_CreateObject();initialized=1;}
 free(output);cJSON *q=cJSON_Parse(input),*res=cJSON_CreateObject();
 cJSON *state=cJSON_GetObjectItem(q,"state");if(state){cJSON_DeleteItemFromObject(ctx,"state");cJSON_AddItemToObject(ctx,"state",cJSON_Duplicate(state,1));}
 cJSON *context=cJSON_GetObjectItem(q,"context"),*entry=NULL; cJSON_ArrayForEach(entry,context){cJSON_DeleteItemFromObject(ctx,entry->string);cJSON_AddItemToObject(ctx,entry->string,cJSON_Duplicate(entry,1));}
 const char *op=cJSON_GetStringValue(cJSON_GetObjectItem(q,"operation"));if(op && !strncmp(op,"ui.render",9)) BUFO__UI(q,ctx,res);else BUFO__COMPONENTS(q,ctx,res);output=cJSON_PrintUnformatted(res);cJSON_Delete(q);cJSON_Delete(res);return output;
}
