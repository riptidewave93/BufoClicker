import createBufoModule from './runtime/bufo.js';
import { development } from './runtime/config.js';
import { installDomBridge } from './dom-bridge.js';

const callbacks = new Map();
const callbackTokens = new WeakMap();
const references = new WeakMap();
const proxyCache = new Map();
const componentCache = new Map();
const timers = new Map();
const promises = new Map();
const settledPromises = new Map();
const html = new WeakMap();
const keyedAnimations = new WeakMap();
const deferredDomWork = [];
let runtimeDepth = 0;
const callbackFrames = new Set();
let retainedCallbacks = [];
let nextToken = 0;
let runtime;
let eventObservers = true;
let dom;
function sweepCallbacks() {
  if (runtimeDepth || !callbacks.size) return;
  const reachable = new Set(retainedCallbacks);
  const visit = value => {
    if (typeof value === 'string') { if (callbacks.has(value)) reachable.add(value); return; }
    if (value && typeof value === 'object') for (const child of Object.values(value)) visit(child);
  };
  for (const frame of callbackFrames) visit(frame);
  for (const work of deferredDomWork) visit(work.roots);
  for (const value of settledPromises.values()) visit(value);
  for (const root of dom?.callbackRoots() || []) visit(root);
  for (const id of callbacks.keys()) if (!reachable.has(id)) callbacks.delete(id);
}
function encode(value, seen = new Set()) {
  if (value === undefined) return { $oracle: 'undefined' };
  if (Object.is(value, -0)) return { $oracle: 'number', value: '-0' };
  if (typeof value === 'number' && !Number.isFinite(value)) return { $oracle: 'number', value: String(value) };
  if (value && (typeof value === 'object' || typeof value === 'function') && references.has(value)) return references.get(value);
  if (typeof value === 'function') {
    let id = callbackTokens.get(value);
    if (!id) { id = `callback-${++nextToken}`; callbackTokens.set(value, id); }
    callbacks.set(id, value);
    return { $callback: id };
  }
  if (value instanceof Element) return dom.token(value);
  if (value === null || typeof value !== 'object') return value;
  if (seen.has(value)) throw new TypeError('Cyclic values cannot cross the runtime boundary.');
  seen.add(value);
  const result = Array.isArray(value)
    ? value.map(item => encode(item, seen))
    : Object.fromEntries(Object.entries(value).map(([key, item]) => [key, encode(item, seen)]));
  seen.delete(value);
  return result;
}
function decode(value) {
  if (!value || typeof value !== 'object') return value;
  if (value.$oracle === 'number') return value.value === '-0' ? -0 : Number(value.value);
  if ('$logger' in value) return new Proxy({}, { get: (_target, method) => (...args) => dispatch({ operation: `logger.${method}`, loggerContext: value.$logger, args: encode(args) }) });
  if ('$oracle' in value) {
    const values = { undefined, NaN, Infinity, '-Infinity': -Infinity };
    return values[value.$oracle];
  }
  if ('$component' in value) {
    if (componentCache.has(value.$component)) return componentCache.get(value.$component);
    const component = new Proxy({}, { get: (_target, method) => method === 'then' ? undefined : (...args) => call(`component.${method}`, [value, ...args]) });
    references.set(component, value);
    componentCache.set(value.$component, component);
    return component;
  }
  if ('$proxy' in value) return proxy(value.$proxy);
  if ('$element' in value) return dom.element(value);
  if ('$callback' in value) return callbacks.get(value.$callback);
  if ('$callable' in value) return function (...args) { return call('time.invoke', [value.$callable, args, this]); };
  if ('$cancel' in value) return () => call('time.cancel', [value.$cancel]);
  if ('$promise' in value) {
    if (!promises.has(value.$promise)) {
      let resolve, reject;
      const promise = new Promise((done, fail) => { resolve = done; reject = fail; });
      promises.set(value.$promise, { promise, resolve, reject });
      const settled = settledPromises.get(value.$promise);
      if (settled) { settled.ok ? resolve(decode(settled.value)) : reject(new Error(settled.error)); settledPromises.delete(value.$promise); }
    }
    const promise = promises.get(value.$promise).promise;
    references.set(promise, value);
    return promise;
  }
  return Array.isArray(value)
    ? value.map(decode)
    : Object.fromEntries(Object.entries(value).map(([key, item]) => [key, decode(item)]));
}
function morphChildren(parent, next) {
  let cursor = parent.firstChild;
  for (const desired of [...next.childNodes]) {
    const same = cursor && cursor.nodeType === desired.nodeType &&
      (cursor.nodeType !== Node.ELEMENT_NODE || (cursor.tagName === desired.tagName &&
        cursor.getAttribute('data-id') === desired.getAttribute('data-id')));
    if (!same) {
      const replacement = desired.cloneNode(true);
      parent.insertBefore(replacement, cursor);
      continue;
    }
    if (cursor.nodeType === Node.TEXT_NODE) {
      if (cursor.nodeValue !== desired.nodeValue) cursor.nodeValue = desired.nodeValue;
    } else if (cursor.nodeType === Node.ELEMENT_NODE) {
      for (const attribute of [...cursor.attributes]) {
        if (!desired.hasAttribute(attribute.name)) cursor.removeAttribute(attribute.name);
      }
      for (const attribute of desired.attributes) {
        if (cursor.getAttribute(attribute.name) !== attribute.value) cursor.setAttribute(attribute.name, attribute.value);
      }
      morphChildren(cursor, desired);
    }
    cursor = cursor.nextSibling;
  }
  while (cursor) { const next = cursor.nextSibling; cursor.remove(); cursor = next; }
}
function target(command) { return document.querySelector(command.target); }
function execute(command) {
  const element = command.target ? target(command) : null;
  switch (command.kind) {
    case 'html':
      if (element && html.get(element) !== command.value) {
        const template = document.createElement('template');
        template.innerHTML = command.value;
        morphChildren(element, template.content);
        html.set(element, command.value);
      }
      break;
    case 'value': if (element) { element.value = command.value; element.focus(); element.select?.(); } break;
    case 'text': if (element && element.textContent !== command.value) element.textContent = command.value; break;
    case 'attr': if (element) command.value === null ? element.removeAttribute(command.name) : element.setAttribute(command.name, command.value); break;
    case 'style': if (element) element.style.setProperty(command.name, command.value); break;
    case 'class': if (element) element.classList.toggle(command.name, command.value); break;
    case 'remove': element?.remove(); break;
    case 'focus': element?.focus(); break;
    case 'select': element?.select(); break;
    case 'domCallback': {
      if (command.guard && !dispatch(command.guard)) return;
      let callbackResult;
      try { callbackResult = { ok: true, value: encode(callbacks.get(command.callback?.$callback)?.(decode(command.value))) }; }
      catch (error) { callbackResult = { ok: false, error: String(error.message || error) }; }
      if (command.continuation) dispatch({ ...command.continuation, callbackResult });
      return callbackResult;
    }
    case 'ephemeral': {
      let layer = document.querySelector(command.target);
      if (!layer) { layer = document.createElement('div'); layer.id = command.target.slice(1); document.body.append(layer); }
      while (layer.childElementCount >= command.limit) layer.firstElementChild.remove();
      const node = document.createElement('div'); node.className = command.className;
      node.innerHTML = command.value; node.style.left = `${command.x}px`; node.style.top = `${command.y}px`;
      layer.append(node);
      let frames = command.frames;
      if (command.constrainX) {
        const { min, max } = command.constrainX;
        const upper = Math.max(min, max - node.getBoundingClientRect().width);
        const clamp = value => Math.max(min, Math.min(value, upper));
        node.style.left = `${clamp(command.x)}px`;
        frames = frames.map(frame => frame.left === undefined ? frame : { ...frame, left: `${clamp(parseFloat(frame.left))}px` });
      }
      if (command.removeOnImageError) node.addEventListener('error', () => node.remove(), { capture: true, once: true });
      const animation = node.animate(frames, { duration: command.duration, easing: command.easing || 'ease-out' });
      animation.finished.catch(() => {}).finally(() => node.remove());
      break;
    }
    case 'animate': {
      if (!element) break;
      let active = keyedAnimations.get(element);
      if (!active) { active = new Map(); keyedAnimations.set(element, active); }
      if (command.key) active.get(command.key)?.cancel();
      const animation = element.animate(command.frames, command.options);
      if (command.key) {
        active.set(command.key, animation);
        animation.finished.catch(() => {}).finally(() => { if (active.get(command.key) === animation) active.delete(command.key); });
      }
      break;
    }
    case 'callback':
      try { return { ok: true, value: encode(callbacks.has(command.id) ? Reflect.apply(callbacks.get(command.id), decode(command.thisArg), decode(command.args || [])) : undefined) }; }
      catch (error) { return { ok: false, error: String(error.message || error) }; }
    case 'timer': {
      clearTimeout(timers.get(command.id ?? command.token));
      const id = command.id ?? command.token;
      timers.set(id, setTimeout(() => {
        timers.delete(id);
        dispatch({ operation: 'time.fire', args: [id, command.generation] });
      }, command.delay));
      break;
    }
    case 'timerCancel': clearTimeout(timers.get(command.id ?? command.token)); timers.delete(command.id ?? command.token); break;
    case 'resolve':
      if (promises.has(command.id)) { promises.get(command.id).resolve(decode(command.value)); promises.delete(command.id); }
      else settledPromises.set(command.id, { ok: true, value: command.value });
      break;
    case 'reject':
      if (promises.has(command.id)) { promises.get(command.id).reject(new Error(command.error)); promises.delete(command.id); }
      else settledPromises.set(command.id, { ok: false, error: command.error });
      break;
    case 'fetch': return fetchCommand(command);
    case 'clipboard': return navigator.clipboard.writeText(command.value).catch(error => console.warn('Clipboard unavailable', error));
    case 'log': (console[command.method] || console.log).apply(console, decode(command.args || [])); break;
    case 'reload': location.reload(); break;
    case 'download': {
      const url = URL.createObjectURL(new Blob([command.value], { type: command.type || 'text/plain' }));
      const anchor = document.createElement('a');
      anchor.href = url; anchor.download = command.name; anchor.click();
      setTimeout(() => URL.revokeObjectURL(url), 0);
      break;
    }
    default: throw new Error(`Unknown host command: ${command.kind}`);
  }
}
async function fetchCommand(command) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), command.timeout || 10000);
  try {
    const response = await fetch(command.url, { signal: controller.signal });
    return { id: command.id, ok: response.ok, status: response.status, statusText: response.statusText, text: await response.text() };
  } catch (error) { return { id: command.id, ok: false, status: 0, statusText: '', text: '', error: String(error.message || error) }; }
  finally { clearTimeout(timeout); }
}
function settle(response, frame) {
  const result = decode(response.result);
  for (const request of response.after || []) dispatch(request);
  for (const event of response.events || []) {
    const args = Object.hasOwn(event, 'payload') ? [event.name, event.payload] : [event.name];
    if (eventObservers) call('event.emit', args);
    if (response.notifyComponents) call('component.notifyEvent', args);
  }
  let callbackResult;
  const fetched = [];
  for (const command of response.commands || []) {
    const outcome = execute(command);
    frame.outcomes.push(outcome);
    if (command.kind === 'callback') callbackResult = outcome;
    if (command.kind === 'fetch') fetched.push(outcome);
  }
  const finish = commandResults => {
    if (response.continuation) return dispatch({ ...response.continuation, callbackResult, commandResults });
    if (response.ok === false) throw new Error(response.error || 'Runtime operation failed.');
    return result;
  };
  return fetched.length ? Promise.all(fetched).then(finish) : finish();
}
function dispatch(request) {
  const frame = { request, outcomes: [] };
  callbackFrames.add(frame);
  const release = () => { callbackFrames.delete(frame); sweepCallbacks(); };
  try {
    let output;
    runtimeDepth++;
    try { output = runtime.ccall('bufo_dispatch', 'string', ['string'], [JSON.stringify({ now: Date.now(), monotonicNow: performance.now(), development, ...request, collectCallbacks: callbacks.size > 0 })]); }
    finally { runtimeDepth--; }
    const response = JSON.parse(output);
    if (typeof response.eventObservers === 'boolean') eventObservers = response.eventObservers;
    frame.response = response;
    if (response.callbackRoots) retainedCallbacks = response.callbackRoots;
    else if (callbacks.size) retainedCallbacks = [...new Set([...retainedCallbacks, ...callbacks.keys()])];
    const result = settle(response, frame);
    while (!runtimeDepth && deferredDomWork.length) {
      const work = deferredDomWork.shift();
      runDomWork(work);
    }
    if (result instanceof Promise) { result.then(release, release); return result; }
    release();
    return result;
  } catch (error) { release(); throw error; }
}
function runDomWork(work) {
  const frame = { request: work.roots };
  callbackFrames.add(frame);
  try { return work.run(); }
  finally { callbackFrames.delete(frame); sweepCallbacks(); }
}
function fromDom(run, roots) {
  const work = { run, roots };
  if (runtimeDepth) { deferredDomWork.push(work); return; }
  return runDomWork(work);
}
function call(operation, args = {}) { return dispatch({ operation, args: encode(args) }); }
function ui(request) {
  return fromDom(() => renderRequest(request), request);
}
function renderRequest(request) {
  try { const result = dispatch({ ...request, browser: true }); document.querySelector('#host-error').textContent = ''; return result; }
  catch (error) { console.error(error); document.querySelector('#host-error').textContent = error.message; }
}
function proxy(path = []) {
  const key = JSON.stringify(path);
  if (proxyCache.has(key)) return proxyCache.get(key);
  const facade = new Proxy(function () {}, {
    get(_target, key) {
      if (key === 'then') return undefined;
      if (typeof key !== 'string') return undefined;
      return proxy([...path, key]);
    },
    apply(_target, _this, args) { return call('api', { path, values: args }); }
  });
  proxyCache.set(key, facade);
  references.set(facade, { $proxy: path });
  return facade;
}
try {
  runtime = await createBufoModule({ locateFile: name => new URL(`./runtime/${name}`, import.meta.url).href });
  dom = installDomBridge(request => fromDom(() => dispatch(request), request), (id, value) => fromDom(() => callbacks.get(id)?.(decode(value)), { $callback: id, value }), sweepCallbacks);
  if (development) {
    window.debugTools = proxy();
    window.cobol = Object.freeze({ call, dispatch: request => dispatch(encode(request)) });
  }
  ui({ operation: 'init', args: { hidden: document.hidden } });
  for (const eventName of ['click', 'change', 'input', 'submit']) {
    document.addEventListener(eventName, event => {
      const element = event.target.closest(`[data-${eventName}]`);
      if (!element) return;
      if (eventName === 'submit') event.preventDefault();
      const rect = element.getBoundingClientRect();
      const form = element.closest('form');
      const fields = form ? Object.fromEntries(new FormData(form)) : {};
      ui({ operation: element.dataset[eventName], args: {
        ...element.dataset, value: element.value, checked: element.checked,
        x: event.detail === 0 ? rect.x + rect.width / 2 : event.clientX, y: event.detail === 0 ? rect.y + rect.height / 2 : event.clientY, width: innerWidth, height: innerHeight, fields
      } });
    });
  }
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') ui({ operation: 'action', args: { action: 'close' } });
  });
  document.addEventListener('visibilitychange', () => ui({ operation: 'visibility', args: { hidden: document.hidden } }));
  window.addEventListener('beforeunload', () => ui({ operation: 'save.save', args: { auto: true } }));
  window.addEventListener('pagehide', () => ui({ operation: 'visibility', args: { hidden: true } }));
  let firstFrame = true;
  function frame() { ui({ operation: 'frame', args: { firstFrame } }); firstFrame = false; requestAnimationFrame(frame); }
  requestAnimationFrame(frame);
} catch (error) {
  console.error(error);
  document.querySelector('#host-error').textContent = `Could not start the game: ${error.message}. Reload to retry.`;
}
