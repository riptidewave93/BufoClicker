const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs'),http=require('node:http'),path=require('node:path');
const root=path.resolve(process.env.API_BROWSER_ROOT || 'dist');
const mime={'.js':'text/javascript','.css':'text/css','.wasm':'application/wasm','.json':'application/json','.html':'text/html','.svg':'image/svg+xml','.png':'image/png','.gif':'image/gif','.ico':'image/x-icon','.woff2':'font/woff2'};
let server;

(async()=>{
 if(!process.env.API_BROWSER_URL) {
 server=http.createServer((req,res)=>{
  const file=path.resolve(root,'.'+(req.url==='/'?'/index.html':req.url.split('?')[0]));
  if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
  fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(file.endsWith('/host.js')?String(data).replace('const callbacks = new Map();','const callbacks = globalThis.__callbackRegistry = new Map();'):data)});
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 }
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 await page.goto(process.env.API_BROWSER_URL || `http://127.0.0.1:${server.address().port}`);await page.waitForSelector('#bufo',{timeout:60000});
 assert.match(await page.title(),/Bufo/);
 console.log('page identity',await page.title());
 const counts=await page.evaluate(async()=>{
 const check=(condition,label)=>{if(!condition)throw Error(label)};
 const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));
 debugTools.time.pause();
 const baseline=__callbackRegistry.size;
 for(let i=0;i<100;i++){const fn=()=>i;cobol.call('event.on',['temporary',fn]);cobol.call('event.off',['temporary',fn]);}
 check(cobol.call('event.getListenerCount',['temporary'])===0,'event listeners removed');
 check(__callbackRegistry.size===baseline,'removed closures retained: '+__callbackRegistry.size);
 let onceCalls=0;const once=()=>{cobol.call('event.off',['single',once]);cobol.call('getState');onceCalls++};cobol.call('event.on',['single',once]);cobol.call('event.emit',['single']);check(onceCalls===1,'one-shot response callback lost');check(__callbackRegistry.size===baseline,'one-shot callback retained');
 let calls=0;const shared=()=>calls++;
 cobol.call('event.on',['one',shared]);cobol.call('event.on',['two',shared]);cobol.call('event.off',['one',shared]);
 cobol.call('event.emit',['two']);check(calls===1,'other event owner lost');
 cobol.call('event.off',['two',shared]);check(__callbackRegistry.size===baseline,'last owner retained');
 cobol.call('event.on',['again',shared]);cobol.call('event.emit',['again']);check(calls===2,'old token re-registration lost');cobol.call('event.off',['again',shared]);
 let nested=0;const inner=()=>nested++;const outer=()=>{cobol.call('event.off',['nested',outer]);cobol.call('event.on',['inner',inner]);cobol.call('event.emit',['inner']);cobol.call('event.off',['inner',inner]);};
 cobol.call('event.on',['nested',outer]);cobol.call('event.emit',['nested']);check(nested===1,'nested owner lost');check(__callbackRegistry.size===baseline,'nested callbacks retained');
 let stateCalls=0;const stateFn=()=>stateCalls++;cobol.call('stateManager.subscribe',[stateFn]);
 cobol.call('event.on',['state-shared',stateFn]);cobol.call('event.off',['state-shared',stateFn]);const previousStateCalls=stateCalls;
 cobol.call('stateManager.setState',[{resources:{bufos:1}}]);check(stateCalls>previousStateCalls,'state owner lost');cobol.call('stateManager.unsubscribe',[stateFn]);check(__callbackRegistry.size===baseline,'unsubscribed state owner retained');
 const node=document.createElement('button');document.body.append(node);const component=cobol.call('component.create',['Component',{element:node}]);
 component.addEventListener('click',shared);cobol.call('event.on',['dom-shared',shared]);cobol.call('event.off',['dom-shared',shared]);node.click();check(calls===3,'DOM owner lost');
 component.removeEventListener('click',shared);cobol.call('getState');check(__callbackRegistry.size===baseline,'removed DOM owner retained');
 for(let i=0;i<30;i++){component.addEventListener('click',()=>i);component.destroy();}
 cobol.call('getState');check(__callbackRegistry.size===baseline,'destroyed DOM callbacks retained');node.remove();
 let completed=0;const animated=document.createElement('div');document.body.append(animated);
 cobol.call('animation.animateElement',[animated,{duration:30,properties:{opacity:1},onComplete:()=>{cobol.call('getState');completed++}}]);
 await wait(130);cobol.call('getState');check(completed===1,'animation completion lost');check(__callbackRegistry.size===baseline,'completed animation callback retained');animated.remove();
 let scheduled=0;const scheduledFn=()=>{cobol.call('getState');scheduled++};
 cobol.call('event.on',['scheduled-root',scheduledFn]);const scheduledToken=[...__callbackRegistry].find(([,fn])=>fn===scheduledFn)[0];
 globalThis.bufoDomBridge({kind:'schedule',id:'callback-ownership-timer',delay:30,callback:{$callback:scheduledToken}});
 cobol.call('event.off',['scheduled-root',scheduledFn]);await wait(100);check(scheduled===1,'DOM timer callback lost');check(__callbackRegistry.size===baseline,'DOM timer callback retained');
 let timed=0;const timerFn=()=>{timed++;cobol.call('getState');};const delayed=cobol.call('time.debounce',[timerFn,30]);delayed();
 cobol.call('event.on',['timer-shared',timerFn]);cobol.call('event.off',['timer-shared',timerFn]);await wait(100);check(timed===1,'pending timer owner lost');
 // Callable wrappers remain reusable after firing, and retain their source callback.
 delayed();await wait(100);check(timed===2,'reused callable lost');
 const beforeReset=__callbackRegistry.size;check(beforeReset===baseline+1,'unexpected pending callback count '+beforeReset);
 cobol.call('runtime.reset');check(__callbackRegistry.size===0,'reset retained runtime callbacks');
 return {temporaryClosures:100,domClosures:30,sharedCalls:calls,nested,stateCalls,onceCalls,completed,scheduled,timed,retained:__callbackRegistry.size};
 });
 assert.deepEqual(errors,[]);console.log('Callback ownership passed',counts);await browser.close();server?.close();
})().catch(e=>{console.error(e);server?.close();process.exit(1)});
