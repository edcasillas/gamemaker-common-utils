const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const dir = path.join(__dirname, '../extensions/gmcu_disable_mobile');
const extension = JSON.parse(fs.readFileSync(path.join(dir, 'gmcu_disable_mobile.yy'), 'utf8'));
const injection = extension.HTML5CodeInjection;
const source = fs.readFileSync(path.join(__dirname, '../datafiles/disable-mobile.js'), 'utf8');

/** Execute the HTML hook with a canvas container and no GameMaker runtime. */
function fixture(navigator) {
  const nodes = {};
  const game = { style: {}, parentNode: { insertBefore(node) { nodes[node.id] = node; } } };
  nodes.gm4html5_div_id = game;
  const context = vm.createContext({ navigator, console, document: {
    getElementById: id => nodes[id],
    createElement: () => ({})
  } });
  return { game, nodes, start: () => vm.runInContext(source, context) };
}

test('desktop HTML hook leaves gameplay visible', () => {
  const f = fixture({ userAgent: 'Macintosh', platform: 'MacIntel', maxTouchPoints: 0 });
  f.start();
  assert.equal(f.game.style.display, undefined);
  assert.equal(f.nodes['mobile-message'], undefined);
});

for (const navigator of [
  { userAgent: 'iPhone' },
  { userAgent: 'Android' },
  { userAgent: 'Macintosh', platform: 'MacIntel', maxTouchPoints: 5 }
]) {
  test(`mobile warning hides gameplay: ${navigator.userAgent}`, () => {
    const f = fixture(navigator);
    f.start();
    assert.equal(f.game.style.display, 'none');
    const warning = f.nodes['mobile-message'];
    assert.match(warning.innerHTML, /This game is not designed/);
    assert.match(warning.innerHTML, /history.back\(\)/);
    f.start();
    assert.equal(f.nodes['mobile-message'], warning, 'injection is idempotent');
  });
}

// PostCanvas precedes the runner script in GameMaker's standard HTML template.
test('blocking is owned by the early HTML hook and has no runtime initializer', () => {
  assert.match(injection, /^<GM_HTML5_PostCanvas>/);
  assert.deepEqual(extension.files, []);
  assert.match(injection, /<script src="html5game\/disable-mobile.js"><\/script>/);
  assert.doesNotMatch(injection, /\b(?:async|defer)\b/);
  const f = fixture({ userAgent: 'iPhone' });
  f.start(); // No GameMaker_Init, window.onload, or resource-loading callback exists.
  assert.equal(f.game.style.display, 'none');
  assert.ok(f.nodes['mobile-message']);
});
