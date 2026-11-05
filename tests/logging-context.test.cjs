const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');

const root = path.resolve(__dirname, '..');

test('logging owns runtime instance context', () => {
  const tags = fs.readFileSync(
    path.join(root, 'scripts/gmcu_log_get_tags/gmcu_log_get_tags.gml'),
    'utf8'
  );
  const textboxCreate = fs.readFileSync(
    path.join(root, 'objects/gmcu_o_textbox/Create_0.gml'),
    'utf8'
  );
  const textboxStep = fs.readFileSync(
    path.join(root, 'objects/gmcu_o_textbox/Step_0.gml'),
    'utf8'
  );
  const keyboard = fs.readFileSync(
    path.join(root, 'objects/gmcu_o_text_keyboard/Create_0.gml'),
    'utf8'
  );

  assert.match(tags, /instance_exists\(id\)/);
  assert.match(tags, /"#" \+ string\(id\)/);
  assert.doesNotMatch(textboxCreate, /diagnostic_id|instance=.*string\(id\)/);
  assert.doesNotMatch(textboxStep, /diagnostic_id|instance=.*string\(id\)/);
  assert.doesNotMatch(keyboard, /instance=.*string\(id\)/);
});
