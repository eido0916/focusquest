const fs = require('fs'), path = require('path'), crypto = require('crypto');
const sharp = require('sharp'), assert = require('assert');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'art/workspace_materials/FocusQuest_player_reactions_v017');
const runtime = path.join(root, 'mobile/assets/images/playable_stage');
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
async function main() {
  const report = JSON.parse(fs.readFileSync(path.join(out, 'verification.json')));
  let keys = 0, ticks = 0;
  for (const c of report.checks) {
    const actor = path.join(c.female ? 'players_female' : 'players', c.character);
    const folder = path.join(out, actor, c.action);
    const meta = JSON.parse(fs.readFileSync(path.join(folder, 'animation.json')));
    assert.equal(meta.direction, 'right'); assert.equal(meta.interpolation, 'none');
    assert.equal(meta.part_transforms, false); assert.equal(meta.crossfade, false);
    assert.equal(meta.loop_in_game, false); assert.equal(meta.fps, 24);
    assert.equal(meta.keyframes.length, 4);
    let firstHeight = 0, finalHeight = 0;
    for (const k of meta.keyframes) {
      const data = await sharp(path.join(folder, k.file)).ensureAlpha().raw().toBuffer();
      assert.equal(data.length, 128 * 128 * 4);
      assert.equal(hash(data), k.rgba_sha256);
      let top = 128, bottom = 0;
      for (let y = 0; y < 128; y += 2) for (let x = 0; x < 128; x += 2) {
        const p = (y * 128 + x) * 4;
        for (const offset of [4, 128 * 4, 128 * 4 + 4])
          assert(data.subarray(p, p + 4).equals(data.subarray(p + offset, p + offset + 4)));
        assert([0, 255].includes(data[p + 3]));
        if (data[p + 3]) { top = Math.min(top, y); bottom = Math.max(bottom, y + 2); }
      }
      assert(bottom > top, 'Original must stay visible: ' + c.character);
      if (k.index === 0) firstHeight = bottom - top;
      if (k.index === 3) finalHeight = bottom - top;
      const file = `${c.character}_${c.action}_${String(k.index).padStart(3, '0')}.png`;
      assert.equal(hash(fs.readFileSync(path.join(runtime, file))), hash(fs.readFileSync(path.join(folder, k.file))));
      keys++;
    }
    if (c.action === 'defeat') { assert(meta.hold_last_frame); assert(finalHeight < firstHeight); }
    for (const row of meta.timeline) {
      assert.equal(hash(await sharp(path.join(folder, row.file)).ensureAlpha().raw().toBuffer()), meta.keyframes[row.keyframe].rgba_sha256);
      ticks++;
    }
    const registration = JSON.parse(fs.readFileSync(path.join(out, 'source', c.character, 'registration.json')));
    assert(Math.abs(registration.standingReferenceHeightPx - registration.standingOriginalHeightPx) <= 1);
    assert.equal(hash(fs.readFileSync(path.join(root, registration.reference))), registration.referenceSha256);
  }
  const previous = JSON.parse(fs.readFileSync(path.join(out, 'previous_runtime_assets.json')));
  for (const [file, digest] of Object.entries(previous)) assert.equal(hash(fs.readFileSync(path.join(runtime, file))), digest);
  Object.assign(report, { verifiedOriginals: keys, verified24fpsFrames: ticks, exactRgbaEquality: true,
    exact2xLogicalGrid: true, allFinalDefeatPosesVisibleAndKneeling: true,
    preservedPreviousRuntimeAssets: Object.keys(previous).length });
  fs.writeFileSync(path.join(out, 'verification.json'), JSON.stringify(report, null, 2) + '\n');
  const actors = [...new Map(report.checks.map(c => [c.character, c])).values()];
  const cols = 8, rows = Math.ceil(actors.length / cols), width = cols * 128, height = rows * 128;
  const sheets = [];
  for (const action of ['hurt', 'defeat']) for (let pose = 0; pose < 4; pose++) {
    sheets.push(await sharp({ create: { width, height, channels: 4, background: '#142235' } })
      .composite(actors.map((c, i) => ({ input: path.join(runtime, `${c.character}_${action}_${String(pose).padStart(3, '0')}.png`),
        left: i % cols * 128, top: Math.floor(i / cols) * 128 }))).png().toBuffer());
  }
  fs.writeFileSync(path.join(out, 'kneeling-preview.png'), sheets[7]);
  const rawSheets = await Promise.all(sheets.map(b => sharp(b).ensureAlpha().raw().toBuffer()));
  await sharp(Buffer.concat(rawSheets), { raw: { width, height: height * 8, channels: 4, pageHeight: height } })
    .gif({ loop: 0, delay: [40, 80, 125, 250, 165, 250, 335, 1700] }).toFile(path.join(out, 'reactions-preview.gif'));
  console.log(JSON.stringify({ actors: actors.length, motions: report.checks.length, keys, ticks, previous: Object.keys(previous).length }));
}
main().catch(e => { console.error(e); process.exitCode = 1; });
