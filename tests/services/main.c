#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libcob.h>
#include "cJSON.h"
extern int BUFO__SERVICES(void*,void*,void*);
extern cob_field *J__NUM(cob_field**,const int,cob_field*,cob_field*);
extern cob_field *J__STR(cob_field**,const int,cob_field*,cob_field*);

const char *service_dispatch(const char *line) {
 static cJSON *ctx;
 static char *output;
 if(!ctx){
  cob_init_nomain(0,NULL);static cob_module m[2];
  m[0].module_name="J__NUM";m[0].module_entry.funcvoid=(void*)J__NUM;
  m[1].module_name="J__STR";m[1].module_entry.funcvoid=(void*)J__STR;
  cob_set_cancel(&m[0]);cob_set_cancel(&m[1]);ctx=cJSON_CreateObject();
 }
 cJSON *q=cJSON_Parse(line),*r=cJSON_CreateObject();
 cJSON *rt=cJSON_GetObjectItem(ctx,"runtime");
 if(!rt){rt=cJSON_CreateObject();cJSON_AddItemToObject(ctx,"runtime",rt);}
 cJSON_DeleteItemFromObject(rt,"randomIndex");cJSON_AddNumberToObject(rt,"randomIndex",0);
 cJSON *seed=cJSON_GetObjectItem(q,"testDefaultState");
 if(seed){cJSON_DeleteItemFromObject(rt,"defaultState");cJSON_AddItemToObject(rt,"defaultState",cJSON_Duplicate(seed,1));}
 BUFO__SERVICES(q,ctx,r);
 free(output);output=cJSON_PrintUnformatted(r);cJSON_Delete(q);cJSON_Delete(r);
 return output;
}
#ifndef __EMSCRIPTEN__
int main(void) {
 char *line=NULL;size_t cap=0;
 while(getline(&line,&cap,stdin)>=0){puts(service_dispatch(line));fflush(stdout);}
 free(line);return 0;
}
#endif
