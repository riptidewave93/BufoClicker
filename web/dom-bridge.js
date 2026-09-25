/* Generic DOM handles, commands and callback transport. No application markup. */
export function installDomBridge(dispatch, invokeCallback = () => {}, rootsChanged = () => {}) {
  const nodes = new Map();
  const identities = new WeakMap();
  const listeners = new Map();
  const timers = new Map();
  const activeCallbacks = new Set();
  let sequence = 0;
  const token = node => {
    if (!node) return null;
    let key = identities.get(node);
    if (!key) { key = `dom-${++sequence}`; identities.set(node, key); nodes.set(key, node); }
    return {$element: key};
  };
  const element = value => {
    if (!value) return null;
    if (value.$element === 'body') return document.body;
    if (value.$element === 'head') return document.head;
    if (value.$element === 'document') return document;
    return nodes.get(value.$element) || null;
  };
  const transport = event => ({type: event.type, clientX: event.clientX, clientY: event.clientY,
    key: event.key, button: event.button, value: event.target?.value,
    target: token(event.target), currentTarget: token(event.currentTarget)});
  const fire = (callback, value) => {
    const active = { callback };
    activeCallbacks.add(active);
    try {
      if (callback?.operation) return dispatch({...callback, args: [...(callback.args || []), value]});
      if (callback?.$callback) return invokeCallback(callback.$callback, value);
    } finally { activeCallbacks.delete(active); rootsChanged(); }
  };
  const morph = (parent, next) => {
    let cursor = parent.firstChild;
    for (const desired of [...next.childNodes]) {
      const compatible = cursor && cursor.nodeType === desired.nodeType &&
        (cursor.nodeType !== Node.ELEMENT_NODE || cursor.tagName === desired.tagName);
      if (!compatible) { const node = desired.cloneNode(true); parent.insertBefore(node,cursor); cursor = node.nextSibling; continue; }
      if (cursor.nodeType === Node.ELEMENT_NODE) {
        for (const attribute of [...cursor.attributes]) if (!desired.hasAttribute(attribute.name)) cursor.removeAttribute(attribute.name);
        for (const attribute of desired.attributes) if (cursor.getAttribute(attribute.name) !== attribute.value) cursor.setAttribute(attribute.name,attribute.value);
        morph(cursor,desired);
      } else if (cursor.nodeValue !== desired.nodeValue) cursor.nodeValue = desired.nodeValue;
      cursor = cursor.nextSibling;
    }
    while (cursor) { const next = cursor.nextSibling; cursor.remove(); cursor = next; }
  };
  const bridge = command => {
    const node = element(command.element);
    switch (command.kind) {
      case 'confirm': return globalThis.confirm(command.message);
      case 'create': return token(document.createElement(command.tag || 'div'));
      case 'byId': return token(document.getElementById(command.id));
      case 'query': {
        try { return token((node || document).querySelector(command.selector)); } catch { return null; }
      }
      case 'queryAll': {
        try { return Array.from((node || document).querySelectorAll(command.selector), token); } catch { return []; }
      }
      case 'nextSibling': return token(node?.nextElementSibling);
      case 'closest': return token(node?.closest(command.selector));
      case 'rect': {
        if (!node) return null;
        const r = node.getBoundingClientRect();
        return {x:r.x,y:r.y,left:r.left,top:r.top,right:r.right,bottom:r.bottom,width:r.width,height:r.height};
      }
      case 'viewport': return {width:innerWidth,height:innerHeight};
      case 'computed': return node ? getComputedStyle(node)[command.name] : null;
      case 'getStyle': return node?.style[command.name] || '';
      case 'getAttribute': return node?.getAttribute(command.name) ?? null;
      case 'getId': return node?.id || null;
      case 'contains': return Boolean(node?.contains(element(command.child)));
      case 'html': if (node) { if(command.morph){const next=document.createElement('template');next.innerHTML=command.value;morph(node,next.content);}else if(command.append)node.innerHTML += command.value; else node.innerHTML=command.value; } return null;
      case 'text': if (node)node.textContent=command.value; return null;
      case 'attribute': if(node) { if(command.value === null)node.removeAttribute(command.name); else node.setAttribute(command.name,String(command.value)); } return null;
      case 'property': if(node)node[command.name]=command.value; return null;
      case 'style': if(node)node.style[command.name]=String(command.value); return null;
      case 'class':
        if(node) for(const name of command.names || []) {
          if(!name)continue;
          try {
            if(command.action==='toggle') { if('force' in command)node.classList.toggle(name,command.force); else node.classList.toggle(name); }
            else node.classList[command.action](name);
          } catch { /* Match the safe DOM utility contract for malformed classes. */ }
        }
        return null;
      case 'append': if(node && element(command.child))node.appendChild(element(command.child)); return null;
      case 'prepend': if(node && element(command.child))node.prepend(element(command.child)); return null;
      case 'remove': node?.remove(); return null;
      case 'focus': node?.focus(); return null;
      case 'select': node?.select(); return null;
      case 'listen': {
        const key=command.id;
        if(listeners.has(key))return null;
        const listener=event=>{
          if(command.preventDefault)event.preventDefault();
          if(command.stopPropagation)event.stopPropagation();
          fire(command.callback,transport(event));
        };
        node?.addEventListener(command.event,listener,Boolean(command.capture));
        listeners.set(key,{node,event:command.event,listener,capture:Boolean(command.capture),callback:command.callback});return null;
      }
      case 'unlisten': {
        const previous=listeners.get(command.id);
        if(previous)previous.node?.removeEventListener(previous.event,previous.listener,previous.capture);
        listeners.delete(command.id);rootsChanged();return null;
      }
      case 'schedule': {
        const key=command.id;
        if(timers.has(key)) { const old=timers.get(key); old.frame?cancelAnimationFrame(old.id):clearTimeout(old.id); }
        const run=time=>{timers.delete(key);fire(command.callback,{now:performance.now(),wallNow:Date.now(),time});};
        const id=command.frame?requestAnimationFrame(run):setTimeout(run,command.delay || 0);
        timers.set(key,{id,frame:Boolean(command.frame),callback:command.callback});return null;
      }
      case 'cancel': {
        const timer=timers.get(command.id);
        if(timer)timer.frame?cancelAnimationFrame(timer.id):clearTimeout(timer.id);
        timers.delete(command.id);rootsChanged();return null;
      }
      case 'callback': return fire(command.callback,command.value);
      case 'release': if(node){nodes.delete(command.element.$element);identities.delete(node);} return null;
      default: throw new Error(`Unknown DOM command: ${command.kind}`);
    }
  };
  globalThis.bufoDomBridge = bridge;
  return {token,element,callbackRoots: () => [...listeners.values(), ...timers.values(), ...activeCallbacks].map(record => record.callback),dispose() {
    for(const {node,event,listener,capture} of listeners.values())node?.removeEventListener(event,listener,capture);
    for(const {id,frame} of timers.values())frame?cancelAnimationFrame(id):clearTimeout(id);
    listeners.clear();timers.clear();nodes.clear();rootsChanged();
    if(globalThis.bufoDomBridge===bridge)delete globalThis.bufoDomBridge;
  }};
}
