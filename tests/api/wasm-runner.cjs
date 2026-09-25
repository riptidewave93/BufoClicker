const createApiModule = require('../../build/api-wasm/api.cjs');
const readline = require('node:readline');
const fs = require('node:fs');
const path = require('node:path');
const stored = new Map();
global.localStorage = {getItem:key=>stored.get(key)??null,setItem:(key,value)=>stored.set(key,String(value)),removeItem:key=>stored.delete(key),clear:()=>stored.clear(),key:index=>[...stored.keys()][index]??null,get length(){return stored.size;}};
let domResults=[];
global.bufoDomBridge=()=>{if(!domResults.length)throw Error('Missing explicit headless DOM fixture');return domResults.shift();};
createApiModule({locateFile:name=>path.resolve('build/api-wasm',name),wasmBinary:fs.readFileSync('build/api-wasm/api.wasm'),print:value=>process.stderr.write(value+'\n')}).then(module=>{
 const lines=readline.createInterface({input:process.stdin});
 lines.on('line',line=>{domResults=JSON.parse(line).domResults||[];process.stdout.write(module.ccall('bufo_dispatch','string',['string'],[line])+'\n');});
});
