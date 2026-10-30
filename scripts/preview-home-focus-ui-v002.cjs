const path = require('path');
const fs = require('fs');
const sharp = require('C:/Users/eido0/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '../art/home_focus_ui_v002');
(async () => {
  const previews = path.join(root, 'previews');
  const pages = await Promise.all(['home', 'timer'].map(async name => ({
    input: await sharp(path.join(previews, `${name}-390x844-1.png`)).resize(390, 844).png().toBuffer(),
    left: name === 'home' ? 20 : 430, top: 20,
  })));
  await sharp({create: {width: 840, height: 884, channels: 4, background: '#0a2037'}})
    .composite(pages).png().toFile(path.join(previews, 'implemented-screens.png'));
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'));
  console.log(`Saved implemented-screens.png; manifest has ${Array.isArray(manifest) ? manifest.length : Object.keys(manifest).length} entries`);
})();
