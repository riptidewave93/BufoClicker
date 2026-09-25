const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const assert = require('node:assert/strict');
const { firefox } = require('playwright');
const captureErrors = require('./errors.cjs');
const root = path.resolve(process.env.BUFO_SITE_DIR || 'dist');
const mime = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css', '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg' };
const server = http.createServer((request, response) => {
  const pathname = new URL(request.url, 'http://localhost').pathname;
  const file = path.resolve(root, `.${pathname.endsWith('/') ? `${pathname}index.html` : pathname}`);
  if (!file.startsWith(root + path.sep)) { response.writeHead(403).end(); return; }
  try { response.setHeader('Content-Type', mime[path.extname(file)] || 'application/octet-stream'); response.end(fs.readFileSync(file)); }
  catch { response.writeHead(404).end(); }
});
(async () => {
  await new Promise(resolve => server.listen(9364, '0.0.0.0', resolve));
  const browser = await firefox.launch();
  try {
    const page = await browser.newPage();
    const assertErrors = captureErrors(page);
    await page.goto('http://127.0.0.1:9364/');
    await page.waitForFunction(() => Boolean(window.cobol));
    await page.evaluate(() => {
      debugTools.resources.add(1000);
      debugTools.game.buyGenerator('tadpole', 1);
    });
    const deferred = await page.evaluate(() => {
      const original = globalThis.bufoDomBridge;
      let delivered = false;
      globalThis.bufoDomBridge = command => {
        if (!delivered) {
          delivered = true;
          window.dispatchEvent(new PageTransitionEvent('pagehide'));
        }
        return original(command);
      };
      try { cobol.call('dom.querySelector', ['body']); }
      finally { globalThis.bufoDomBridge = original; }
      cobol.dispatch({ operation: 'visibility', args: { hidden: false } });
      return delivered && Number.isFinite(cobol.call('getState').resources.bufos);
    });
    assert.equal(deferred, true, 'native lifecycle event must defer until the active runtime call returns');
    for (const navigation of ['reload', 'reload', 'link']) {
      const before = await page.evaluate(() => {
        debugTools.resources.add(12345);
        cobol.call('achievement.checkAllAchievements');
        cobol.dispatch({ operation: 'render', browser: true });
        const state = cobol.call('getState');
        return { bank: state.resources.bufos, rate: Object.values(state.generators).reduce((sum, generator) => sum + generator.totalProduction, 0), at: Date.now() };
      });
      await page.evaluate(() => Promise.all([...document.images].map(image => image.decode())));
      if (navigation === 'reload') {
        await Promise.all([page.waitForEvent('load'), page.evaluate(() => location.reload())]);
      } else {
        await Promise.all([page.waitForEvent('load'), page.locator('a.brand').click()]);
      }
      await page.waitForFunction(() => Boolean(window.cobol));
      const after = await page.evaluate(() => ({ bank: cobol.call('getState').resources.bufos, at: Date.now() }));
      assert.ok(after.bank >= before.bank, `${navigation} lost acknowledged progress: ${JSON.stringify({ before, after })}`);
      const maximumIncome = before.rate * ((after.at - before.at) / 1000 + 2);
      assert.ok(after.bank <= before.bank + maximumIncome + 1e-6, `${navigation} replayed credit or a reward: ${JSON.stringify({ before, after })}`);
    }
    await assertErrors();
    console.log('Firefox lifecycle passed: two browser reloads and link navigation retain progress without duplicate credit');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; }).finally(() => server.close());
