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
  fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.setHeader('Content-Type',mime[path.extname(file)]||'application/octet-stream');res.end(data)});
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 }
 const browser=await chromium.launch({headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 await page.goto(process.env.API_BROWSER_URL || `http://127.0.0.1:${server.address().port}`);await page.waitForSelector('#bufo',{timeout:60000});
 assert.match(await page.title(),/Bufo/);
 console.log('page identity',await page.title());
 const result=await page.evaluate(async()=>{
  const assert=(value,label)=>{if(!value)throw Error(label)};
  const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));
  debugTools.time.pause();
  const manager=debugTools.gameCore.getGeneratorManager();assert(manager.getAllGenerators().length===14,'manager proxy');
  const shop=debugTools.ui.getComponent('shop'),before=document.querySelector('#shop').innerHTML;
  assert(shop===debugTools.ui.getComponent('shop'),'component identity');assert(shop.getElement()===document.querySelector('#shop'),'element identity');assert(before===document.querySelector('#shop').innerHTML,'getter mutation');
  let notices=debugTools.ui.showNotification({message:'Browser acceptance',duration:50});assert(notices instanceof HTMLElement&&notices.isConnected&&notices.textContent.includes('Browser acceptance'),'notification attached');
  await wait(450);assert(!notices.isConnected,'notification removed');
  const loading=debugTools.initialization.createLoadingUI('app');loading.update({step:'Browser loading',progress:50});
  assert(document.querySelector('.game-loading .loading-progress').style.width==='50%','loading progress');assert(document.querySelector('.game-loading .loading-status').textContent==='Browser loading','loading text');
  loading.remove();await wait(600);assert(!document.querySelector('.game-loading'),'loading removed');
  const missing=debugTools.initialization.createLoadingUI('missing-root');missing.update({step:'Missing',progress:10});missing.remove();
  let closeEvents=[];const onClose=payload=>closeEvents.push(payload);debugTools.events.on('UI_MODAL_CLOSED',onClose);
  let callback=0;debugTools.ui.showModal({id:'acceptance',title:'Browser modal',content:'<b>Browser content</b>',buttons:[{text:'Accept',callback:()=>callback++}]});
  assert(document.querySelector('#modal-layer').textContent.includes('Browser content'),'modal content');
  document.querySelector('[data-action="customModalButton"]').click();assert(callback===1,'modal callback');assert(closeEvents.length===0,'close event delay');await wait(400);assert(closeEvents.length===1&&closeEvents[0].modalId==='acceptance','close event payload');
  debugTools.ui.showModal({id:'throws',title:'Throwing',content:'stays open',buttons:[{text:'Throw',callback:()=>{throw Error('expected callback failure')}}]});
  let caught=false;try{debugTools.ui.customModalButton(0)}catch(e){caught=e.message.includes('expected callback failure')};assert(caught,'callback failure propagated');assert(document.querySelector('#modal-layer').textContent.includes('stays open'),'callback failure retains modal');debugTools.ui.closeModal();await wait(400);debugTools.events.off('UI_MODAL_CLOSED',onClose);
  const progress=[];const initialized=await debugTools.initialization.initializeGame('app',status=>{progress.push(status.progress);assert(debugTools.resources.get().bufos>=0,'progress callback reentry')});assert(initialized===true,'initialization result');assert(debugTools.logger.getLogLevel()===4,'development logger level');assert(JSON.stringify(progress)==='[10,20,40,60,70,80,90,95,100]','initialization progress '+JSON.stringify(progress));
  return {progress,callback,managerCount:manager.getAllGenerators().length};
 });console.log('browser acceptance',result);
 page.once('dialog',d=>d.dismiss());assert.equal(await page.evaluate(()=>debugTools.game.reset()),false);
 page.once('dialog',d=>d.accept());assert.equal(await page.evaluate(()=>debugTools.game.reset()),true);
 await page.evaluate(()=>{
  const current='bufo_idle_save_cobol_v1',legacy='bufo_idle_save';
  const saved=localStorage.getItem(current),state=JSON.stringify(cobol.call('getState'));
  localStorage.setItem(legacy,JSON.stringify({version:'1.0.0',state:JSON.parse(state)}));
  localStorage.setItem('unrelated','keep');
  const remove=Storage.prototype.removeItem;
  try {
   Storage.prototype.removeItem=function(key){if(key===legacy)throw Error('Blocked removal');return remove.call(this,key)};
   if(debugTools.saveManager.clearSave()!==false||localStorage.getItem(current)!==saved)throw Error('Failed clear changed current save');
  } finally {Storage.prototype.removeItem=remove}
  if(debugTools.saveManager.clearSave()!==true)throw Error('Clear failed');
  if(localStorage.getItem(current)!==null||localStorage.getItem(legacy)!==null||localStorage.getItem('unrelated')!=='keep')throw Error('Clear storage scope');
  if(debugTools.saveManager.loadGame()!==null||JSON.stringify(cobol.call('getState'))!==state)throw Error('Cleared save revived or changed live state');
 });
 const screenshot=process.env.API_SCREENSHOT || 'build/browser-evidence/api-browser.png';fs.mkdirSync(path.dirname(screenshot),{recursive:true});await page.screenshot({path:screenshot,fullPage:true});
 assert.deepEqual(errors,[]);console.log('No console or page errors; reset confirm cancel/accept passed');await browser.close();server?.close();
})().catch(e=>{console.error(e);server?.close();process.exit(1)});
