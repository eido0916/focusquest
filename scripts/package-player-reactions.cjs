// Package independently drawn pixel poses; generate no intermediate images.
// NODE_PATH=<node_modules> node scripts/package-player-reactions.cjs inputs.json
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const assert = require('assert');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'art/workspace_materials/FocusQuest_player_reactions_v017');
const runtime = path.join(root, 'mobile/assets/images/playable_stage');
const inputs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const json = (p, data) => fs.writeFileSync(p, JSON.stringify(data, null, 2) + '\n');
const png = raw => sharp(raw.data, { raw: { width: raw.width, height: raw.height, channels: 4 } });

// Drop isolated export specks, never a connected character/weapon drawing.
function extractDrawings(data, width, height) {
  const visited = new Uint8Array(width * height);
  const queue = new Int32Array(width * height);
  const groups = Array.from({ length: 8 }, () => []);
  for (let start = 0; start < visited.length; start++) {
    if (visited[start] || data[start * 4 + 3] < 128) continue;
    let head = 0, tail = 1; queue[0] = start; visited[start] = 1;
    while (head < tail) {
      const i = queue[head++], x = i % width, y = Math.floor(i / width);
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        const n = ny * width + nx;
        if (!visited[n] && data[n * 4 + 3] >= 128) {
          visited[n] = 1; queue[tail++] = n;
        }
      }
    }
    if (tail < 32) continue;
    let cx = 0, cy = 0;
    for (let i = 0; i < tail; i++) {
      cx += queue[i] % width; cy += Math.floor(queue[i] / width);
    }
    cx /= tail; cy /= tail;
    const col = Math.max(0, Math.min(3, Math.floor(cx / (width / 4))));
    const row = Math.max(0, Math.min(1, Math.round(cy / (height / 2) - .55)));
    for (let i = 0; i < tail; i++) groups[row * 4 + col].push(queue[i]);
  }
  return groups.map((pixels, index) => {
    assert(pixels.length, 'Missing original pose ' + index);
    let l = width, t = height, r = 0, b = 0;
    for (const p of pixels) {
      const x = p % width, y = Math.floor(p / width);
      l = Math.min(l, x); r = Math.max(r, x + 1);
      t = Math.min(t, y); b = Math.max(b, y + 1);
    }
    const cropped = Buffer.alloc((r - l) * (b - t) * 4);
    for (const p of pixels) {
      const j = ((Math.floor(p / width) - t) * (r - l) + p % width - l) * 4;
      data.copy(cropped, j, p * 4, p * 4 + 4); cropped[j + 3] = 255;
    }
    const originX = Math.round(index % 4 * width / 4);
    const originY = Math.round(Math.floor(index / 4) * height / 2);
    return { data: cropped, width: r - l, height: b - t,
      box: { l: l - originX, r: r - originX, t: t - originY, b: b - originY } };
  });
}

function bounds(data, width, height) {
  let l = width, t = height, r = 0, b = 0;
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    if (data[(y * width + x) * 4 + 3] < 128) continue;
    l = Math.min(l, x); t = Math.min(t, y); r = Math.max(r, x + 1); b = Math.max(b, y + 1);
  }
  assert(r > l && b > t, 'Every original must remain visible');
  return { l, t, r, b, width: r - l, height: b - t };
}

async function main() {
  fs.mkdirSync(out, { recursive: true });
  const manifest = JSON.parse(fs.readFileSync(path.join(runtime, 'manifest.json'), 'utf8'));
  // Protect all earlier assets, including attacks, bosses, projectile originals.
  const previous = new Map(manifest.files.filter(f => !/character_.*_(hurt|defeat)_/.test(f.file))
    .map(f => [f.file, hash(fs.readFileSync(path.join(runtime, f.file)))]));
  if (!fs.existsSync(path.join(out, 'previous_runtime_assets.json'))) {
    json(path.join(out, 'previous_runtime_assets.json'), Object.fromEntries(previous));
  }
  const checks = [];
  for (const spec of inputs) {
    const source = path.join(out, 'source', spec.id);
    fs.mkdirSync(source, { recursive: true });
    const atlas = path.join(source, 'original_atlas.png');
    if (path.resolve(root, spec.path) !== atlas) fs.copyFileSync(path.resolve(root, spec.path), atlas);
    const reference = path.resolve(root, spec.ref);
    fs.copyFileSync(reference, path.join(source, 'reference.png'));
    fs.writeFileSync(path.join(source, 'prompt.txt'), spec.prompt + '\n');
    const ref = await sharp(reference).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const refBounds = bounds(ref.data, ref.info.width, ref.info.height);
    const rawAtlas = await sharp(atlas).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const originals = extractDrawings(rawAtlas.data, rawAtlas.info.width, rawAtlas.info.height);
    const refMetaFile = reference.replace(/_000\.png$/, '.json');
    const refMeta = JSON.parse(fs.readFileSync(refMetaFile, 'utf8'));
    const anchor = refMeta.sprite_anchor_px || [64, 114];
    const scale = refBounds.height / 2 / originals[0].height;
    const winged = ['天使', '悪魔'].includes(spec.role);
    const baseline = Math.round((winged ? anchor[1] : refBounds.b) / 2);
    const hoverOffset = winged ? Math.min(0, refBounds.b - anchor[1]) : 0;
    const sizes = originals.map(p => ({ w: Math.max(1, Math.round(p.width * scale)), h: Math.max(1, Math.round(p.height * scale)) }));
    assert(sizes.every(s => s.w <= 62 && s.h <= 62), 'Pose exceeds fixed character scale: ' + spec.id);
    const center = (refBounds.l + refBounds.r) / 4;
    const relative = originals.map(p => (p.box.l + p.box.r) / 2 - (originals[0].box.l + originals[0].box.r) / 2);
    const lefts = sizes.map((s, i) => Math.round(center + relative[i] * scale - s.w / 2));
    // Register the entire drawings together; never resize a part or an action.
    const minLeft = Math.min(...lefts), maxRight = Math.max(...lefts.map((l, i) => l + sizes[i].w));
    const sharedShift = minLeft < 1 ? 1 - minLeft : maxRight > 63 ? 63 - maxRight : 0;
    const images = [];
    for (let i = 0; i < originals.length; i++) {
      const { w, h } = sizes[i];
      const left = lefts[i] + sharedShift, top = baseline - h;
      assert(left >= 1 && left + w <= 63 && top >= 1 && baseline <= 63);
      const image = await png(originals[i]).resize(w, h, { kernel: 'nearest' }).png().toBuffer();
      images.push(await sharp({ create: { width: 64, height: 64, channels: 4, background: '#00000000' } })
        .composite([{ input: image, left, top }]).png().toBuffer().then(b => sharp(b).resize(128, 128, { kernel: 'nearest' }).png().toBuffer()));
    }
    json(path.join(source, 'registration.json'), { reference: path.relative(root, reference).replaceAll('\\', '/'),
      referenceSha256: hash(fs.readFileSync(reference)), sharedScale: scale, sharedShift,
      baselinePx: baseline * 2, standingReferenceHeightPx: refBounds.height,
      standingOriginalHeightPx: sizes[0].h * 2, canvas: [128, 128], logicalGrid: [64, 64],
      partTransforms: false, interpolation: 'none', generationTool: 'built-in image_gen' });
    for (const [a, action] of ['hurt', 'defeat'].entries()) {
      const folder = path.join(out, spec.female ? 'players_female' : 'players', spec.id, action);
      for (const sub of ['keyframes', 'frames_24fps', 'preview']) fs.mkdirSync(path.join(folder, sub), { recursive: true });
      const keys = images.slice(a * 4, a * 4 + 4);
      const holds = action === 'hurt' ? [1, 2, 3, 6] : [4, 6, 8, 12];
      const offsets = action === 'hurt' ? [0, -4, -6, 0] : [0, -2, -4, -4];
      const heights = action === 'hurt' ? Array(4).fill(hoverOffset)
        : [hoverOffset, Math.round(hoverOffset / 2), 0, 0];
      const timeline = [];
      const keyframes = [];
      for (let i = 0; i < keys.length; i++) {
        const file = `keyframes/frame_${String(i).padStart(3, '0')}.png`;
        fs.writeFileSync(path.join(folder, file), keys[i]);
        keyframes.push({ index: i, file, rgba_sha256: hash(await sharp(keys[i]).ensureAlpha().raw().toBuffer()) });
        for (let h = 0; h < holds[i]; h++) {
          const tick = timeline.length, frameFile = `frames_24fps/frame_${String(tick).padStart(3, '0')}.png`;
          fs.writeFileSync(path.join(folder, frameFile), keys[i]);
          timeline.push({ tick, keyframe: i, root_offset_px: [offsets[i], heights[i]], file: frameFile });
          assert.equal(hash(await sharp(path.join(folder, frameFile)).ensureAlpha().raw().toBuffer()), keyframes[i].rgba_sha256);
        }
      }
      const events = action === 'hurt'
        ? [{ event: 'damage_reaction', tick: 0, keyframe: 0 }, { event: 'recovered', tick: 11, keyframe: 3 }]
        : [{ event: 'defeat_begin', tick: 0, keyframe: 0 }, { event: 'kneel_ground_contact', tick: 10, keyframe: 2 }, { event: 'defeat_pose_hold', tick: 18, keyframe: 3 }];
      const meta = { asset: spec.id, action, render_mode: 'original_pixel_keyframes', canvas: [128, 128], fps: 24,
        direction: 'right', interpolation: 'none', part_transforms: false, crossfade: false,
        loop_in_game: false, hold_last_frame: action === 'defeat', duration_seconds: timeline.length / 24,
        sprite_anchor_px: anchor, root_motion_space: 'world_px_absolute_offset', keyframes,
        holds: holds.map((ticks, keyframe) => ({ keyframe, ticks, root_offset_px: [offsets[keyframe], heights[keyframe]] })), events, timeline };
      json(path.join(folder, 'animation.json'), meta);
      const rawKeys = await Promise.all(keys.map(b => sharp(b).ensureAlpha().raw().toBuffer()));
      await sharp(Buffer.concat(rawKeys), { raw: { width: 128, height: 512, channels: 4, pageHeight: 128 } })
        .gif({ loop: 0, delay: holds.map((ticks, i) => Math.round(ticks * 1000 / 24) + (action === 'defeat' && i === 3 ? 1200 : 0)) })
        .toFile(path.join(folder, 'preview/animation.gif'));
      await sharp({ create: { width: 512, height: 128, channels: 4, background: '#00000000' } })
        .composite(keys.map((input, i) => ({ input, left: i * 128, top: 0 }))).png().toFile(path.join(folder, 'sprite_sheet.png'));
      const name = spec.id + '_' + action;
      json(path.join(runtime, name + '.json'), meta);
      if (!manifest.motions.includes(name)) manifest.motions.push(name);
      for (let i = 0; i < keys.length; i++) {
        const file = name + '_' + String(i).padStart(3, '0') + '.png';
        fs.writeFileSync(path.join(runtime, file), keys[i]);
        const entry = { file, source: `FocusQuest_player_reactions_v017/${spec.female ? 'players_female' : 'players'}/${spec.id}/${action}/${keyframes[i].file}`,
          sha256: hash(keys[i]), rgba_sha256: keyframes[i].rgba_sha256 };
        const existing = manifest.files.findIndex(f => f.file === file);
        if (existing === -1) manifest.files.push(entry); else manifest.files[existing] = entry;
      }
      checks.push({ character: spec.id, role: spec.role, female: spec.female, action, keyframes: 4,
        ticks: timeline.length, framePixelEquality: true, canvas: [128, 128],
        finalPoseVisible: true, holdLastFrame: meta.hold_last_frame });
    }
    console.log(spec.id + ': hurt + kneeling defeat packaged');
  }
  for (const [file, digest] of previous) assert.equal(hash(fs.readFileSync(path.join(runtime, file))), digest, file + ' altered');
  manifest.player_reactions_source = 'FocusQuest_player_reactions_v017';
  json(path.join(runtime, 'manifest.json'), manifest);
  json(path.join(out, 'verification.json'), { characterCount: inputs.length, motions: checks.length,
    originalCount: checks.length * 4, timelineFrameCount: checks.reduce((n, c) => n + c.ticks, 0),
    previousRuntimeAssetsPreserved: previous.size, checks });
  const cards = inputs.map(s => {
    const actor = `${s.female ? 'players_female' : 'players'}/${s.id}`;
    return `<article><h2>${s.role}・${s.female ? '女性' : '男性'}</h2>` + ['hurt', 'defeat'].map(action =>
      `<section><h3>${action === 'hurt' ? '被弾' : '膝をつく敗北'}</h3><img src="${actor}/${action}/preview/animation.gif"><p><a href="${actor}/${action}/sprite_sheet.png">原画一覧</a> · <a href="${actor}/${action}/animation.json">再生JSON</a></p></section>`).join('') + '</article>';
  }).join('');
  fs.writeFileSync(path.join(out, 'index.html'), `<!doctype html><meta charset="utf-8"><title>FocusQuest 被弾と敗北 v017</title><style>body{background:#142235;color:#fff;font-family:sans-serif}main{display:flex;flex-wrap:wrap;gap:24px}article{width:280px}img{width:256px;image-rendering:pixelated}a{color:#fbd580}</style><h1>男女16職業・被弾と膝をつく敗北 v017</h1><p>128px透過・64px論理格子・24fps原画保持。敗北の最後はゲーム内で保持します。</p><main>${cards}</main>`);
}
main().catch(e => { console.error(e); process.exitCode = 1; });
