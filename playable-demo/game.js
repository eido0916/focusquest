import { StageGame, RULES } from './engine.js';

const $ = (id) => document.getElementById(id);
const canvas = $('game');
const ctx = canvas.getContext('2d');
const animations = new Map();
const game = new StageGame();
const floats = [];
let background;
let last = 0;
let loaded = false;
let deathX = 770;
let messageUntil = 0;
let lastUi = '';

async function loadImage(src) {
  const image = new Image();
  image.src = src;
  await image.decode();
  return image;
}
async function loadAnimation(name) {
  const base = `assets/${name}/`;
  const response = await fetch(`${base}animation.json`);
  if (!response.ok) throw new Error(`${name}: ${response.status}`);
  const meta = await response.json();
  const images = await Promise.all(meta.keyframes.map(key => loadImage(base + key.file)));
  animations.set(name, { meta, images });
}
function message(text, duration = 2.2) {
  $('stage-message').textContent = text;
  messageUntil = game.clock + duration;
}
function events() {
  for (const event of game.drainEvents()) {
    if (event.type === 'travel') message(game.phase === 0 ? '最初の戦いへ' : '次のフェーズへ走行中', RULES.travel);
    if (event.type === 'battle') message(game.current.boss ? 'BOSS · ドラキュラが現れた！' : `PHASE ${game.phase + 1} · ${game.current.name}が現れた！`);
    if (event.type === 'skill') message('蓄力斬撃！', 1.9);
    if (event.type === 'enemyHit') floats.push({ x: game.enemyX, y: 380, time: game.clock, text: `${event.amount}`, skill: event.skill });
    if (event.type === 'heroHit') floats.push({ x: game.heroX, y: 360, time: game.clock, text: `−${event.amount}`, hurt: true });
    if (event.type === 'enemyDefeated') { deathX = game.enemyX; message(`${game.current.name}を倒した！`, 1.8); }
    if (event.type === 'won') showResult(true);
    if (event.type === 'lost') showResult(false);
  }
}
function showResult(won) {
  $('overlay').hidden = false;
  $('overlay-kicker').textContent = won ? 'STAGE CLEAR' : 'TRY AGAIN';
  $('overlay-title').textContent = won ? '草原を、駆け抜けた。' : 'もう一度、挑もう。';
  $('overlay-copy').textContent = won
    ? `3フェーズ突破！ 通常攻撃 ${game.hits}回 · スキル ${game.skills}回 · ${Math.ceil(game.clock)}秒`
    : `${game.phase + 1}フェーズ目で力尽きた。攻撃3回でスキルを解放しよう。`;
  $('start').textContent = 'もう一度プレイ';
  $('overlay-keys').textContent = won ? '次の冒険への第一歩。' : '攻撃とスキルを組み合わせて、ボスに挑もう。';
}
function restart() {
  game.reset(); floats.length = 0; deathX = 770; messageUntil = 0;
  game.start(); $('overlay').hidden = true; lastUi = ''; events(); updateUi();
}
function syncPauseOverlay() {
  if (game.paused) {
    $('overlay').hidden = false; $('overlay-kicker').textContent = 'PAUSED';
    $('overlay-title').textContent = 'ひと休み。'; $('overlay-copy').textContent = '準備ができたら、冒険を続けよう。';
    $('start').textContent = '冒険を再開'; $('overlay-keys').textContent = 'Pキーでも再開できます。';
  } else $('overlay').hidden = true;
}
function togglePause() { if (game.togglePause()) { syncPauseOverlay(); updateUi(); } }
$('start').addEventListener('click', () => {
  if (!loaded) return;
  if (game.paused) togglePause(); else restart();
});
$('reset').addEventListener('click', () => { if (loaded) restart(); });
$('pause').addEventListener('click', togglePause);
$('attack').addEventListener('click', () => { game.attack(); updateUi(); });
$('skill').addEventListener('click', () => { game.skill(); events(); updateUi(); });
document.addEventListener('keydown', event => {
  if (event.repeat || event.ctrlKey || event.metaKey || event.altKey) return;
  const key = event.key.toLowerCase();
  if (key === 'a') game.attack();
  if (key === 's') game.skill();
  if (key === 'p' || key === 'escape') togglePause();
  events(); updateUi();
});
document.addEventListener('visibilitychange', () => {
  if (document.hidden && !game.paused && ['travel', 'battle', 'defeat'].includes(game.mode)) togglePause();
});
function updateUi() {
  const token = [game.mode, game.phase, game.hp, game.enemyHp, game.charge, !!game.action, game.paused, loaded].join(':');
  if (token === lastUi) return;
  lastUi = token;
  $('hero-hp').textContent = `${game.hp} / ${RULES.hp}`;
  $('hero-bar').style.width = `${game.hp / RULES.hp * 100}%`;
  $('enemy-hp').textContent = `${game.enemyHp} / ${game.current.hp}`;
  $('enemy-bar').style.width = `${game.enemyHp / game.current.hp * 100}%`;
  $('enemy-name').textContent = `${game.current.boss ? 'BOSS · ' : ''}${game.current.name}`;
  document.querySelector('.enemy-panel').hidden = ['travel', 'ready'].includes(game.mode);
  $('phase-label').textContent = game.current.subtitle;
  $('attack').disabled = !game.canAttack;
  $('skill').disabled = !game.canSkill;
  $('skill').classList.toggle('ready', game.charge === RULES.charge);
  $('skill-label').textContent = game.charge === RULES.charge ? '蓄力斬撃 · 発動可能' : `蓄力斬撃 · あと${RULES.charge - game.charge}回`;
  $('skill').setAttribute('aria-label', game.charge === RULES.charge ? 'スキル、蓄力斬撃を発動' : `スキル、あと${RULES.charge - game.charge}回の通常攻撃命中で解放`);
  document.querySelectorAll('.charge-pips i').forEach((pip, index) => pip.classList.toggle('filled', index < game.charge));
  document.querySelectorAll('[data-phase]').forEach((li, index) => {
    li.classList.toggle('active', index === game.phase && game.mode !== 'won');
    li.classList.toggle('complete', index < game.cleared);
    li.setAttribute('aria-current', index === game.phase ? 'step' : 'false');
  });
  $('pause').disabled = !['travel', 'battle', 'defeat'].includes(game.mode);
  $('pause').textContent = game.paused ? '再開' : '一時停止';
  const labels = { ready: '準備完了', travel: '走行中', battle: '戦闘中', defeat: 'フェーズ突破', won: 'ステージクリア', lost: '再挑戦できます' };
  $('state-label').textContent = game.paused ? '一時停止中' : labels[game.mode];
  $('journey-title').textContent = game.mode === 'won' ? '3フェーズ、すべて突破！' : `PHASE ${game.phase + 1} / 3 · ${game.current.name}${game.current.boss ? 'との決戦' : 'との戦い'}`;
  $('journey-copy').textContent = game.mode === 'travel' ? '敵のいる場所へ向かっています。' : '通常攻撃3回の命中で、スキルを解放。';
}
function frameAt(name, elapsed, loop = false) {
  const animation = animations.get(name);
  if (!animation) return null;
  let tick = Math.floor(elapsed * 24);
  tick = loop ? tick % animation.meta.timeline.length : Math.min(tick, animation.meta.timeline.length - 1);
  const row = animation.meta.timeline[Math.max(0, tick)];
  return { image: animation.images[row.keyframe], offset: row.root_offset_px ?? [0, 0] };
}
function drawSprite(name, elapsed, x, loop = false) {
  const frame = frameAt(name, elapsed, loop);
  if (!frame) return;
  // Source PNG is a doubled 64px logical grid. Keep logical pixels integer sized.
  const logicalScale = Math.max(1, Math.floor(canvas.width / 300));
  const size = 64 * logicalScale;
  const ratio = size / 128;
  const ground = Math.round(canvas.height * 0.885);
  const px = Math.round(x / 1280 * canvas.width - size / 2 + frame.offset[0] * ratio);
  const py = Math.round(ground - 114 * ratio + frame.offset[1] * ratio);
  ctx.drawImage(frame.image, px, py, size, size);
}
function render() {
  const rect = canvas.getBoundingClientRect();
  const dpr = window.devicePixelRatio || 1;
  const w = Math.round(rect.width * dpr), h = Math.round(rect.height * dpr);
  if (canvas.width !== w || canvas.height !== h) { canvas.width = w; canvas.height = h; }
  ctx.imageSmoothingEnabled = false;
  ctx.clearRect(0, 0, w, h);
  if (background) {
    // Continuous world travel: repeat the immutable background, shift its position.
    const shift = Math.round((game.distance * 0.35 / 1280 * w) % w);
    const height = Math.max(h, Math.round(w / background.width * background.height));
    const top = Math.round(h * 0.885 - height * 0.885);
    ctx.drawImage(background, -shift, top, w, height);
    if (shift) ctx.drawImage(background, w - shift, top, w, height);
  }
  if (!loaded) return;
  const heroName = game.action ? `hero/${game.action.name}` : game.mode === 'travel' ? 'hero/run' : 'hero/idle';
  drawSprite(heroName, game.action?.time ?? (game.mode === 'travel' ? game.modeTime : game.clock), game.heroX, !game.action);
  if (!['ready', 'won', 'lost'].includes(game.mode)) {
    if (game.mode === 'defeat') drawSprite(`${game.current.id}/defeat`, game.modeTime, deathX);
    else if (game.mode === 'battle') drawSprite(`${game.current.id}/${game.enemyAction ? 'attack' : 'locomotion'}`, game.enemyAction?.time ?? game.modeTime, game.enemyX, !game.enemyAction);
    else if (game.modeTime > 1.8) drawSprite(`${game.current.id}/locomotion`, game.modeTime, game.enemyX, true);
  }
  for (let i = floats.length - 1; i >= 0; i--) {
    const f = floats[i]; const age = game.clock - f.time;
    if (age > 1) { floats.splice(i, 1); continue; }
    const x = Math.round(f.x / 1280 * w), y = Math.round((f.y - age * 70) / 720 * h);
    ctx.font = `800 ${Math.max(16, Math.round(w / 48))}px sans-serif`;
    ctx.textAlign = 'center'; ctx.lineWidth = Math.max(3, Math.round(w / 300));
    ctx.strokeStyle = '#173025'; ctx.fillStyle = f.hurt ? '#ffd2bf' : f.skill ? '#e0ffe7' : '#fff5c8';
    ctx.strokeText(f.text, x, y); ctx.fillText(f.text, x, y);
  }
}
function loop(now) {
  const dt = last ? (now - last) / 1000 : 0; last = now;
  if (loaded) { game.update(dt); events(); updateUi(); }
  if (messageUntil && game.clock > messageUntil) { $('stage-message').textContent = ''; messageUntil = 0; }
  render(); requestAnimationFrame(loop);
}
async function boot() {
  try {
    const manifest = await (await fetch('assets/manifest.json')).json();
    await Promise.all([loadImage('assets/grassland.png').then(image => { background = image; }), ...manifest.animations.map(loadAnimation)]);
    game.durations.attack = animations.get('hero/attack').meta.duration_seconds;
    game.durations.skill = animations.get('hero/skill').meta.duration_seconds;
    loaded = true; $('start').disabled = false; $('start').textContent = '冒険をはじめる'; updateUi();
  } catch (error) {
    $('start').textContent = '読み込みに失敗しました';
    $('overlay-copy').textContent = 'ページを再読み込みしてください。ローカルではHTTPサーバーから開いてください。';
    $('overlay-copy').classList.add('loading-error'); console.error(error);
  }
}
requestAnimationFrame(loop); boot();
