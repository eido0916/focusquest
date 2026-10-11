// Package generated, independently drawn boss poses; never synthesize poses.
// Usage: NODE_PATH=<bundled node_modules> node scripts/package-boss-resolution.cjs inputs.json
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const assert = require('assert');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'art/workspace_materials/FocusQuest_pixel_keyframes_v014');
const old = path.join(root, 'art/workspace_materials/FocusQuest_pixel_keyframes_v013');
const runtime = path.join(root, 'mobile/assets/images/playable_stage');
const inputs = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const actions = ['walk', 'attack', 'hurt', 'defeat'];
const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const writeJson = (p, value) => fs.writeFileSync(p, JSON.stringify(value, null, 2) + '\n');
const copySource = (source, dest) => {
  const absolute = path.resolve(root, source);
  if (absolute !== path.resolve(dest)) fs.copyFileSync(absolute, dest);
};
const checks = [];
const manifest = JSON.parse(fs.readFileSync(path.join(runtime, 'manifest.json'), 'utf8'));

// Extract connected original drawings rather than truncating a weapon at a grid line.
async function cellsFromAtlas(file, cols, rows) {
  const { data, info } = await sharp(file).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  assert.equal(info.channels, 4);
  assert.equal(data[3], 0, 'Atlas background must be transparent: ' + file);
  const runs = [], parents = [];
  let previous = [];
  const find = i => {
    while (parents[i] !== i) { parents[i] = parents[parents[i]]; i = parents[i]; }
    return i;
  };
  for (let y = 0; y < info.height; y++) {
    const current = [];
    for (let x = 0; x < info.width;) {
      if (data[(y * info.width + x) * 4 + 3] < 128) { x++; continue; }
      const start = x;
      while (x < info.width && data[(y * info.width + x) * 4 + 3] >= 128) x++;
      const i = runs.length;
      runs.push({ y, l: start, r: x }); parents.push(i); current.push(i);
      for (const p of previous) {
        if (runs[p].r < start) continue;
        if (runs[p].l > x) break;
        parents[find(i)] = find(p);
      }
    }
    previous = current;
  }
  const components = new Map();
  runs.forEach((r, i) => {
    const k = find(i);
    if (!components.has(k)) components.set(k, []);
    components.get(k).push(r);
  });
  const groups = Array.from({ length: cols * rows }, () => []);
  const cw = info.width / cols, ch = info.height / rows;
  for (const rr of components.values()) {
    const area = rr.reduce((n, r) => n + r.r - r.l, 0);
    if (area < 3) continue;
    const cx = rr.reduce((n, r) => n + (r.l + r.r - 1) / 2 * (r.r - r.l), 0) / area;
    const cy = rr.reduce((n, r) => n + r.y * (r.r - r.l), 0) / area;
    const col = Math.max(0, Math.min(cols - 1, Math.floor(cx / cw)));
    const row = Math.max(0, Math.min(rows - 1, Math.round(cy / ch - .55)));
    groups[row * cols + col].push(...rr);
  }
  return groups.map((rr, i) => {
    assert(rr.length, `Empty original pose ${file} cell ${i}`);
    const l = Math.min(...rr.map(r => r.l)), r = Math.max(...rr.map(r => r.r));
    const t = Math.min(...rr.map(r => r.y)), b = Math.max(...rr.map(r => r.y)) + 1;
    const pixels = Buffer.alloc((r - l) * (b - t) * 4);
    rr.forEach(run => {
      for (let x = run.l; x < run.r; x++) {
        const j = ((run.y - t) * (r - l) + x - l) * 4;
        data.copy(pixels, j, (run.y * info.width + x) * 4, (run.y * info.width + x) * 4 + 4);
        pixels[j + 3] = 255;
      }
    });
    // Normalize dimensions for shared registration across separately generated atlases.
    return { pixels, width: r - l, height: b - t,
      relativeLeft: (l - Math.round(i % cols * cw)) / cw,
      normalizedWidth: (r - l) / cw, normalizedHeight: (b - t) / cw };
  });
}

async function main() {
  fs.mkdirSync(path.join(out, 'source'), { recursive: true });
  for (const spec of inputs) {
    const sourceDir = path.join(out, 'source', spec.id);
    fs.mkdirSync(sourceDir, { recursive: true });
    let poses;
    const sourceAssets = [];
    if (spec.actions) {
      poses = [];
      for (const action of actions) {
        const dest = path.join(sourceDir, action + '_atlas.png');
        copySource(spec.actions[action], dest);
        poses.push(...await cellsFromAtlas(dest, 4, 2));
        sourceAssets.push({ action, file: path.relative(out, dest).replaceAll('\\', '/') });
      }
    } else {
      const dest = path.join(sourceDir, 'original_atlas.png');
      copySource(spec.path, dest);
      poses = await cellsFromAtlas(dest, spec.columns, spec.rows);
      sourceAssets.push({ file: path.relative(out, dest).replaceAll('\\', '/') });
    }
    const count = poses.length / 4;
    assert([4, 8].includes(count));
    for (const [action, override] of Object.entries(spec.overrides || {})) {
      const dest = path.join(sourceDir, action + '_atlas.png');
      copySource(override.path, dest);
      const replacement = await cellsFromAtlas(dest, override.columns, override.rows);
      assert.equal(replacement.length, count);
      const factor = poses[0].normalizedHeight / replacement[0].normalizedHeight;
      for (const p of replacement) {
        p.relativeLeft = .5 + (p.relativeLeft - .5) * factor;
        p.normalizedWidth *= factor;
        p.normalizedHeight *= factor;
      }
      poses.splice(actions.indexOf(action) * count, count, ...replacement);
      sourceAssets.push({ action, file: path.relative(out, dest).replaceAll('\\', '/'), registrationFactor: factor });
    }
    const minLeft = Math.min(...poses.map(p => p.relativeLeft));
    const maxRight = Math.max(...poses.map(p => p.relativeLeft + p.normalizedWidth));
    const maxHeight = Math.max(...poses.map(p => p.normalizedHeight));
    // 192 logical pixels (previously 64), doubled to a 384px PNG.
    // All actions use one scale, and the original 120/128 foot anchor stays fixed.
    const scale = Math.min(168 / (maxRight - minLeft), 168 / maxHeight);
    const xOrigin = (192 - (maxRight - minLeft) * scale) / 2;
    const keys = [];
    for (const p of poses) {
      const w = Math.max(1, Math.round(p.normalizedWidth * scale));
      const h = Math.max(1, Math.round(p.normalizedHeight * scale));
      const l = Math.round(xOrigin + (p.relativeLeft - minLeft) * scale);
      const t = 180 - h;
      assert(l >= 1 && t >= 1 && l + w < 192);
      const image = await sharp(p.pixels, { raw: { width: p.width, height: p.height, channels: 4 } })
        .resize(w, h, { kernel: 'nearest' }).png().toBuffer();
      keys.push(await sharp({ create: { width: 192, height: 192, channels: 4, background: '#00000000' } })
        .composite([{ input: image, left: l, top: t }]).png().toBuffer().then(b =>
          sharp(b).resize(384, 384, { kernel: 'nearest' }).png().toBuffer()));
    }
    writeJson(path.join(sourceDir, 'production.json'), {
      tool: 'built-in image_gen', sourceAssets, canvas: [384, 384], logicalGrid: [192, 192],
      previousCanvas: [128, 128], resolutionMultiplier: 3, drawnDetail: true,
      registration: { sharedScale: scale, xOrigin, minLeft, footBaseline: 360 },
      constraints: 'Preserve left facing identity, palette, pose order and animation timing; add fine pixel details; no intermediate poses or deformation.',
    });
    for (let a = 0; a < actions.length; a++) {
      const action = actions[a], folder = path.join(out, 'enemies', spec.id, action);
      for (const sub of ['keyframes', 'frames_24fps', 'preview']) fs.mkdirSync(path.join(folder, sub), { recursive: true });
      const meta = JSON.parse(fs.readFileSync(path.join(old, 'enemies', spec.id, action, 'animation.json'), 'utf8'));
      const images = keys.slice(a * count, (a + 1) * count);
      if (action === 'defeat') images.push(await sharp({ create: { width: 384, height: 384, channels: 4, background: '#00000000' } }).png().toBuffer());
      assert.equal(images.length, meta.keyframes.length);
      meta.canvas = [384, 384];
      meta.coordinate_canvas = [128, 128]; // World offsets and foot anchors retain original units.
      meta.production = 'New detailed image_gen original poses, 192px logical grid, nearest-neighbor 2x export; no synthesized intermediate poses.';
      for (let i = 0; i < images.length; i++) {
        const raw = await sharp(images[i]).ensureAlpha().raw().toBuffer();
        assert.equal(raw.length, 384 * 384 * 4);
        meta.keyframes[i].rgba_sha256 = digest(raw);
        fs.writeFileSync(path.join(folder, meta.keyframes[i].file), images[i]);
      }
      for (const row of meta.timeline) {
        const data = images[row.keyframe];
        fs.writeFileSync(path.join(folder, row.file), data);
        assert.equal(digest(await sharp(path.join(folder, row.file)).raw().toBuffer()), meta.keyframes[row.keyframe].rgba_sha256);
      }
      writeJson(path.join(folder, 'animation.json'), meta);
      const frames = await Promise.all(images.map(b => sharp(b).raw().toBuffer()));
      const animated = await sharp(Buffer.concat(frames), { raw: { width: 384, height: 384 * frames.length, channels: 4, pageHeight: 384 } })
        .gif({ loop: meta.loop_in_game ? 0 : 1, delay: images.map((_, i) => Math.round(meta.holds.filter(h => h.keyframe === i).reduce((n, h) => n + h.ticks, 0) * 1000 / 24)) }).toBuffer();
      fs.writeFileSync(path.join(folder, 'preview/animation.gif'), animated);
      const cols = 4, rows = Math.ceil(images.length / cols);
      await sharp({ create: { width: 384 * cols, height: 384 * rows, channels: 4, background: '#00000000' } })
        .composite(images.map((input, i) => ({ input, left: (i % cols) * 384, top: Math.floor(i / cols) * 384 })))
        .png().toFile(path.join(folder, 'sprite_sheet.png'));
      if (action !== 'hurt') {
        const name = spec.id + '_' + (action === 'walk' ? 'locomotion' : action);
        writeJson(path.join(runtime, name + '.json'), meta);
        for (let i = 0; i < images.length; i++) {
          const file = name + '_' + String(i).padStart(3, '0') + '.png';
          fs.writeFileSync(path.join(runtime, file), images[i]);
          const entry = manifest.files.find(f => f.file === file);
          assert(entry, file);
          entry.source = `FocusQuest_pixel_keyframes_v014/enemies/${spec.id}/${action}/${meta.keyframes[i].file}`;
          entry.sha256 = digest(images[i]); entry.rgba_sha256 = meta.keyframes[i].rgba_sha256;
        }
      }
      checks.push({ boss: spec.id, action, keyframes: images.length, timelineFrames: meta.timeline.length, canvas: meta.canvas, framePixelEquality: true, originalTimingAndWorldOffsets: true });
    }
    console.log(spec.id + ': 384px all four actions packaged');
  }
  manifest.boss_source = 'FocusQuest_pixel_keyframes_v014';
  writeJson(path.join(runtime, 'manifest.json'), manifest);
  writeJson(path.join(out, 'verification.json'), { bossCount: inputs.length, animationCount: checks.length, checks });
  const cards = checks.map(c => {
    const folder = `enemies/${c.boss}/${c.action}`;
    return `<article><h2>${c.boss} · ${c.action}</h2><img src="${folder}/preview/animation.gif"><p>${c.keyframes}原画・384×384px・24fps</p><a href="${folder}/sprite_sheet.png">原画一覧</a> · <a href="${folder}/animation.json">再生JSON</a></article>`;
  }).join('');
  fs.writeFileSync(path.join(out, 'index.html'), `<!doctype html><meta charset="utf-8"><title>FocusQuest ボス高精細原画 v014</title><style>body{background:#142235;color:#fff;font-family:sans-serif}main{display:flex;flex-wrap:wrap;gap:16px}article{width:400px}img{image-rendering:pixelated;width:384px}a{color:#fbd580}</style><h1>ボス9体・高精細原画 v014</h1><p>128→384px、論理格子64→192px。各姿勢を描き直し、原画保持の24fpsで再生。以前の素材を保持。</p><main>${cards}</main>`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
