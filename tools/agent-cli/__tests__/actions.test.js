const { detectActions } = require('../lib/actions');
const path = require('path');

test('detectActions returns npm when package.json present', () => {
  const fixture = path.resolve(__dirname, '..');
  const actions = detectActions(fixture);
  // in our placeholder package.json present, so result should include npm
  expect(actions.some(a => a.id === 'npm')).toBe(true);
});
