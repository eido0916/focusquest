export const PHASES = [
  { id: 'slime', name: 'スライム', hp: 112, damage: 8, interval: 4.8, subtitle: '草原の入り口' },
  { id: 'goblin', name: 'ゴブリン', hp: 168, damage: 11, interval: 4.2, subtitle: '見張りの丘' },
  { id: 'dracula', name: 'ドラキュラ', hp: 280, damage: 14, interval: 3.8, subtitle: '草原の主', boss: true },
];
export const RULES = { hp: 160, attackDamage: 28, skillDamage: 112, charge: 3, travel: 2.8 };

// Only world coordinates move. Sprite pixels never rotate, morph, or interpolate.
export class StageGame {
  constructor(durations = {}) {
    this.durations = { attack: 1, skill: 1.75, enemyAttack: 1, defeat: 1.25, ...durations };
    this.reset();
  }
  reset() {
    this.mode = 'ready'; this.paused = false; this.phase = 0; this.hp = RULES.hp;
    this.charge = 0; this.enemyHp = PHASES[0].hp; this.clock = 0; this.modeTime = 0;
    this.action = null; this.enemyAction = null; this.enemyWait = 0;
    this.heroX = 295; this.enemyX = 855; this.distance = 0;
    this.hits = 0; this.skills = 0; this.cleared = 0; this.events = [];
  }
  get current() { return PHASES[this.phase]; }
  get canAttack() { return this.mode === 'battle' && !this.paused && !this.action; }
  get canSkill() { return this.canAttack && this.charge >= RULES.charge; }
  emit(type, extra = {}) { this.events.push({ type, time: this.clock, ...extra }); }
  drainEvents() { return this.events.splice(0); }
  start() {
    if (this.mode !== 'ready') return false;
    this.mode = 'travel'; this.modeTime = 0; this.emit('travel'); return true;
  }
  togglePause() {
    if (!['travel', 'battle', 'defeat'].includes(this.mode)) return false;
    this.paused = !this.paused; return true;
  }
  attack() {
    if (!this.canAttack) return false;
    this.action = { name: 'attack', time: 0, hit: false }; return true;
  }
  skill() {
    if (!this.canSkill) return false;
    this.charge = 0; this.skills++; this.action = { name: 'skill', time: 0, hit: false };
    this.emit('skill'); return true;
  }
  damageEnemy(amount, skill) {
    if (this.mode !== 'battle') return;
    this.enemyHp = Math.max(0, this.enemyHp - amount);
    if (!skill) { this.hits++; this.charge = Math.min(RULES.charge, this.charge + 1); }
    this.emit('enemyHit', { amount, skill });
    if (this.enemyHp === 0) {
      this.mode = 'defeat'; this.modeTime = 0; this.enemyAction = null;
      this.cleared++; this.emit('enemyDefeated');
    }
  }
  update(dt) {
    if (this.paused || ['ready', 'won', 'lost'].includes(this.mode)) return;
    // Clamp browser stalls; returning to the tab cannot instantly kill the player.
    dt = Math.max(0, Math.min(dt, 0.1)); this.clock += dt; this.modeTime += dt;
    if (this.action) {
      const a = this.action; a.time += dt;
      const hitAt = a.name === 'skill' ? 31 / 24 : 13 / 24;
      if (!a.hit && a.time >= hitAt) {
        a.hit = true; this.damageEnemy(a.name === 'skill' ? RULES.skillDamage : RULES.attackDamage, a.name === 'skill');
      }
      // Lunge in world space toward the opponent, then return to the left side.
      const duration = this.durations[a.name];
      const progress = a.time / duration;
      const excursion = progress < 0.24 ? progress / 0.24 : progress > 0.8 ? (1 - progress) / 0.2 : 1;
      this.heroX = Math.round(295 + 315 * Math.max(0, Math.min(1, excursion)));
      if (a.time >= duration) { this.action = null; this.heroX = 295; }
    }
    if (this.mode === 'travel') {
      this.distance += dt * 105; this.heroX = 295;
      this.enemyX = 1330 - Math.min(1, this.modeTime / RULES.travel) * 560;
      if (this.modeTime >= RULES.travel) {
        this.mode = 'battle'; this.modeTime = 0; this.enemyX = 770; this.enemyWait = 1.6;
        this.emit('battle', { phase: this.phase });
      }
    } else if (this.mode === 'battle') {
      if (!this.enemyAction) {
        this.enemyWait -= dt;
        if (this.enemyWait <= 0) this.enemyAction = { time: 0, hit: false };
      } else {
        const a = this.enemyAction; a.time += dt;
        const progress = a.time / this.durations.enemyAttack;
        this.enemyX = Math.round(770 - 130 * (progress < 0.25 ? progress / 0.25 : progress > 0.8 ? (1 - progress) / 0.2 : 1));
        if (!a.hit && a.time >= 11 / 24) {
          a.hit = true; this.hp = Math.max(0, this.hp - this.current.damage);
          this.emit('heroHit', { amount: this.current.damage });
          if (this.hp === 0) { this.mode = 'lost'; this.action = null; this.emit('lost'); }
        }
        if (a.time >= this.durations.enemyAttack) {
          this.enemyAction = null; this.enemyX = 770; this.enemyWait = this.current.interval;
        }
      }
    } else if (this.mode === 'defeat' && this.modeTime >= this.durations.defeat && !this.action) {
      if (this.phase === PHASES.length - 1) { this.mode = 'won'; this.emit('won'); }
      else {
        this.phase++; this.enemyHp = this.current.hp; this.enemyX = 1330;
        this.hp = Math.min(RULES.hp, this.hp + 16); this.mode = 'travel'; this.modeTime = 0;
        this.emit('travel');
      }
    }
  }
}
