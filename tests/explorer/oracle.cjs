const fs = require('node:fs');
const assert = require('node:assert/strict');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const ts = require('/app/node_modules/typescript');
const sourceRoot = process.env.SOURCE_ROOT || '/source';
let now = 1000, randomValues = [], randomIndex = 0;
let state = {}, events = [], timers = new Map(), timerId = 0;
const cache = new Map();
const clone = value => JSON.parse(JSON.stringify(value));
function merge(left, patch) {
 const result = {...left};
 for (const [key, value] of Object.entries(patch)) result[key] = value && typeof value === 'object' && !Array.isArray(value) ? merge(left?.[key] || {}, value) : value;
 return result;
}
const stateService = {getState: () => clone(state), setState: patch => {state = merge(state,patch)}, startBatch() {}, endBatch() {}};
const eventService = {emit: (name,payload) => events.push({name,payload:clone(payload ?? null)}), on() {}};
const fakeDate = class extends Date {constructor(...args) { super(...(args.length ? args : [now])); } static now() {return now;}};
const fakeMath = Object.create(Math);
fakeMath.random = () => randomValues[randomIndex++] ?? 0.999;
const context = vm.createContext({ Date:fakeDate, Math:fakeMath, structuredClone:clone, console:{log(){},warn(){},error(){},debug(){}}, setTimeout:(fn,ms)=>{timers.set(++timerId,{fn,at:now+ms}); return timerId},clearTimeout:id=>timers.delete(id),setInterval:()=>++timerId,clearInterval(){},performance:{now:()=>now},process:{env:{NODE_ENV:'test'}} });
context.window = context;
function load(file) {
 file = path.resolve(sourceRoot,file);
 if (!path.extname(file)) file += '.ts';
 if (cache.has(file)) return cache.get(file).exports;
 const relative = path.relative(sourceRoot,file);
 if (relative === 'src/core/stateManager.ts') return {getStateManager:()=>stateService};
 if (relative === 'src/core/eventBus.ts') return {getEventBus:()=>eventService};
 if (relative === 'src/utils/logger.ts') return new Proxy({}, {get:()=>()=>{}});
 if (relative === 'src/utils/dataLoader.ts') return {loadJsonData:async p=>JSON.parse(fs.readFileSync(path.join(sourceRoot,p),'utf8'))};
 if (relative === 'src/game/gameCore.ts') return {getGameCore:()=>({getGeneratorManager:()=>load('src/managers/generatorManager').getGeneratorManager()})};
 const module = {exports:{}}; cache.set(file,module);
 const raw=fs.readFileSync(file,'utf8');
 const compiled=ts.transpileModule(raw,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText;
 const fn=vm.runInContext(`(function(require,module,exports){${compiled}\n})`,context,{filename:file});
 fn(request=>load(path.resolve(path.dirname(file),request)),module,module.exports);
 return module.exports;
}
const ex=load('src/models/explorer'), en=load('src/models/enemies'), co=load('src/models/combat');
const manager=load('src/managers/explorerManager').getExplorerManager();
const defaults=clone(ex.DEFAULT_EXPLORER_DATA), vectors=[];
const random=Array(256).fill(.5);
function record(operation,args={},seed=null,sequence=random,time=1000) {
 sequence=[...sequence,...Array(256).fill(.999)];
 now=time; randomValues=sequence; randomIndex=0; events=[];
 if(seed) {state={explorer:clone(seed),resources:{bufos:12345}}; manager.currentCombat=null;manager.currentEnemy=null;manager.explorationDistance=0;}
 const input={operation,args:clone(args),now,random:sequence};
 let result;
 if(operation.startsWith('model.')) {const name=operation.slice(6);const a=args;
 const calls={DEFAULT_EXPLORER_DATA:()=>ex.DEFAULT_EXPLORER_DATA,ExplorerState:()=>ex.ExplorerState,
 calculateStatUpgradeCost:()=>ex.calculateStatUpgradeCost(a.statLevel,a.baseCost),getAreaLevel:()=>ex.getAreaLevel(a.area),
 calculateAreaEffectiveness:()=>ex.calculateAreaEffectiveness(a.explorer,a.areaLevel),upgradeExplorerStat:()=>ex.upgradeExplorerStat(a.explorer,a.statName,a.bufos),
 startExploration:()=>ex.startExploration(a.explorer,a.area),calculateExplorationResult:()=>ex.calculateExplorationResult(a.explorer,a.elapsedSeconds),
 completeExploration:()=>ex.completeExploration(a.explorer,a.result),restExplorer:()=>ex.restExplorer(a.explorer,a.seconds),updateExplorer:()=>ex.updateExplorer(a.explorer,a.deltaSeconds)};
 result=calls[name]?calls[name]():ex[name](a.explorer);
 } else if(operation.startsWith('enemy.')) {const name=operation.slice(6);const a=args;
 result=name==='generateEnemy'?en[name](a.area,a.distanceMultiplier,a.areaLevel):name==='calculateRelativeDifficulty'?en[name](a.enemyStats,a.explorerStats):name==='calculateEnemyRewards'?en[name](a.enemy):en[name];
 } else if(operation.startsWith('combat.')) {const name=operation.slice(7);const a=args;
 result=name==='initializeCombat'?co[name](a.explorer,a.enemy):name==='executeCombatAction'?co[name](a.state,a.action):name==='simulateCombat'?co[name](a.explorer,a.enemy,a.simulationRounds):co[name];
 } else {const a=args;const calls={update:()=>manager.update(a.delta),startExploration:()=>manager.startExploration(a.area),performCombatAction:()=>manager.performCombatAction(a.action),upgradeExplorerStat:()=>manager.upgradeExplorerStat(a.statName,a.availableBufos)};result=calls[operation]?calls[operation]():manager[operation]();}
 input.random=sequence.slice(0,randomIndex);
 const expected={ok:true};if(result!==undefined)expected.result=clone(result);
 vectors.push({input,expected,randomConsumed:randomIndex,...(seed?{seed:clone(seed)}:{}),...(operation.includes('.')?{}:{explorer:clone(state.explorer),events:clone(events)})});
 return result;
}
record('model.DEFAULT_EXPLORER_DATA');record('model.ExplorerState');record('enemy.EnemyType');record('combat.CombatStatus');record('combat.CombatActionType');
for(const name of ['calculateDPS','calculateSurvivalTime','calculatePowerRating','recalculateExplorerStats','canLevelUp','levelUpExplorer','startCombat'])record('model.'+name,{explorer:defaults});
for(const area of ['Pond','Creek','Swamp','River','Lake','Forest','Mountains','Dungeon','unknown'])record('model.getAreaLevel',{area});
for(const level of [1,2,8,100])record('model.calculateStatUpgradeCost',{statLevel:level});
for(const areaLevel of [1,5,10])record('model.calculateAreaEffectiveness',{explorer:defaults,areaLevel});
for(const statName of ['attack','defense','speed','luck','invalid'])for(const bufos of [49,50])record('model.upgradeExplorerStat',{explorer:defaults,statName,bufos});
for(const stateName of ['idle','resting','injured','exploring','fighting']) {
 const explorer={...defaults,state:stateName};record('model.startExploration',{explorer,area:'Pond'});record('model.startCombat',{explorer});record('model.updateExplorer',{explorer,deltaSeconds:60});
}
for(const health of [1,19,20,95,100])for(const stateName of ['resting','injured'])record('model.restExplorer',{explorer:{...defaults,state:stateName,health},seconds:60},null,random,61000);
for(const roll of [.0,.99]) {const result=record('model.calculateExplorationResult',{explorer:defaults,elapsedSeconds:600},null,[roll]);record('model.completeExploration',{explorer:{...defaults,experience:1000},result});}
record('model.updateExplorer',{explorer:{...defaults,state:'exploring',explorationProgress:99},deltaSeconds:6},null,[.0],601000);
record('model.levelUpExplorer',{explorer:{...defaults,experience:1000}});
const enemies=[];for(const [area,areaLevel] of [['Pond',1],['Creek',2],['Swamp',3],['River',4],['Lake',5],['Forest',6],['Mountains',8],['Dungeon',10]])for(const roll of [.0,.96,.999])enemies.push(record('enemy.generateEnemy',{area,areaLevel,distanceMultiplier:.4},null,[roll,roll,.5,.5,.5,.5]));
record('enemy.BASE_DROP_ITEMS');record('enemy.INITIAL_ENEMY_TEMPLATES');
const enemy=enemies[0];record('enemy.calculateEnemyRewards',{enemy},null,[.0,.999,.0,.999]);
record('enemy.calculateRelativeDifficulty',{enemyStats:enemy,explorerStats:{attack:10,defense:5,health:100,speed:8}});
const combat=record('combat.initializeCombat',{explorer:defaults,enemy});
for(const action of ['attack','defend','flee'])for(const roll of [.0,.99])record('combat.executeCombatAction',{state:clone(combat),action},null,Array(20).fill(roll));
record('combat.executeCombatAction',{state:{...clone(combat),enemy:{...enemy,health:1}},action:'attack'});
for(const simulationRounds of [0,1,10])record('combat.simulateCombat',{explorer:defaults,enemy,simulationRounds});
record('combat.simulateCombat',{explorer:{...defaults,health:1},enemy:{...enemy,attack:100}});
for(const method of ['getExplorer','getCurrentEnemy','getCurrentCombat','getExplorerStats','getAvailableAreas','reset'])record(method,{},defaults);
for(const statName of ['attack','defense','speed','luck'])for(const availableBufos of [49,50])record('upgradeExplorerStat',{statName,availableBufos},defaults);
record('startExploration',{area:'invalid'},defaults);record('startExploration',{area:'Pond'},defaults);
record('update',{delta:0});record('update',{delta:10},null,[.999]);record('update',{delta:40},null,[.999],51000);
record('startExploration',{area:'Pond'},{...defaults,experience:1000});record('update',{delta:50},null,[.999],51000);
record('startExploration',{area:'Pond'},defaults);record('update',{delta:1},null,[.0,...random]);record('getCurrentEnemy');record('getCurrentCombat');record('performCombatAction',{action:'defend'});record('autoResolveCombat');
record('performCombatAction',{action:'attack'},defaults);record('autoResolveCombat',{},defaults);
for(const stateName of ['resting','injured'])record('update',{delta:60},{...defaults,state:stateName,health:19},random,61000);
record('startExploration',{area:'Pond'},defaults);for(let i=1;i<=5;i++)record('update',{delta:10},null,[.999],1000+i*10000);
record('startExploration',{area:'Pond'},{...defaults,experience:1000});for(let i=1;i<=5;i++)record('update',{delta:10},null,[.999],1000+i*10000);
for(const offset of [-1,-.5,0,.5,1]) {
 const explorer={...defaults,experience:61923852+offset,experienceToNextLevel:61923852};
 record('model.canLevelUp',{explorer});record('model.levelUpExplorer',{explorer});
 record('model.upgradeExplorerStat',{explorer:{...defaults,attack:{...defaults.attack,upgradeCost:61923852}},statName:'attack',bufos:61923852+offset});
}
for(const health of [61923851,61923852,12384769.4,12384770.4,30961925])for(const stateName of ['resting','injured'])record('model.restExplorer',{explorer:{...defaults,health,maxHealth:61923852,state:stateName},seconds:0});
const out=process.env.OUTPUT_DIR||'/out';fs.writeFileSync(path.join(out,'vectors.json'),JSON.stringify(vectors,null,2)+'\n');
if(process.env.ENEMY_CATALOG_OUTPUT)fs.writeFileSync(process.env.ENEMY_CATALOG_OUTPUT,JSON.stringify({BASE_DROP_ITEMS:en.BASE_DROP_ITEMS,INITIAL_ENEMY_TEMPLATES:en.INITIAL_ENEMY_TEMPLATES},null,2)+'\n');
const sourceFiles=['src/models/explorer.ts','src/models/enemies.ts','src/models/combat.ts','src/managers/explorerManager.ts','src/core/eventTypes.ts','src/core/types.ts'];
const provenance={revision:'fe02bde429b650d32591f22a824f7dad8a0d4dd9',sourceFiles:sourceFiles.map(file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(sourceRoot,file))).digest('hex')})),oracleSha256:crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex'),vectorsSha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(out,'vectors.json'))).digest('hex'),substitutions:['StateManager cloned-read in-memory store','EventBus payload recorder without listener delivery','Date.now and Math.random deterministic sources'],vectors:vectors.length};
fs.writeFileSync(path.join(out,'oracle-provenance.json'),JSON.stringify(provenance,null,2)+'\n');
console.log(JSON.stringify({vectors:vectors.length}));
