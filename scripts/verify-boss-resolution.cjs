const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const assert = require('assert');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'art/workspace_materials/FocusQuest_pixel_keyframes_v014');
const old = path.join(root, 'art/workspace_materials/FocusQuest_pixel_keyframes_v013');
const runtime = path.join(root, 'mobile/assets/images/playable_stage');
const hash = buffer => crypto.createHash('sha256').update(buffer).digest('hex');

async function main() {
  const report = JSON.parse(fs.readFileSync(path.join(out, 'verification.json')));
  let keys = 0, ticks = 0, oldKeys = 0, runtimeBosses = 0, otherAssets = 0;
  for (const c of report.checks) {
    const folder = path.join(out, 'enemies', c.boss, c.action);
    const oldFolder = path.join(old, 'enemies', c.boss, c.action);
    const m = JSON.parse(fs.readFileSync(path.join(folder, 'animation.json')));
    const before = JSON.parse(fs.readFileSync(path.join(oldFolder, 'animation.json')));
    for (const field of ['fps', 'duration_seconds', 'holds', 'timeline', 'events', 'sprite_anchor_px', 'loop_in_game'])
      assert.deepStrictEqual(m[field], before[field], field + ' changed');
    for (const k of m.keyframes) {
      const data = await sharp(path.join(folder, k.file)).ensureAlpha().raw().toBuffer();
      assert.equal(data.length, 384 * 384 * 4);
      assert.equal(hash(data), k.rgba_sha256);
      // Every 192px logical pixel is exported as an exact 2x2 block.
      for (let y = 0; y < 384; y += 2) for (let x = 0; x < 384; x += 2) {
        const p = (y * 384 + x) * 4;
        for (const offset of [4, 384 * 4, 384 * 4 + 4])
          assert(data.subarray(p, p + 4).equals(data.subarray(p + offset, p + offset + 4)));
      }
      const oldData = await sharp(path.join(oldFolder, before.keyframes[k.index].file)).ensureAlpha().raw().toBuffer();
      assert.equal(hash(oldData), before.keyframes[k.index].rgba_sha256, 'Previous original altered');
      oldKeys++;
      if (c.action !== 'defeat' || k.index < m.keyframes.length - 1) {
        const enlargedOld = await sharp(path.join(oldFolder, before.keyframes[k.index].file)).resize(384, 384, { kernel: 'nearest' }).ensureAlpha().raw().toBuffer();
        assert(!data.equals(enlargedOld), 'A high-detail frame must not be a simple enlargement');
      } else {
        for (let i = 3; i < data.length; i += 4) assert.equal(data[i], 0);
      }
      keys++;
    }
    for (const row of m.timeline) {
      assert.equal(hash(await sharp(path.join(folder, row.file)).ensureAlpha().raw().toBuffer()), m.keyframes[row.keyframe].rgba_sha256);
      ticks++;
    }
  }
  const manifest = JSON.parse(fs.readFileSync(path.join(runtime, 'manifest.json')));
  for (const entry of manifest.files) {
    const bytes = fs.readFileSync(path.join(runtime, entry.file));
    assert.equal(hash(bytes), entry.sha256);
    const image = sharp(bytes), info = await image.metadata();
    assert.equal(hash(await image.ensureAlpha().raw().toBuffer()), entry.rgba_sha256);
    if (entry.file.startsWith('boss_')) {
      assert.equal(info.width, 384); assert.equal(info.height, 384); runtimeBosses++;
    } else {
      assert.equal(info.width, 128); assert.equal(info.height, 128); otherAssets++;
    }
  }
  Object.assign(report, { totalOriginals: keys, totalTimelineFrames: ticks, previousBossOriginalsPreserved: oldKeys, runtimeBossFrames: runtimeBosses, otherRuntimeFramesUnchanged: otherAssets, logicalGrid: [192, 192], exact2xExport: true, notSimple3xEnlargement: true });
  fs.writeFileSync(path.join(out, 'verification.json'), JSON.stringify(report, null, 2) + '\n');
  const bossIds = [...new Set(report.checks.map(c => c.boss))];
  await sharp({ create: { width: 1152, height: 1152, channels: 4, background: '#142235' } })
    .composite(bossIds.map((b, i) => ({ input: path.join(out, 'enemies', b, 'walk/keyframes/frame_000.png'), left: i % 3 * 384, top: Math.floor(i / 3) * 384 })))
    .png().toFile(path.join(out, 'boss-preview.png'));
  console.log(JSON.stringify({ bosses: bossIds.length, actions: report.checks.length, keys, ticks, oldKeys, runtimeBosses, otherAssets }));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
