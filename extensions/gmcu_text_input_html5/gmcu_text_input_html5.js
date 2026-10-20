/** Non-editable canvas text capture; leaves mobile OS keyboards closed. */
var gmcuTextInput = { active:false, queue:[], installed:false };
function gmcu_text_capture_begin() {
  var s=gmcuTextInput; s.active=true; s.queue=[];
  if(s.installed)return 0; s.installed=true;
  window.addEventListener('keydown', function(e) {
    if(!s.active || e.isComposing)return;
    if(e.ctrlKey || e.metaKey) {
      if(e.key.toLowerCase()==='c') {if(!e.repeat)s.queue.push({kind:'shortcut',value:'COPY'});return;}
      // Let the browser dispatch paste with its clipboardData, avoiding a read permission.
      if(e.key.toLowerCase()==='v') {if(!e.repeat)s.queue.push({kind:'shortcut',value:'PASTE'});return;}
      return;
    }
    if(e.key==='Enter' || e.key==='Escape') {
      e.preventDefault(); if(!e.repeat)s.queue.push({kind:'action',value:e.key==='Enter'?'DONE':'CANCEL'}); return;
    }
    if(e.key.length===1) { e.preventDefault(); if(!e.repeat)s.queue.push({kind:'char',value:e.key}); }
  },true);
  window.addEventListener('copy',function(e){if(!s.active)return; e.preventDefault(); if(s.copyAllowed){e.clipboardData.setData('text/plain',s.copyText);s.queue.push({kind:'feedback',value:'Copied'});}},true);
  window.addEventListener('paste',function(e){if(!s.active)return; e.preventDefault();s.queue.push({kind:'paste',value:e.clipboardData.getData('text/plain')});},true);
  return 0;
}
/** End capture and discard queued gestures. */
function gmcu_text_capture_end(){gmcuTextInput.active=false;gmcuTextInput.queue=[];return 0;}
/** Drain input once per active textbox step. */
function gmcu_text_capture_poll(){var q=gmcuTextInput.queue;gmcuTextInput.queue=[];return JSON.stringify(q);}
/** Request clipboard access; responses carry the initiating field/session token. */
function gmcu_text_clipboard(action,value,owner,token){
  var finish=function(ok,text){gmcuTextInput.queue.push({kind:'clipboard',action:action,owner:owner,token:token,ok:ok,value:text||''});};
  if(!navigator.clipboard){finish(false,'');return 0;}
  var request;
  try {request=action==='copy'?navigator.clipboard.writeText(value):navigator.clipboard.readText();}
  catch(e){finish(false,'');return 0;}
  Promise.resolve(request).then(function(text){finish(true,text);},function(){finish(false,'');});return 0;
}

/** Cache the active value for synchronous browser COPY gestures. */
function gmcu_text_copy_snapshot(text,allowed){gmcuTextInput.copyText=text;gmcuTextInput.copyAllowed=!!allowed;return 0;}

/** Track canvas gestures without observing touches on surrounding HTML controls. */
var gmcuTextPointer = null;
var gmcuTextCanvas = document.getElementById('canvas');
if (gmcuTextCanvas) {
  ['pointermove','pointerdown'].forEach(function(type){gmcuTextCanvas.addEventListener(type,function(e){if(e.isPrimary)gmcuTextPointer={x:e.clientX,y:e.clientY};});});
}
/** Return scaled GUI coordinates or an empty array before the first canvas gesture. */
function gmcu_text_pointer_gui(width,height){
  if(!gmcuTextPointer || !gmcuTextCanvas)return '[]';
  var r=gmcuTextCanvas.getBoundingClientRect();
  return JSON.stringify([(gmcuTextPointer.x-r.left)*width/r.width,(gmcuTextPointer.y-r.top)*height/r.height]);
}
