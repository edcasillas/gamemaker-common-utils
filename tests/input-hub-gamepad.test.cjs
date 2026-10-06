const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
// Execute actual Begin Step GML with engine APIs stubbed. Only the GML dynamic
// struct accessor is translated; this is not a substitute for an engine build.
const step = fs.readFileSync(path.join(__dirname,'../objects/gmcu_o_input_hub/Step_1.gml'),'utf8')
  .replace(/\[\$ ([^\]]+)\]/g,'[$1]');
const create = fs.readFileSync(path.join(__dirname,'../objects/gmcu_o_input_hub/Create_0.gml'),'utf8');
const axisSource = create.slice(create.indexOf('function gmcu_gamepad_axis_value('));
/** Set up physical/virtual sources and execute the real hub sampling code. */
function fixture() {
  const buttons = ['gp_start','gp_select','gp_face1','gp_padl','gp_padr','gp_padu','gp_padd'];
  const keys = ['vk_left','vk_right','vk_up','vk_down'];
  const states = Object.fromEntries([...buttons,...keys].map(k=>[k,{is_down:false}]));
  const f = {owner:'gameplay', physical:false, held:new Set(), keyboard:new Set(),
    keyPressed:false, axes:[0,0], virtual:{connected:false,buttons:[],axis_x:0,axis_y:0}, events:[], polls:0};
  const context = vm.createContext({
    ...Object.fromEntries([...buttons,...keys,'gp_axislh','gp_axislv','vk_anykey'].map(k=>[k,k])),
    GMCU_INPUT_OWNER_GAMEPLAY:'gameplay', GMCU_INPUT_OWNER_DEV_MENU:'dev_menu',
    GMCU_EVENT_KEYBOARD_KEY_PRESSED:'key_down',GMCU_EVENT_KEYBOARD_KEY_RELEASED:'key_up',
    GMCU_EVENT_GAMEPAD_BUTTON_PRESSED:'pad_down',GMCU_EVENT_GAMEPAD_BUTTON_RELEASED:'pad_up',
    global:{gmcu_virtual_gamepad_provider:()=>{f.polls++;return f.virtual;},
      gmcu_registered_keyboard_keys:keys,gmcu_registered_gamepad_buttons:buttons,
      gmcu_gamepad_buttons_mapping:Object.fromEntries(buttons.map(k=>[k,k]))},
    last_input_device:undefined,prompt_axis_x:0,prompt_axis_y:0,
    sign:Math.sign,keyboard_check_pressed:()=>f.keyPressed,
    gamepads:[3], is_undefined:v=>v===undefined,array_length:a=>a.length,
    array_contains:(a,v)=>a.includes(v),abs:Math.abs,string:String,
    current_input_owner:()=>f.owner,
    keyboard_check:k=>f.keyboard.has(k),
    gamepad_is_connected:id=>f.physical && id===3,
    gamepad_button_check:(id,b)=>{assert.equal(id,3);return f.held.has(b);},
    gamepad_axis_value:(id,a)=>{assert.equal(id,3);return f.axes[a==='gp_axislh'?0:1];},
    gmcu_keyboard_input_state:k=>states[k],gmcu_gamepad_input_state:b=>states[b],
    input_state_down:(s,o)=>!!s?.is_down && s.owner===o,
    gmcu_eventbus_dispatch:(e,b)=>f.events.push([e,b]),gmcu_log_debug:()=>{},
    show_error:m=>{throw Error(m);}
  });
  vm.runInContext(axisSource,context);
  f.tick=()=>{f.events=[];vm.runInContext(step,context);};
  return Object.assign(f,{context,states});
}
test('merged hold has one press and releases only after both sources release',()=>{
  const f=fixture();f.physical=true;f.held.add('gp_face1');f.virtual={connected:true,buttons:['gp_face1'],axis_x:0,axis_y:0};
  f.tick();assert.deepEqual(f.events,[['pad_down','gp_face1']]);
  f.held.clear();f.tick();assert.deepEqual(f.events,[]);
  f.virtual.buttons=[];f.tick();assert.deepEqual(f.events,[['pad_up','gp_face1']]);
  f.tick();assert.deepEqual(f.events,[]);assert.equal(f.polls,4);
});
test('disconnecting either source releases its held buttons without physical slot zero',()=>{
  for(const virtual of [true,false]){
    const f=fixture();f.physical=!virtual;f.held.add('gp_start');
    f.virtual={connected:virtual,buttons:['gp_start'],axis_x:0,axis_y:0};f.tick();
    f.physical=false;f.virtual.connected=false;f.tick();
    assert.deepEqual(f.events,[['pad_up','gp_start']]);assert.equal(f.states.gp_start.is_down,false);
  }
});
test('axes choose greater magnitude and physical ties; keyboard and D-pad take precedence',()=>{
  const f=fixture();f.physical=true;f.axes=[-.5,.4];f.virtual={connected:true,buttons:[],axis_x:.5,axis_y:-.8};f.tick();
  assert.equal(f.context.h_axis,-.5);assert.equal(f.context.v_axis,-.8);
  f.virtual.buttons=['gp_padr'];f.tick();assert.equal(f.context.h_axis,1);
  f.keyboard.add('vk_left');f.tick();assert.equal(f.context.h_axis,-1);assert.equal(f.context.v_axis,0);
});
test('Dev Menu owns presses and axes; releasing a gameplay hold there does not dispatch gameplay',()=>{
  const f=fixture();f.virtual={connected:true,buttons:['gp_start'],axis_x:1,axis_y:0};f.tick();
  f.owner='dev_menu';f.virtual.buttons=[];f.tick();assert.deepEqual(f.events,[]);
  assert.equal(f.context.h_axis,0);assert.equal(f.context.gmcu_gamepad_axis_value('gp_axislh'),0);
  assert.equal(f.context.gmcu_gamepad_axis_value('gp_axislh','dev_menu'),1);
  f.virtual.buttons=['gp_face1'];f.tick();assert.deepEqual(f.events,[]);assert.equal(f.states.gp_face1.pressed_dev_menu,true);
  f.owner='gameplay';f.virtual.buttons=[];f.tick();assert.deepEqual(f.events,[]);
});
test('absent virtual provider and missing physical device remain neutral',()=>{
  const f=fixture();f.context.global.gmcu_virtual_gamepad_provider=undefined;f.context.gamepads=[];f.tick();
  assert.deepEqual(f.events,[]);assert.equal(f.context.h_axis,0);assert.equal(f.context.v_axis,0);
});

test('prompt device starts from virtual availability, not idle physical connection',()=>{
  const f=fixture();f.physical=true;f.tick();assert.equal(f.context.last_input_device,undefined);
  f.virtual.connected=true;f.tick();assert.equal(f.context.last_input_device,'gamepad');
  f.keyPressed=true;f.tick();assert.equal(f.context.last_input_device,'keyboard');
  f.keyPressed=false;f.tick();assert.equal(f.context.last_input_device,'keyboard');
  f.virtual.buttons=['gp_face1'];f.tick();assert.equal(f.context.last_input_device,'gamepad');
  f.physical=false;f.virtual.connected=false;f.tick();assert.equal(f.context.last_input_device,'keyboard');
});
test('fresh analog direction switches prompts; held direction, dead-zone neutral and releases do not',()=>{
  const f=fixture();f.physical=true;f.axes=[.5,0];f.tick();assert.equal(f.context.last_input_device,'gamepad');
  f.keyPressed=true;f.tick();assert.equal(f.context.last_input_device,'keyboard');
  f.keyPressed=false;f.axes=[.6,0];f.tick();assert.equal(f.context.last_input_device,'keyboard');
  f.axes=[0,0];f.tick();assert.equal(f.context.last_input_device,'keyboard');
  f.axes=[-.4,0];f.tick();assert.equal(f.context.last_input_device,'gamepad');
});
test('Dev Menu input updates prompt device without leaking game events; keyboard wins simultaneous presses',()=>{
  const f=fixture();f.owner='dev_menu';f.virtual.connected=true;f.virtual.buttons=['gp_face1'];
  f.keyPressed=true;f.tick();assert.equal(f.context.last_input_device,'keyboard');assert.deepEqual(f.events,[]);
  f.keyPressed=false;f.virtual.buttons=[];f.tick();assert.equal(f.context.last_input_device,'keyboard');
  f.virtual.buttons=['gp_face1'];f.tick();assert.equal(f.context.last_input_device,'gamepad');assert.deepEqual(f.events,[]);
});
