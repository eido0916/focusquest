const fs=require('node:fs/promises'),sync=require('node:fs'),cp=require('node:child_process');
const root="C:/Users/eido0/OneDrive/ドキュメント/ChatGPT/Focus Quest",art=root+'/art/job_reveal_v001';
const dart='C:/src/flutter/bin/cache/dart-sdk/bin/dart.exe',flutter='C:/src/flutter/bin/cache/flutter_tools.snapshot';
const env={...process.env,PATH:'C:\\src\\flutter\\bin;C:\\Windows\\System32;C:\\Windows;C:\\Users\\eido0\\AppData\\Local\\FocusQuestTools\\java\\jdk-17.0.20.1+1\\bin;C:\\Users\\eido0\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\native\\git\\cmd',PATHEXT:'.COM;.EXE;.BAT;.CMD',SystemRoot:'C:\\Windows',USERPROFILE:'C:\\Users\\eido0',LOCALAPPDATA:'C:\\Users\\eido0\\AppData\\Local',APPDATA:'C:\\Users\\eido0\\AppData\\Roaming',TEMP:'C:\\Users\\eido0\\AppData\\Local\\Temp',TMP:'C:\\Users\\eido0\\AppData\\Local\\Temp',JAVA_HOME:'C:\\Users\\eido0\\AppData\\Local\\FocusQuestTools\\java\\jdk-17.0.20.1+1',ANDROID_HOME:'C:\\Users\\eido0\\AppData\\Local\\FocusQuestTools\\android-sdk'};
async function run(name,args,cwd){await fs.rm(art+'/'+name+'.exit',{force:true});const fd=sync.openSync(art+'/'+name+'.log','w');const p=cp.spawn(dart,[flutter,...args],{cwd,env,windowsHide:true,stdio:['ignore',fd,fd]});await fs.writeFile(art+'/'+name+'.pid',String(p.pid));const code=await new Promise((res,rej)=>{p.on('error',rej);p.on('close',res)});sync.closeSync(fd);await fs.writeFile(art+'/'+name+'.exit',String(code));if(code!==0)throw Error(name+' failed: '+code);}
(async()=>{
if(process.argv.includes('--resume-android')) {
const stage=(await fs.readFile(art+'/android-workspace.txt','utf8')).trim();
await fs.writeFile(art+'/continue-build.phase','arm64 APK再ビルド');
await run('android-build',['build','apk','--debug','--target-platform','android-arm64','--no-pub'],stage);
const apk=root+'/output/android/FocusQuest-job-reveal-v001-debug.apk';
await fs.link(stage+'/build/app/outputs/flutter-apk/app-debug.apk',apk);
await fs.writeFile(art+'/continue-build.done',apk);return;
}

const qa=(await fs.readFile(art+'/qa-workspace.txt','utf8')).trim()+'/mobile';
for(const f of ['job_reveal_all_roles_test.dart','job_reveal_test.dart'])await fs.copyFile(root+'/mobile/test/'+f,qa+'/test/'+f);
await fs.writeFile(art+'/continue-build.phase','全職業プレビュー確認');
await run('all-roles-test',['test','--no-pub','--concurrency=1','--dart-define=CAPTURE_JOB_REVEAL=true','--dart-define=JOB_REVEAL_OUTPUT='+art+'/previews/all_roles','--dart-define=QA_FONT='+root+'/mobile/assets/fonts/NotoSerifJP.ttf','test/job_reveal_all_roles_test.dart'],qa);
await fs.writeFile(art+'/continue-build.phase','Androidビルド用フォルダー準備');
await fs.rm(qa+'/build',{recursive:true,force:true});
const stage='C:/Users/eido0/AppData/Local/FocusQuestTools/build/job-reveal-android-'+Date.now();await fs.mkdir(stage,{recursive:true});await fs.writeFile(art+'/android-workspace.txt',stage);
await fs.cp(root+'/mobile/lib',stage+'/lib',{recursive:true});
await fs.cp(root+'/mobile/android',stage+'/android',{recursive:true,filter:p=>!p.includes('/.gradle')&&!p.includes('\\.gradle')&&!p.endsWith('local.properties')});
for(const f of ['pubspec.yaml','pubspec.lock','analysis_options.yaml'])await fs.copyFile(root+'/mobile/'+f,stage+'/'+f);
await fs.symlink(root+'/mobile/assets',stage+'/assets','junction');
await fs.writeFile(art+'/continue-build.phase','Android依存関係解決');
await run('android-pub',['pub','get','--offline'],stage);
await fs.writeFile(art+'/continue-build.phase','APKビルド');
await run('android-build',['build','apk','--debug','--target-platform','android-arm64','--no-pub'],stage);
const apk=root+'/output/android/FocusQuest-job-reveal-v001-debug.apk';await fs.copyFile(stage+'/build/app/outputs/flutter-apk/app-debug.apk',apk);await fs.writeFile(art+'/continue-build.done',apk);
})().catch(async err=>{await fs.writeFile(art+'/continue-build.error',err.stack);process.exitCode=1;});
