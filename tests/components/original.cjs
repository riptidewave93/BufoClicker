const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto');
const ts=require('/app/node_modules/typescript');
const cache=new Map(), hashes={};
let state={resources:{bufos:250},generators:{}};
class Base {constructor(options={}){this.options=options;this.element=null;this.id=options.id||null;}}
function load(file){file=path.resolve('/source',file);if(!path.extname(file))file+='.ts';if(cache.has(file))return cache.get(file).exports;
 const rel=path.relative('/source',file);
 if(rel==='src/ui/core/Component.ts')return {Component:Base};
 if(rel==='src/core/stateManager.ts')return {getStateManager:()=>({getState:()=>state})};
 if(rel==='src/game/gameCore.ts')return {getGameCore:()=>({getGeneratorManager:()=>({getMaxAffordable:(id,b)=>load('src/models/generators').calculateMaxAffordable(state.generators[id],b)})})};
 if(rel==='src/utils/dataLoader.ts')return {loadJsonData:async()=>[]};
 if(rel==='src/utils/logger.ts')return Object.fromEntries(['log','warn','error','debug','info'].map(k=>[k,()=>{}]));
 const source=fs.readFileSync(file,'utf8');hashes[path.relative('/source',file)]=crypto.createHash('sha256').update(source).digest('hex');
 const module={exports:{}};cache.set(file,module);
 const code=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText;
 vm.runInThisContext(`(function(require,module,exports){${code}\n})`,{filename:file})(p=>load(path.resolve(path.dirname(file),p)),module,module.exports);return module.exports;}
const templates=load('src/ui/templates'),animation=load('src/utils/animationUtils');
const rows=[];
const cases={sectionHeader:[['Owned','frogs'],['<b>Title</b>']],panel:[['Panel','<p>Contents</p>','panel','wide']],button:[['Buy','b','buy()','purchase',true],['Next']],iconButton:[['X','close','Close','close()','tiny',true]],progressBar:[[3,8,'p',true,'wide'],[1,3,'',false],[0,0],[3,0]],resourceDisplay:[[1234,'Ignored','r',true,'12K','large']],tooltip:[['Body','Title','t','wide']],notification:[['Saved'],['Failed','error','err']],modal:[['Title','<p>Body</p>',[{text:'OK',callback:'ok()'},{text:'No',callback:'no()',className:'cancel'}],'m',false]],tabContainer:[[[{id:'main',label:'Main',content:'<b>One</b>',icon:'🐸'},{id:'shop',label:'Shop',content:'Two'}],'shop','tabs']]};
for(const [name,values] of Object.entries(cases))for(const args of values)rows.push({request:{operation:`templates.${name}`,args},expected:templates[name](...args)});
for(const [name,fn] of Object.entries(animation.Easing))for(const t of [0,.1,.25,.5,.75,1])rows.push({request:{operation:`animation.Easing.${name}`,args:[t]},expected:fn(t)});
const generator={id:'tadpole',name:'Tadpole',description:'Pond worker',detailedDescription:'A careful pond worker',count:0,baseCost:10,currentCost:10,costMultiplier:1.15,baseProduction:1,currentProduction:2,totalProduction:0,category:'basic',unlocked:true,boosts:[{source:'Training',multiplier:1.5,active:true},{source:'Inactive',multiplier:2,active:false}]};
state.generators.tadpole=generator;
for(const [file,kind,data] of [['generatorItem','GeneratorItem',generator],['shopItem','ShopItem',{generator,purchaseAmount:10,canAfford:true}],['upgradeItem','UpgradeItem',{id:'stronger_clicks_1',name:'Strong fingers',description:'Stronger clicks',cost:100,category:'click'}]]) {
 const Class=load(`src/ui/components/${file}`)[kind],instance=new Class({});instance.update(data);
 for(const method of ['render','generateTooltipContent'])rows.push({request:{component:{kind,options:{},data},method,state},expected:instance[method]()});
}
const constantExports=load('src/ui/constants'), styleExports=load('src/ui/styles');
fs.writeFileSync('/out/original-tables.json',JSON.stringify({uiConstants:constantExports,uiStyles:styleExports},null,2)+'\n');
for(const [prefix,exports] of [['uiConstants',constantExports],['uiStyles',styleExports]])for(const [name,value] of Object.entries(exports))rows.push({request:{operation:`${prefix}.${name}`,args:[]},expected:name==='DEFAULT_THEME'?'dark':value,...(name==='DEFAULT_THEME'?{original:value,change:'Owner requires dark mode'}:{})});
fs.writeFileSync('/out/original-vectors.jsonl',rows.map(x=>JSON.stringify(x)).join('\n')+'\n');
fs.writeFileSync('/out/original-provenance.json',JSON.stringify({baseline:'fe02bde429b650d32591f22a824f7dad8a0d4dd9',sourceHashes:hashes,count:rows.length},null,2)+'\n');
