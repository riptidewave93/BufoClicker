#include <math.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <time.h>
#include "cJSON.h"
#include <stdlib.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
EM_JS(int, host_url_valid, (const char *text), {
 try { new URL(UTF8ToString(text)); return 1; } catch (_) { return 0; }
});
EM_JS(char *, host_timestamp, (double ms, int include), {
 let text;
 if (!Number.isFinite(ms)) text = 'Invalid date';
 else {
  const date = new Date(ms);
  if (Number.isNaN(date.getTime())) text = 'Invalid date';
  else {
   const options = {year:'numeric',month:'short',day:'numeric'};
   if (include) Object.assign(options,{hour:'2-digit',minute:'2-digit',second:'2-digit'});
   try { text = date.toLocaleString(undefined,options); }
   catch (_) { text = 'Error formatting date'; }
  }
 }
 return stringToNewUTF8(text);
});
#endif
int h_round(double *v,const double *factor){double x=*v * *factor;*v=(x-floor(x)<0.5?floor(x):ceil(x))/ *factor;return 0;}
int h_atan2(const double *y,const double *x,double *r){*r=atan2(*y,*x);return 0;}
int h_array_swap(cJSON *a,int i,int j){if(i==j)return 0;cJSON *x=cJSON_GetArrayItem(a,i),*y=cJSON_GetArrayItem(a,j);if(!x||!y)return -1;cJSON *xc=cJSON_Duplicate(x,1),*yc=cJSON_Duplicate(y,1);if(!xc||!yc){cJSON_Delete(xc);cJSON_Delete(yc);return -1;}cJSON_ReplaceItemInArray(a,i,yc);cJSON_ReplaceItemInArray(a,j,xc);return 0;}
int h_scalar_equal(cJSON *a,cJSON *b){if(!a||!b)return a==b;if(cJSON_IsArray(a)||cJSON_IsObject(a)||cJSON_IsArray(b)||cJSON_IsObject(b))return a==b;if(cJSON_IsNumber(a)&&cJSON_IsNumber(b))return a->valuedouble==b->valuedouble;return cJSON_Compare(a,b,1);}
int h_url_valid(cJSON *v){
#ifdef __EMSCRIPTEN__
 const char *text=cJSON_GetStringValue(v);return text&&text[0]?host_url_valid(text):0;
#else
 const char *s=cJSON_GetStringValue(v);if(!s)return 0;while(isspace((unsigned char)*s))s++;if(!isalpha((unsigned char)*s))return 0;const char *p=s+1;while(isalnum((unsigned char)*p)||*p=='+'||*p=='-'||*p=='.')p++;if(*p!=':')return 0;if(!strncmp(s,"http:",5)||!strncmp(s,"https:",6)||!strncmp(s,"ftp:",4)){p++;while(*p=='/'||*p=='\\')p++;if(!*p)return 0;for(;*p&&*p!='/';p++)if(isspace((unsigned char)*p)){while(isspace((unsigned char)*p))p++;if(*p)return 0;break;}}return 1;
#endif
}
int h_timestamp(const double *ms,int include,char *out,int cap) {
#ifdef __EMSCRIPTEN__
 memset(out,' ',cap);char *text=host_timestamp(*ms,include);if(!text)return -1;
 size_t length=strlen(text);if(length>(size_t)cap){free(text);return -1;}
 memcpy(out,text,length);free(text);return 0;
#else
memset(out,' ',cap);char b[128];if(!isfinite(*ms)||fabs(*ms)>8640000000000000.)strcpy(b,"Invalid date");else{time_t sec=(time_t)(*ms/1000);struct tm t;if(!gmtime_r(&sec,&t))strcpy(b,"Invalid date");else{static const char *m[]={"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};int n=snprintf(b,sizeof b,"%s %d, %d",m[t.tm_mon],t.tm_mday,t.tm_year+1900);if(include)snprintf(b+n,sizeof b-n,", %02d:%02d:%02d %s",t.tm_hour%12?t.tm_hour%12:12,t.tm_min,t.tm_sec,t.tm_hour>=12?"PM":"AM");}}int n=strlen(b);if(n>cap)return -1;memcpy(out,b,n);return 0;
#endif
}
int h_power(const double *base,const double *exponent,double *r){*r=pow(*base,*exponent);return 0;}
int h_log10(const double *value,double *r){*r=log10(fabs(*value));return 0;}
int h_truthy(cJSON *v){if(!v||cJSON_IsNull(v)||cJSON_IsFalse(v))return 0;if(cJSON_IsNumber(v))return v->valuedouble!=0;if(cJSON_IsString(v))return v->valuestring[0]!=0;return 1;}
int h_nonempty(cJSON *v){const unsigned char *s=(unsigned char*)cJSON_GetStringValue(v);if(!s)return 0;while(*s){if(!isspace(*s))return 1;s++;}return 0;}
int h_has_tag(cJSON *v){if(!v)return 0;if(cJSON_IsObject(v)&&cJSON_GetObjectItemCaseSensitive(v,"$oracle"))return 1;for(cJSON *c=v->child;c;c=c->next)if(h_has_tag(c))return 1;return 0;}
int h_number_compare(const double *a,const double *b){return *a<*b?-1:*a>*b?1:0;}
int h_array_remove(cJSON *array,int index){if(!cJSON_IsArray(array)||index<0||index>=cJSON_GetArraySize(array))return -1;cJSON_DeleteItemFromArray(array,index);return 0;}
int h_number_binary(int op,const double *a,const double *b,double *out){switch(op){case 1:*out=*a+*b;break;case 2:*out=*a-*b;break;case 3:*out=*a**b;break;case 4:*out=*a / *b;break;case 5:*out=pow(*a,*b);break;default:return -1;}return 0;}
int h_number_unary(int op,const double *a,double *out){switch(op){case 1:*out=ceil(*a);break;case 2:*out=floor(*a);break;case 3:*out=log(*a);break;case 4:*out=sqrt(*a);break;default:return -1;}return 0;}
int h_clock_text(const double *ms,char *out){time_t seconds=(time_t)(*ms/1000);struct tm t;char b[32];if(!gmtime_r(&seconds,&t))return -1;int milli=(int)fmod(*ms,1000);if(milli<0)milli+=1000;snprintf(b,sizeof b,"%02d:%02d:%02d.%03d",t.tm_hour,t.tm_min,t.tm_sec,milli);memcpy(out,b,12);return 0;}
int h_is_integer(const double *value){return isfinite(*value)&&trunc(*value)==*value;}
/* JSON encoding for IEEE values that JSON numbers cannot represent. */
int h_number_result(const double *value,void **out){
 if(isfinite(*value)&&(*value!=0||!signbit(*value))){*out=cJSON_CreateNumber(*value);return *out?0:-1;}
 cJSON *tag=cJSON_CreateObject();if(!tag){*out=NULL;return -1;}
 cJSON_AddStringToObject(tag,"$oracle","number");
 cJSON_AddStringToObject(tag,"value",isnan(*value)?"NaN":isinf(*value)?(*value<0?"-Infinity":"Infinity"):"-0");
 *out=tag;return 0;
}
