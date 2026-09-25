/* Generate finite boundary expectations by executing the original utility modules. */
const fs=require('node:fs'),vm=require('node:vm'),crypto=require('node:crypto');
const ts=require('/app/node_modules/typescript');
const root=process.env.SOURCE_ROOT || '/source';
const files={number:'src/utils/numberUtils.ts',math:'src/utils/mathUtils.ts',validation:'src/utils/validationUtils.ts'};
let random=.5;const modules={};const hashes={};
for(const [namespace,file] of Object.entries(files)){
 const source=fs.readFileSync(root+'/'+file,'utf8');hashes[file]=crypto.createHash('sha256').update(source).digest('hex');
 const module={exports:{}};const math=Object.create(Math);math.random=()=>random;
 vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{module,exports:module.exports,Math:math,Number,Date});modules[namespace]=module.exports;
}
const cases=[];function add(operation,args,r=.5){random=r;const [namespace,method]=operation.split('.');cases.push({operation,args,random:[r],expected:modules[namespace][method](...args)})}
for(const base of [1,1e12,1e16,-1e16]){
 const step=base===1?Number.EPSILON:base===1e12?.0001220703125:2;
 const low=base,high=base+4*step;
 for(const value of [base-step,base,base+2*step,high,high+step]){
  add('number.clamp',[value,low,high]);add('math.inRange',[value,low,high]);add('math.inRange',[value,high,low]);add('validation.isInRange',[value,low,high]);
 }
 add('math.mapRange',[base+2*step,low,high,10,20]);add('math.mapRange',[2,0,1,low,high]);add('math.mapRange',[-1,0,1,high,low]);
 add('math.inverseLerp',[low,high,base+2*step]);
}
for(const t of [1-Number.EPSILON,1,1+Number.EPSILON,-Number.MIN_VALUE]){add('math.lerp',[0,1e16,t]);add('math.smoothLerp',[0,1e16,t,2]);}
for(const r of [.5-Number.EPSILON,.5,.5+Number.EPSILON]){add('math.chance',[50],r);add('math.weightedRandom',[[1,1]],r)}
console.log(JSON.stringify({baseline:'fe02bde429b650d32591f22a824f7dad8a0d4dd9',hashes,cases},null,2));
