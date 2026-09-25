#include <stdio.h>
#include <stdlib.h>
#include <libcob.h>
#include "cJSON.h"
extern int BUFO__COMPONENTS(void*,void*,void*);
extern int BUFO__COMPONENT__RENDER(void*,void*,void*);
extern cob_field *J__NUM(cob_field**,const int,cob_field*,cob_field*);
extern cob_field *J__STR(cob_field**,const int,cob_field*,cob_field*);
int main(void) {
 cob_init_nomain(0,NULL); static cob_module m[2];
 m[0].module_name="J__NUM";m[0].module_entry.funcvoid=(void*)J__NUM;
 m[1].module_name="J__STR";m[1].module_entry.funcvoid=(void*)J__STR;
 cob_set_cancel(&m[0]);cob_set_cancel(&m[1]);
 cJSON *ctx=cJSON_CreateObject();char *line=NULL;size_t cap=0;
 while(getline(&line,&cap,stdin)>=0){cJSON *q=cJSON_Parse(line),*r=cJSON_CreateObject();
 cJSON *state=cJSON_GetObjectItem(q,"state");
 if(state){cJSON_DeleteItemFromObject(ctx,"state");cJSON_AddItemToObject(ctx,"state",cJSON_Duplicate(state,1));}
 if(cJSON_HasObjectItem(q,"component"))BUFO__COMPONENT__RENDER(q,ctx,r);else BUFO__COMPONENTS(q,ctx,r);char *s=cJSON_PrintUnformatted(r);puts(s);fflush(stdout);free(s);cJSON_Delete(q);cJSON_Delete(r);}
 free(line);cJSON_Delete(ctx);return 0;
}
