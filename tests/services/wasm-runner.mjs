import createModule from '../../build/services-wasm/services.cjs';
import { readFileSync } from 'node:fs';
const storage = new Map();
globalThis.localStorage = {getItem:key=>storage.get(key)??null,setItem:(key,value)=>storage.set(key,String(value)),removeItem:key=>storage.delete(key)};
import { createInterface } from 'node:readline';
const module = await createModule({wasmBinary:readFileSync(new URL('../../build/services-wasm/services.wasm',import.meta.url))});
for await (const line of createInterface({input:process.stdin})) {
 console.log(module.ccall('service_dispatch','string',['string'],[line]));
}
