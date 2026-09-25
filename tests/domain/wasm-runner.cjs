const createDomainModule = require('../../build/domain-wasm/domain.cjs');
const readline = require('node:readline');
const fs = require('node:fs');
const path = require('node:path');
createDomainModule({locateFile: name => path.resolve('build/domain-wasm', name), wasmBinary: fs.readFileSync('build/domain-wasm/domain.wasm'), print: value => process.stderr.write(value + '\n')}).then(module => {
  const lines = readline.createInterface({input: process.stdin});
  lines.on('line', line => {
    process.stdout.write(module.ccall('bufo_dispatch', 'string', ['string'], [line]) + '\n');
  });
});
