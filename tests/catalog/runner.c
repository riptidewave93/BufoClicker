#include <stdio.h>
#include <stdlib.h>
#include <libcob.h>
#include "cJSON.h"
extern int BUFO__VALIDATE__CATALOGS(void*,void*,void*);
extern cob_field *J__NUM(cob_field**,const int,cob_field*,cob_field*);
extern cob_field *J__STR(cob_field**,const int,cob_field*,cob_field*);
int main(void){
 cob_init_nomain(0,NULL);static cob_module m[2];m[0].module_name="J__NUM";m[0].module_entry.funcvoid=(void*)J__NUM;m[1].module_name="J__STR";m[1].module_entry.funcvoid=(void*)J__STR;cob_set_cancel(&m[0]);cob_set_cancel(&m[1]);
 char *line=NULL;size_t cap=0;while(getline(&line,&cap,stdin)>0){cJSON *ctx=cJSON_Parse(line),*req=cJSON_CreateObject(),*res=cJSON_CreateObject();BUFO__VALIDATE__CATALOGS(req,ctx,res);char *out=cJSON_PrintUnformatted(res);puts(out);fflush(stdout);free(out);cJSON_Delete(req);cJSON_Delete(ctx);cJSON_Delete(res);}free(line);cob_tidy();return 0;
}
