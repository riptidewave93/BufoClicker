const fs=require('node:fs'),http=require('node:http'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require('playwright');
const root=path.resolve(process.env.BUFO_SITE_DIR||'dist');
(async()=>{
 const server=http.createServer((req,res)=>{const file=path.join(root,req.url==='/'?'index.html':req.url.split('?')[0]);try{res.setHeader('Content-Type',file.endsWith('.wasm')?'application/wasm':file.endsWith('.js')?'text/javascript':file.endsWith('.css')?'text/css':'text/html');res.end(fs.readFileSync(file));}catch{res.writeHead(404).end();}}).listen(9137);
 const browser=await chromium.launch();try{const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto('http://127.0.0.1:9137/');await page.waitForFunction(()=>window.cobol);
 const result=await page.evaluate(async()=>{
  const original=globalThis.bufoDomBridge;let inside=0,reentered=false,changed=0,selectorChanges=0,easingCalls=0;const removed=[];
  globalThis.bufoDomBridge=command=>{inside++;try{if(command.kind==='remove')removed.push(command.element);return original(command);}finally{inside--;}};
  const check=()=>{reentered ||= inside>0;};
  const c=cobol.call('component.create',['Component',{id:'self-destruct'}]);
  cobol.call('component.connectToState',[c,'resources.bufos',()=>{check();changed++;c.destroy();}]);
  const selector=cobol.call('component.create',['Component',{id:'selector-destroy'}]);
  cobol.call('component.connectToState',[selector,state=>{check();selector.destroy();return state.resources.bufos;},()=>selectorChanges++]);
  const input=cobol.call('dom.createElement',['input',{parent:{$element:'body'}}]);const focus=cobol.call('component.create',['Component',{element:input}]);
  focus.addEventListener('focus',()=>{check();focus.destroy();cobol.call('getState');});cobol.call('dom.focus',[input]);
  const animEl=cobol.call('dom.createElement',['div',{parent:{$element:'body'}}]);let handle;
  handle=cobol.call('animation.animate',[100,()=>{throw Error('cancelled easing must not update');},{easing:()=>{check();easingCalls++;cobol.call('animation.cancel',[handle]);return .5;}}]);
  await new Promise(resolve=>setTimeout(resolve,150));
  cobol.call('tooltip.showTooltip',['Owned tip',{clientX:10,clientY:10}]);await new Promise(resolve=>setTimeout(resolve,350));cobol.call('tooltip.hideTooltip');await new Promise(resolve=>setTimeout(resolve,350));
  return {reentered,changed,selectorChanges,easingCalls,alive:typeof cobol.call('getState').resources.bufos,retainedTooltips:removed.filter(token=>original({kind:'getId',element:token})==='game-tooltip').length};
 });
 assert.equal(result.reentered,false);assert.equal(result.changed,1);assert.equal(result.selectorChanges,0);assert.equal(result.easingCalls,1);assert.equal(result.alive,'number');assert.equal(result.retainedTooltips,0);assert.deepEqual(errors,[]);console.log(JSON.stringify({result:'passed',...result}));
 }finally{await browser.close();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
