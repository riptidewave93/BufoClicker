const fs=require('node:fs');
const path=require('node:path');
const http=require('node:http');
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
const root=process.env.REPO_ROOT||process.cwd();
const vectors=JSON.parse(fs.readFileSync(path.join(root,'tests/explorer/vectors.json')));
const wasmRoot=path.join(root,'build/explorer-wasm');
const types={'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.data':'application/octet-stream'};
const server=http.createServer((req,res)=>{
  const relative=req.url.replace(/^\/BufoClicker\//,'/').split('?')[0];
  const file=path.join(wasmRoot,relative==='/'?'index.html':relative);
  if(!file.startsWith(wasmRoot+path.sep)){res.writeHead(400).end();return;}
  fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');res.end(data);});
});
function same(actual,expected,at='result') {
 if(typeof expected==='number')assert(Number.isInteger(expected)?actual===expected:Math.abs(actual-expected)<=Math.max(1e-12,Math.abs(expected)*1e-10),`${at}: ${actual} != ${expected}`);
 else if(Array.isArray(expected)){assert(Array.isArray(actual)&&actual.length===expected.length,at);expected.forEach((v,i)=>same(actual[i],v,`${at}.${i}`));}
 else if(expected&&typeof expected==='object'){assert.deepEqual(Object.keys(actual).sort(),Object.keys(expected).sort(),at);for(const k of Object.keys(expected))same(actual[k],expected[k],`${at}.${k}`);}
 else assert.equal(actual,expected,at);
}
(async()=>{
 await new Promise(resolve=>server.listen(9899,'127.0.0.1',resolve));
 const browser=await chromium.launch({headless:true});
 const evidence=[];
 try {
  for(const prefix of ['/','/BufoClicker/']) {
   const page=await browser.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.goto(`http://127.0.0.1:9899${prefix}`);await page.waitForFunction(()=>typeof window.explorerRun==='function');
   const outputs=await page.evaluate(vs=>vs.map(v=>window.explorerRun(v)),vectors);
   outputs.forEach((out,i)=>{const v=vectors[i],expected={...v.expected,randomConsumed:v.randomConsumed};if('explorer'in v){expected.explorer=v.explorer;expected.events=v.events;}else{delete out.explorer;delete out.events;}same(out,expected,`${i} ${v.input.operation}`);});
   const defaultExplorer=vectors[0].expected.result;
   const normalized=await page.evaluate(ex=>window.explorerRun({input:{operation:'normalize',now:7777,args:{explorer:{...ex,state:'fighting',health:10},strict:true}}}),defaultExplorer);
   assert.equal(normalized.result.state,'injured');assert.equal(normalized.result.stateStartTime,7777);
   const rejected=await page.evaluate(ex=>window.explorerRun({input:{operation:'validate',now:7777,args:{explorer:{...ex,health:ex.maxHealth+1}}}}),defaultExplorer);
   assert.equal(rejected.result,false);assert.deepEqual(errors,[]);
   evidence.push({path:prefix,sourceVectors:outputs.length,normalization:true,invalidHealthRejected:true,pageErrors:errors});
   await page.close();
  }
 } finally {await browser.close();server.close();}
 fs.writeFileSync(path.join(wasmRoot,'browser-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
 console.log(JSON.stringify(evidence));
})().catch(error=>{console.error(error);server.close();process.exitCode=1});
