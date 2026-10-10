import test from 'node:test';
import assert from 'node:assert/strict';
import { StageGame, RULES } from './engine.js';

function advance(game, seconds) { for (let i = 0; i < Math.ceil(seconds * 120); i++) game.update(1 / 120); }
function fight(game) { game.start(); advance(game, 3); }
test('three normal hits unlock one skill; duplicate taps cannot double-hit', () => {
  const game = new StageGame(); fight(game);
  assert.equal(game.skill(), false);
  for (let i = 0; i < 3; i++) {
    assert.equal(game.attack(), true); assert.equal(game.attack(), false); advance(game, 1.1);
  }
  assert.equal(game.hits, 3); assert.equal(game.charge, 3);
  assert.equal(game.skill(), true); assert.equal(game.charge, 0);
  assert.equal(game.skill(), false); advance(game, 1.9);
  assert.equal(game.cleared, 1); assert.equal(game.skills, 1);
});
test('all three phases have travel between them and finish at boss victory', () => {
  const game = new StageGame(); game.start(); let sawTravel = new Set([0]);
  for (let i = 0; i < 120 * 90 && !['won', 'lost'].includes(game.mode); i++) {
    if (game.mode === 'travel') { sawTravel.add(game.phase); assert.equal(game.attack(), false); }
    if (game.canSkill) game.skill(); else if (game.canAttack) game.attack();
    game.update(1 / 120); assert.ok(game.heroX < game.enemyX || game.mode === 'defeat');
  }
  assert.equal(game.mode, 'won'); assert.equal(game.cleared, 3);
  assert.deepEqual([...sawTravel], [0, 1, 2]); assert.ok(game.hp > 0);
});
test('pause freezes actions, HP, charge and travel; reset clears all state', () => {
  const game = new StageGame(); fight(game); game.attack(); advance(game, 0.3);
  game.togglePause(); const state = JSON.stringify(game); advance(game, 30);
  assert.equal(JSON.stringify(game), state); assert.equal(game.attack(), false);
  game.togglePause(); advance(game, 1); assert.equal(game.hits, 1);
  game.reset(); assert.equal(game.mode, 'ready'); assert.equal(game.hp, RULES.hp);
  assert.equal(game.charge, 0); assert.equal(game.hits, 0); assert.equal(game.phase, 0);
});
test('inaction permits defeat and a new game recovers', () => {
  const game = new StageGame(); fight(game); advance(game, 140);
  assert.equal(game.mode, 'lost'); assert.equal(game.hp, 0); assert.equal(game.attack(), false);
  game.reset(); assert.equal(game.start(), true); advance(game, 3); assert.equal(game.canAttack, true);
});
