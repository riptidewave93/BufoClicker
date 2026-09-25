const assert = require('node:assert/strict');

module.exports = function captureErrors(page) {
  const errors = [];
  const pending = [];
  const interruptedImages = new Set();
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {
    if (message.type() !== 'error') return;
    const image = message.text().match(/^\[JavaScript Error: "Image corrupt or truncated\." \{file: "(https?:\/\/[^\"]+\/assets\/images\/[^\"]+)" line: 0\}\]$/);
    if (image) { interruptedImages.add(image[1]); return; }
    const args = message.args();
    if (!args.length) { errors.push(message.text()); return; }
    pending.push(Promise.all(args.map(argument => argument.evaluate(value =>
      value instanceof Error ? `${value.name}: ${value.message}` : JSON.stringify(value)
    ).catch(() => message.text()))).then(parts => errors.push(parts.join(' '))));
  });
  return async function assertErrors(expected = []) {
    await Promise.all(pending);
    // Firefox reports interrupted image decodes during navigation or DOM replacement.
    // Accept that diagnostic only after the same asset decodes successfully.
    await page.evaluate(async urls => {
      for (const url of urls) {
        const image = new Image();
        image.src = url;
        await image.decode();
        if (!image.naturalWidth) throw new Error(`Image has no pixels: ${url}`);
      }
    }, [...interruptedImages]);
    assert.deepEqual(errors.sort(), [...expected].sort());
  };
};
