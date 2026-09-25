const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const assert = require('node:assert/strict');
const playwright = require('playwright');
const captureErrors = require('./errors.cjs');
const root = path.resolve(process.env.BUFO_SITE_DIR || 'dist');
const evidence = path.resolve(process.env.BUFO_EVIDENCE_DIR || 'build/browser-evidence');
fs.mkdirSync(evidence, { recursive: true });
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json', '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.ico': 'image/x-icon' };
const server = http.createServer((request, response) => {
  let name;
  try { name = decodeURIComponent(new URL(request.url, 'http://localhost').pathname); }
  catch { response.writeHead(400).end(); return; }
  if (name.startsWith('/BufoClicker/')) name = name.slice('/BufoClicker'.length);
  if (name.endsWith('/')) name += 'index.html';
  const file = path.resolve(root, `.${name}`);
  if (!file.startsWith(root + path.sep)) { response.writeHead(403).end(); return; }
  try { response.setHeader('Content-Type', mime[path.extname(file)] || 'application/octet-stream'); response.end(fs.readFileSync(file)); }
  catch { response.writeHead(404).end(); }
});
const reports = [];
async function run(engine, prefix) {
  const browser = await playwright[engine].launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  const page = await context.newPage();
  const assertErrors = captureErrors(page);
  const started = Date.now();
  try {
    await page.goto(`http://127.0.0.1:9130${prefix}`);
    await page.waitForSelector('#bufo', { timeout: 60000 });
    const startupMs = Date.now() - started;
    const development = await page.evaluate(() => Boolean(window.cobol));
    await page.locator('#bufo').click({ clickCount: 20, delay: 10 });
    await page.locator('[data-action="buyGenerator"][data-id="tadpole"]').click();
    assert.match(await page.locator('#owned').innerText(), /Tadpole/);
    await page.locator('[data-action="settings"]').first().click();
    await page.locator('[data-action="export"]').click();
    const exported = await page.locator('#save-data').inputValue();
    assert.ok(exported.length > 100);
    await page.locator('#save-data').fill(exported);
    await page.locator('[data-action="import"]').locator('button').click();
    await page.waitForFunction(() => document.querySelector('#modal-layer').childElementCount === 0);
    await Promise.all([
      page.waitForNavigation(),
      page.evaluate(() => location.reload())
    ]);
    await page.waitForSelector('#bufo');
    assert.match(await page.locator('#owned').innerText(), /Tadpole/);
    if (development) {
      const api = await page.evaluate(() => {
        if (debugTools.gameCore.getGeneratorManager() !== debugTools.gameCore.getGeneratorManager()) throw new Error('manager singleton identity');
        if (debugTools.ui.getComponent('shop') !== debugTools.ui.getComponent('shop')) throw new Error('component singleton identity');
        const d = (operation, args) => cobol.call(operation, args);
        let calls = 0;
        const callback = () => calls++;
        d('event.on', ['browser-event', callback]);
        d('event.emit', ['browser-event', {}]);
        d('event.off', ['browser-event', callback]);
        d('event.emit', ['browser-event', {}]);
        let states = 0;
        const subscriber = () => states++;
        d('stateManager.subscribe', [subscriber]);
        d('click');
        d('stateManager.unsubscribe', [subscriber]);
        const after = states;
        d('click');
        let lateTick = 0;
        const tickListener = () => lateTick++;
        const subscribeDuringState = () => d('event.on', ['tick', tickListener]);
        d('stateManager.subscribe', [subscribeDuringState]);
        d('game.tick', { delta: 1 / 60 });
        d('stateManager.unsubscribe', [subscribeDuringState]);
        d('event.off', ['tick', tickListener]);
        return { calls, after, states, lateTick, managerCount: Object.keys(debugTools.gameCore.getGeneratorManager().getAllGenerators()).length };
      });
      assert.deepEqual(api, { calls: 1, after: 1, states: 1, lateTick: 1, managerCount: 14 });
      const modalIdentity = await page.evaluate(() => {
        window.modalClicks = 0;
        const element = debugTools.ui.showModal({ id: 'browser-modal', title: 'Browser modal', content: '<p>Callback proof</p>', buttons: [{ text: 'Continue', callback: () => window.modalClicks++ }], closeOnBackdrop: false });
        return element === document.querySelector('#modal-layer .modal');
      });
      assert.equal(modalIdentity, true);
      await page.locator('[data-action="customModalButton"]').click();
      assert.equal(await page.evaluate(() => window.modalClicks), 1);
      await page.waitForFunction(() => document.querySelector('#modal-layer').childElementCount === 0);
      const timer = await page.evaluate(async () => {
        const receiver = { value: 37 };
        let result;
        const debounced = cobol.call('time.debounce', [function (n) { result = this.value + n; }, 15]);
        debounced.call(receiver, 5);
        await new Promise(resolve => setTimeout(resolve, 60));
        return result;
      });
      assert.equal(timer, 42);
      await page.evaluate(() => debugTools.resources.add(1000000));
      await page.locator('[data-action="quantity"][data-amount="10"]').click();
      await page.locator('[data-action="buyGenerator"][data-id="tadpole"]').click();
      await page.locator('[data-action="buyGenerator"][data-id="froglet"]').click();
      await page.locator('[data-action="buyUpgrade"]').first().click();
      if (engine === 'chromium' && prefix === '/') await page.screenshot({ path: `${evidence}/desktop.png`, fullPage: true });
      await page.locator('[data-action="bossStart"]').click();
      await page.waitForSelector('.boss-sprite');
      await page.locator('.boss-sprite img').evaluate(image => image.decode());
      const healthBeforeClick = await page.locator('.boss-health-label').textContent();
      await page.locator('.boss-sprite').click();
      await page.waitForFunction(previous => document.querySelector('.boss-health-label').textContent !== previous, healthBeforeClick);
      if (engine === 'chromium' && prefix === '/') await page.screenshot({ path: `${evidence}/boss.png`, fullPage: true });
      const bossResult = await page.evaluate(() => {
        const now = Date.now();
        cobol.dispatch({ operation: 'api', args: { path: ['boss', 'win'], values: [] }, now });
        cobol.dispatch({ operation: 'action', args: { action: 'close' }, now, browser: true });
        return document.querySelector('#modal-title')?.textContent;
      });
      assert.match(bossResult, /defeated/i, 'same-timestamp click dismissed boss result');
      await page.waitForTimeout(850);
      await page.locator('.modal [data-action="close"]').last().click();
      await page.evaluate(() => debugTools.golden.spawn());
      await page.waitForSelector('.golden-bufo');
      await page.locator('.golden-bufo').click();
      await page.waitForFunction(() => document.querySelector('#golden').childElementCount === 0);
      await page.locator('[data-action="achievements"]').click();
      assert.ok(await page.locator('.achievement-row').count() > 0);
      await page.locator('[data-action="toggleLocked"]').click();
      await page.locator('[data-action="toggleLocked"]').click();
      const labels = await page.locator('.achievement-state').allTextContents();
      assert.ok(labels.length > 0 && labels.every(label => label === 'Unlocked'));
      await page.locator('.modal [data-action="close"]').click();
      const before = await page.evaluate(() => cobol.call('getState').resources.bufos);
      await page.evaluate(() => debugTools.game.toggleAutoSave(false));
      await page.evaluate(() => { window.originalSetItem = Storage.prototype.setItem; Storage.prototype.setItem = function () { throw new DOMException('Quota test', 'QuotaExceededError'); }; });
      await page.locator('[data-action="settings"]').first().click();
      await page.locator('[data-action="reset"]').click();
      await page.locator('[data-action="confirmReset"]').click();
      assert.ok(await page.evaluate(() => cobol.call('getState').resources.bufos) >= before);
      await page.evaluate(() => { Storage.prototype.setItem = window.originalSetItem; });
      await page.evaluate(() => debugTools.game.toggleAutoSave(true));
      assert.equal(await page.evaluate(() => debugTools.game.isAutoSaveEnabled()), true);
      await page.locator('.modal [data-action="close"]').first().click();
    } else {
      assert.equal(await page.evaluate(() => typeof window.debugTools), 'undefined');
    }
    await page.setViewportSize({ width: 390, height: 844 });
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'mobile horizontal overflow');
    await page.locator('#bufo').click({ clickCount: 12, delay: 5 });
    await page.waitForTimeout(1700);
    assert.equal(await page.locator('#click-effects > *').count(), 0, 'click effects did not clean up');
    if (engine === 'chromium' && prefix === '/') {
      await page.locator('[data-action="save"]').click();
      await page.waitForFunction(() => document.querySelector('#notification').childElementCount === 0);
      await page.screenshot({ path: `${evidence}/mobile.png`, fullPage: true });
    }
    await assertErrors(development ? ['Error: Save could not be written. Progress has not been replaced.'] : []);
    reports.push({ engine, prefix, development, startupMs, result: 'passed' });
    console.log(`${engine} ${prefix}: passed (${startupMs} ms startup)`);
  } finally { await context.close(); await browser.close(); }
}
(async () => {
  await new Promise(resolve => server.listen(9130, '0.0.0.0', resolve));
  try {
    for (const engine of (process.env.BUFO_BROWSERS || 'chromium,firefox,webkit').split(',')) {
      for (const prefix of ['/', '/BufoClicker/']) await run(engine, prefix);
    }
    fs.writeFileSync(`${evidence}/report.json`, JSON.stringify(reports, null, 2) + '\n');
  } finally { server.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
