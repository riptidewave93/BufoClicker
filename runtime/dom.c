/* Synchronous generic DOM boundary. UI decisions remain in COBOL. */
#include "cJSON.h"
#include <stdlib.h>
#include <string.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
EM_JS(char *, dom_invoke, (const char *input), {
 const command = JSON.parse(UTF8ToString(input));
 if (!globalThis.bufoDomBridge) return stringToNewUTF8(JSON.stringify({$error:'DOM bridge is unavailable'}));
 try { return stringToNewUTF8(JSON.stringify(globalThis.bufoDomBridge(command) ?? null)); }
 catch (error) { return stringToNewUTF8(JSON.stringify({$error:String(error.message || error)})); }
});
#endif
int h_dom(cJSON *request, cJSON *command, cJSON **out) {
 *out = NULL;
#ifdef __EMSCRIPTEN__
 char *input=cJSON_PrintUnformatted(command);
 if(!input) return -1;
 char *result=dom_invoke(input); free(input);
 if(result){*out=cJSON_Parse(result);free(result);}
#else
 cJSON *index=cJSON_GetObjectItemCaseSensitive(request,"_domIndex");
 int n=cJSON_IsNumber(index)?index->valueint:0;
 cJSON *fixture=cJSON_GetArrayItem(cJSON_GetObjectItemCaseSensitive(request,"domResults"),n);
 if(index)cJSON_SetNumberValue(index,n+1);else cJSON_AddNumberToObject(request,"_domIndex",n+1);
 if(fixture)*out=cJSON_Duplicate(fixture,1);
 else {
  *out=cJSON_CreateObject();
  cJSON_AddStringToObject(*out,"$error","DOM operation requires a browser or explicit native domResults");
 }
#endif
 if(!*out)*out=cJSON_CreateNull();
 return cJSON_HasObjectItem(*out,"$error")?-1:0;
}
#include <stdio.h>
#include <ctype.h>
int h_css_parse(cJSON *value,double *number,char *unit,int capacity) {
 memset(unit,' ',capacity); *number=0;
 if(cJSON_IsNumber(value)){*number=value->valuedouble;return 1;}
 const char *s=cJSON_GetStringValue(value);if(!s)return 0;
 const char *p=s;if(*p=='-')p++;
 int digits=0;while(isdigit((unsigned char)*p)){digits++;p++;}
 if(*p=='.'){p++;while(isdigit((unsigned char)*p)){digits++;p++;}}
 if(!digits)return 0;
 *number=strtod(s,NULL);
 const char *q=p;while(isalpha((unsigned char)*q)||*q=='%')q++;
 if(*q==0 && q-p<=capacity)memcpy(unit,p,q-p);
 return 1;
}
extern int j_equal(void *left, void *right);
int h_json_equal(cJSON *a,cJSON *b){return j_equal(a,b);}
