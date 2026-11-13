#!/usr/bin/env node
/*! Horus SDK 0.21.1 | (c) Horus Entertainment */
var qt=Object.defineProperty;var M=(t,o)=>()=>(t&&(o=t(t=0)),o);var te=(t,o)=>{for(var n in o)qt(t,n,{get:o[n],enumerable:!0})};import yt from"node:zlib";function ne(t){let o=4294967295;for(let n=0;n<t.length;n++)o=ee[(o^t[n])&255]^o>>>8;return(o^4294967295)>>>0}function kt(t,o=null){let n=-1;for(let s=t.length-22;s>=Math.max(0,t.length-65557);s--)if(t.readUInt32LE(s)===101010256){n=s;break}if(n<0)throw new Error("not a zip file (no end of central directory)");let r=t.readUInt16LE(n+10),e=t.readUInt32LE(n+16),i=new Map;for(let s=0;s<r;s++){if(t.readUInt32LE(e)!==33639248)throw new Error("bad central directory");let c=t.readUInt16LE(e+10),d=t.readUInt32LE(e+20),a=t.readUInt16LE(e+28),f=t.readUInt16LE(e+30),u=t.readUInt16LE(e+32),p=t.readUInt32LE(e+42),h=t.toString("utf8",e+46,e+46+a);if(e+=46+a+f+u,h.endsWith("/")||o&&!o(h))continue;let k=p+30+t.readUInt16LE(p+26)+t.readUInt16LE(p+28),x=t.subarray(k,k+d);if(c===0)i.set(h,Buffer.from(x));else if(c===8)i.set(h,yt.inflateRawSync(x));else throw new Error(`${h}: compression method ${c} not supported`)}return i}function vt(t){let o=[],n=[],r=0;for(let[s,c]of t){let d=Buffer.from(s,"utf8"),a=yt.deflateRawSync(c,{level:9}),f=ne(c),u=Buffer.alloc(30);u.writeUInt32LE(67324752,0),u.writeUInt16LE(20,4),u.writeUInt16LE(2048,6),u.writeUInt16LE(8,8),u.writeUInt16LE(0,10),u.writeUInt16LE(22561,12),u.writeUInt32LE(f,14),u.writeUInt32LE(a.length,18),u.writeUInt32LE(c.length,22),u.writeUInt16LE(d.length,26),u.writeUInt16LE(0,28);let p=Buffer.alloc(46);p.writeUInt32LE(33639248,0),p.writeUInt16LE(20,4),p.writeUInt16LE(20,6),p.writeUInt16LE(2048,8),p.writeUInt16LE(8,10),p.writeUInt16LE(0,12),p.writeUInt16LE(22561,14),p.writeUInt32LE(f,16),p.writeUInt32LE(a.length,20),p.writeUInt32LE(c.length,24),p.writeUInt16LE(d.length,28),p.writeUInt32LE(r,42),o.push(u,d,a),n.push(p,d),r+=30+d.length+a.length}let e=Buffer.concat(n),i=Buffer.alloc(22);return i.writeUInt32LE(101010256,0),i.writeUInt16LE(t.length,8),i.writeUInt16LE(t.length,10),i.writeUInt32LE(e.length,12),i.writeUInt32LE(r,16),Buffer.concat([...o,e,i])}var ee,rt=M(()=>{ee=new Uint32Array(256).map((t,o)=>{let n=o;for(let r=0;r<8;r++)n=n&1?3988292384^n>>>1:n>>>1;return n>>>0})});import F from"node:fs";import $t from"node:os";import U from"node:path";import{spawnSync as oe}from"node:child_process";function Z({env:t=process.env,dir:o=$t.homedir()}={}){if(t.WEBGAME_BUILD_KEY)return String(t.WEBGAME_BUILD_KEY).trim();try{return F.readFileSync(Q(o),"utf8").trim()}catch{return""}}function tt(t,{dir:o=$t.homedir()}={}){if(t=String(t||"").trim(),!/^[\x21-\x7e]{16,200}$/.test(t))throw Object.assign(new Error("build key: 16 to 200 characters, no spaces"),{status:400});return F.mkdirSync(U.dirname(Q(o)),{recursive:!0}),F.writeFileSync(Q(o),`${t}
`,{mode:384}),Q(o)}async function Y(t,o,n,{method:r="GET",body:e,headers:i={},fetchImpl:s=fetch}={}){let c;try{c=await s(`${t.replace(/\/+$/,"")}${n}`,{method:r,body:e,headers:{authorization:`Bearer ${o}`,...i}})}catch(d){throw Object.assign(new Error(`${n}: ${d.cause?.code||d.message} (no internet, or the build server address is wrong)`),{network:!0})}if(c.status===401)throw new Error("the build server refused the build key: ask Horus for the current one");if(c.status===403)throw new Error(`${n}: ${(await c.json().catch(()=>({}))).error||"not allowed with this key"}`);return c}async function St(t,o,{fetchImpl:n=fetch}={}){let r=await Y(t,o,"/sdk",{fetchImpl:n});if(r.status===404)return null;if(!r.ok)throw new Error(`/sdk: HTTP ${r.status}`);return G(r)}async function Et(t,o,n,{fetchImpl:r=fetch}={}){let e=await Y(t,o,`/sdk/${n.file}`,{fetchImpl:r});if(!e.ok)throw new Error(`/sdk/${n.file}: HTTP ${e.status}`);let i=Buffer.from(await e.arrayBuffer()),{createHash:s}=await import("node:crypto");if(n.sha256&&s("sha256").update(i).digest("hex")!==n.sha256)throw new Error(`${n.file}: the download is not the file the server named (sha256)`);return i}function jt(t,o=new Set(["node_modules",".git"])){let n=[],r=e=>{for(let i of F.readdirSync(e,{withFileTypes:!0})){let s=U.join(e,i.name);i.isDirectory()?o.has(i.name)||r(s):n.push([U.relative(t,s).split(U.sep).join("/"),F.readFileSync(s)])}};return r(t),n}async function Lt(t,o,n,r,{fetchImpl:e=fetch}={}){let i=await Y(t,o,"/jobs",{method:"POST",body:n,headers:{"content-type":"application/zip","x-build-meta":Buffer.from(JSON.stringify(r),"utf8").toString("base64")},fetchImpl:e});if(!i.ok)throw new Error(`submit: ${(await G(i)).error||`HTTP ${i.status}`}`);return(await G(i)).id}async function ie(t,o,n,{fetchImpl:r=fetch}={}){let e=await Y(t,o,`/jobs/${n}`,{fetchImpl:r});if(!e.ok)throw new Error(`job ${n}: ${(await G(e)).error||`HTTP ${e.status}`}`);return G(e)}async function V(t,o,n,{fetchImpl:r=fetch}={}){let e=await Y(t,o,`/jobs/${n}/cancel`,{method:"POST",fetchImpl:r}),i=await G(e);if(!e.ok&&e.status!==409)throw new Error(`stop ${n}: ${i.error||`HTTP ${e.status}`}`);return{status:i.status}}async function se(t,o,n,{fetchImpl:r=fetch,interval:e=4e3,timeout:i=30*6e4,offline:s=15*6e4,onState:c=()=>{},onProgress:d=()=>{},onOffline:a=()=>{},signal:f,onCancel:u=()=>{},now:p=Date.now}={}){let h=p(),k="",x="",y="",$=!1,E=0;for(;;){let S;try{f?.aborted&&!$&&(u(await V(t,o,n,{fetchImpl:r})),$=!0),S=await ie(t,o,n,{fetchImpl:r})}catch(O){if(!O.network)throw O;if(E||(E=p(),a(O,!0)),p()-E>s)throw new Error(`${O.message}; no answer for ${s/6e4|0} minutes (the job may still run: follow it again by its id)`);await xt(Math.min(e*2,15e3));continue}E&&(E=0,a(null,!1)),S.status!==k&&(k=S.status,h=p(),c(S));let I=S.progress?JSON.stringify([S.progress.step,S.progress.steps,S.progress.what,S.progress.pct,S.progress.detail]):"";if(S.progress?.at&&S.progress.at!==y&&(y=S.progress.at,h=p()),I&&I!==x&&(x=I,d(S.progress,S)),re.has(S.status))return S;if(p()-h>i)throw new Error(`job ${n}: still ${S.status} after ${i/6e4|0} minutes`);await xt(f?.aborted?Math.min(e,1e3):e)}}function ae(t,o=null,{offset:n=1,after:r=1}={}){if(!t?.steps)return[];let e=[],i=n+t.steps+r,s=n+(t.step||1);return(!o||o.step!==t.step||o.steps!==t.steps)&&e.push(`== [${s}/${i}] ${t.what||"build"} (Horus build PC)`),t.pct!=null&&(!o||o.pct!==t.pct||o.step!==t.step)&&e.push(`   ${t.what||"build"}: ${t.pct}%`),t.detail&&(!o||o.detail!==t.detail)&&e.push(`   ${t.detail}`),e}function Ot(t,o="en"){let n=t?.uploaded,r=o==="vi";return n?n.play?`Google Play ${n.play.track||"internal"}: versionCode ${n.play.versionCode}${n.play.status==="draft"?r?" (bản nháp: Horus phát hành trong Play Console)":" (draft: roll it out in Play Console)":""}`:n.testflight?`TestFlight: build ${n.testflight.build}${n.testflight.version?` (${n.testflight.version})`:""}${r?", Apple xử lý xong (5 đến 30 phút) thì hiện cho tester":", Apple shows it after processing (5 to 30 minutes)"}`:"":""}async function It(t,o,n,r,{fetchImpl:e=fetch}={}){let i=await Y(t,o,`/jobs/${n}/out.zip`,{fetchImpl:e});if(!i.ok)throw new Error(`result of ${n}: ${(await G(i)).error||`HTTP ${i.status}`}`);let s=Buffer.from(await i.arrayBuffer());return F.mkdirSync(U.dirname(U.resolve(r)),{recursive:!0}),F.writeFileSync(r,s),s}async function Tt(t,o,n,{log:r=console.log,interval:e=4e3,fetchImpl:i=fetch,words:s=it,signal:c,sigint:d=!0}={}){let a=new AbortController,f=()=>{if(a.signal.aborted){d&&process.exit(130);return}r(`
${s.stopping}`),a.abort()};c?.addEventListener("abort",f,{once:!0}),d&&process.on("SIGINT",f);let u=null;try{let p=await se(t,o,n,{fetchImpl:i,interval:e,signal:a.signal,onState:h=>{(h.status!=="building"||!h.progress)&&r(`  ${s[h.status]||h.status}`)},onProgress:h=>{for(let k of ae(h,u))r(k);u=h},onOffline:(h,k)=>r(k?`  ${s.offline||it.offline}: ${h.message.split(" (")[0]}`:`  ${s.online||it.online}`)});if(p.status==="cancelled")throw Object.assign(new Error(s.cancelled),{job:p,cancelled:!0});if(p.status==="failed")throw Object.assign(new Error(`${s.failed}:
${p.error||"(no log)"}`),{job:p});return p}finally{c?.removeEventListener("abort",f),d&&process.removeListener("SIGINT",f)}}function At(t,{repo:o="",run:n=oe}={}){let r=(...d)=>{let a=n("git",["-C",t,...d],{encoding:"utf8",windowsHide:!0});return a.status===0?String(a.stdout||"").trim():""},e=r("rev-parse","--show-toplevel"),s=(String(o||"").trim()||(e?r("remote","get-url","origin"):"")).replace(/^(https?:\/\/)[^/@\s]*@/i,"$1"),c=e?U.relative(U.resolve(e),U.resolve(t)).split(U.sep).join("/"):"";return{repo:s,branch:e?r("rev-parse","--abbrev-ref","HEAD"):"",commit:e?r("rev-parse","HEAD"):"",dirty:e?r("status","--porcelain").length>0:!1,dir:c.startsWith("..")?"":c}}var q,Q,re,xt,G,st,it,et=M(()=>{q="https://horus-build.horus-production.workers.dev",Q=t=>U.join(t,".webgame","build-key"),re=new Set(["done","failed","cancelled"]),xt=t=>new Promise(o=>setTimeout(o,t));G=async t=>{let o=await t.text();try{return JSON.parse(o)}catch{throw new Error(`the server did not answer with JSON (HTTP ${t.status}): ${o.slice(0,200)}`)}},st=(t,o)=>{let n=String(t).split(".").map(Number),r=String(o).split(".").map(Number);for(let e=0;e<3;e++)if((n[e]||0)!==(r[e]||0))return(n[e]||0)-(r[e]||0);return 0};it={pending:"waiting in the queue",building:"building",done:"done",failed:"failed",cancelled:"stopped",stopping:"stopping: the build PC ends the job (a half-done Play edit is deleted)",offline:"no answer from the build server, trying again (the job goes on on the build PC)",online:"connected again"}});var _,at=M(()=>{_="0.21.1"});import A from"node:fs";import L from"node:path";function Ht(t){let o=L.dirname(t);return A.existsSync(L.join(o,"horus-sdk.js"))&&A.existsSync(L.join(o,"horus-build.mjs"))?o:null}function ue(t,o,n){let r=[],e=(i,s)=>{if(s>6)return;let c=[];try{c=A.readdirSync(i,{withFileTypes:!0})}catch{return}for(let d of c){let a=L.join(i,d.name);if(d.isDirectory()){!de.has(d.name)&&L.resolve(a)!==L.resolve(o)&&e(a,s+1);continue}if(!ce.has(d.name))continue;let f=A.readFileSync(a,"utf8").slice(0,200),u=(pe.exec(f)||[])[1];u&&st(u,n)<0&&r.push(a)}};return e(t,0),r}function Ct(t,o){A.mkdirSync(L.dirname(t),{recursive:!0}),A.writeFileSync(`${t}.new`,o),A.renameSync(`${t}.new`,t)}async function lt({server:t,key:o,current:n,game:r,sdkDir:e,update:i=!0,major:s=!1,fetchImpl:c=fetch,log:d=console.log}){let a=null;try{if(a=await St(t,o,{fetchImpl:c}),!a)return{action:"none",latest:a};if(st(a.version,n)<=0)return{action:"same",latest:a};if(Number(a.version.split(".")[0])>Number(String(n).split(".")[0])&&!s)return d(`Có Horus SDK ${a.version} (đổi lớn, đang dùng ${n}): đọc CHANGELOG trên trang tài liệu rồi chạy \`node horus-sdk/horus-build.mjs update --major\``),{action:"told",latest:a};if(!i||!e)return d(`Có Horus SDK ${a.version} mới (đang dùng ${n}): chạy \`node horus-sdk/horus-build.mjs update\` để cập nhật`),{action:"told",latest:a};let u=kt(await Et(t,o,a,{fetchImpl:c})),p=le.filter(y=>u.has(`horus-sdk/${y}`));if(!p.includes("horus-sdk.js"))throw new Error(`${a.file} không có horus-sdk/horus-sdk.js`);let h=L.join(e,".old",n);A.mkdirSync(h,{recursive:!0}),A.writeFileSync(L.join(e,".old",".gitignore"),`*
`);for(let y of p)A.existsSync(L.join(e,y))&&A.copyFileSync(L.join(e,y),L.join(h,y));for(let y of p)Ct(L.join(e,y),u.get(`horus-sdk/${y}`));let k=ue(r,e,a.version);k.forEach((y,$)=>{let E=L.join(h,"copies",`${$}-${L.basename(y)}`);A.mkdirSync(L.dirname(E),{recursive:!0}),A.copyFileSync(y,E),Ct(y,u.get(`horus-sdk/${L.basename(y)}`))});let x=y=>L.relative(r,y).split(L.sep).join("/")||".";return d(`Đã cập nhật Horus SDK ${n} lên ${a.version}: ${p.length} file trong ${x(e)}/${k.length?`, và ${k.map(x).join(", ")}`:""}. Bản cũ ở ${x(h)}/. Thay đổi: CHANGELOG.md`),{action:"updated",latest:a}}catch(f){return d(`chú ý: không kiểm được bản Horus SDK mới (${f.message}): build vẫn tiếp tục`),{action:"failed",latest:a}}}var le,ce,de,pe,Ut=M(()=>{rt();et();le=["horus-sdk.js","horus-sdk.mjs","horus-logic.mjs","horus-sdk.d.ts","horus-build.mjs","HorusBuild.cmd","README.md","AGENTS.md","GAME-GUIDE.md","CHANGELOG.md"],ce=new Set(["horus-sdk.js","horus-sdk.mjs","horus-logic.mjs"]),de=new Set(["node_modules",".git",".old","build-online"]),pe=/^(?:#![^\n]*\n)?\/\*! Horus SDK (\d+\.\d+\.\d+)/});import Bt from"node:fs";import he from"node:os";import ct from"node:path";function dt({dir:t=he.homedir()}={}){try{let o=JSON.parse(Bt.readFileSync(fe(t),"utf8")).cli;return typeof o=="string"&&ct.isAbsolute(o)&&Bt.existsSync(o)?o:null}catch{return null}}function ge(t,o){let n=String(o??"").split(/[,\s]+/).map(e=>e.trim()).filter(Boolean);if(!n.length)throw N(t==="ios"?'bản store: iOS "version(build)", ví dụ 0.1.2(1)':"bản store: versionCode Android, ví dụ 21");for(let e of n)if(!me[t].test(e))throw N(t==="ios"?`bản store ${e}: iOS ghi "version(build)", ví dụ 0.1.2(1)`:`bản store ${e}: versionCode là số, ví dụ 21`);let r=[...new Set(n)];if(r.length>1)throw N(`bản store: mỗi lần phát một bản store, không phải ${r.join(", ")}: phát lần lượt cho từng bản (${r[0]}, rồi ${r[1]}...), mỗi lần một id`);return r}function Nt(t,o={},{apps:n={},web:r=""}={}){let e=String(o.platform||"");if(!_t.includes(e))throw N("nền tảng: android hoặc ios");let i=String(n[e]||"");if(!/^[A-Za-z][\w]*(\.[A-Za-z][\w]*)+$/.test(i))throw N(`chưa có app id ${e==="ios"?"iOS (ios.bundleId)":"Android (android.appId)"} của game`);let s=["--app",i,"--platform",e],c=()=>{let d=String(o.id??"").trim();if(!be.test(d))throw N("id: chữ, số, . _ - (tối đa 64), ví dụ v90.1");return d};switch(t){case"hot-status":return{title:`Cập nhật nóng: trạng thái ${e}`,args:["hot","status",...s]};case"hot-publish":{let d=c(),a=ge(e,o.builds),f=Pt(o.pct??10,1);if(!r||!ct.isAbsolute(r))throw N("chưa có thư mục bản web của game");return{title:`Cập nhật nóng: phát ${d} (${e} ${a.join(",")}, ${f}%)`,args:["hot","publish",...s,"--builds",a.join(","),"--id",d,"--pct",String(f),"--web",r,...o.buildWeb?["--build-web"]:[]]}}case"hot-rollout":{let d=c(),a=Pt(o.pct,0);return{title:`Cập nhật nóng: ${d} lên ${a}% (${e})`,args:["hot","rollout",...s,"--id",d,"--pct",String(a)]}}case"hot-withdraw":{let d=c();return{title:`Cập nhật nóng: rút lại ${d} (${e})`,args:["hot","rollout",...s,"--id",d,"--pct","0"]}}case"hot-off":return{title:`Cập nhật nóng: tắt ${e}`,args:["hot","off",...s]};case"hot-on":return{title:`Cập nhật nóng: bật ${e}`,args:["hot","on",...s]};default:throw N(`không có lệnh ${t}`)}}function Dt(t){let o={ready:!!t?.ready,server:!!t?.server,why:typeof t?.why=="string"?t.why.slice(0,300):"",platforms:{}};for(let n of _t){let r=t?.platforms?.[n];if(!r||typeof r!="object")continue;let e=r.status&&typeof r.status=="object"?{off:!!r.status.off,releases:(Array.isArray(r.status.releases)?r.status.releases:[]).slice(-20).map(i=>({id:String(i?.id??""),builds:(Array.isArray(i?.builds)?i.builds:[]).map(String),pct:Number(i?.pct)||0,at:String(i?.at??""),by:String(i?.by??""),files:Number(i?.files)||0}))}:null;o.platforms[n]={app:String(r.app||""),key:!!r.key,status:e,error:typeof r.error=="string"?r.error.slice(0,300):""}}return o}var fe,_t,be,me,N,Pt,Kt=M(()=>{fe=t=>ct.join(t,".webgame","kit.json");_t=["android","ios"],be=/^[A-Za-z0-9][\w.-]{0,63}$/,me={android:/^\d{1,10}$/,ios:/^\d+(\.\d+){0,3}\(\d{1,10}\)$/},N=t=>Object.assign(new Error(t),{status:400});Pt=(t,o)=>{let n=Number(t);if(!Number.isInteger(n)||n<o||n>100)throw N(`%: số nguyên từ ${o} đến 100`);return n}});var Ft={};te(Ft,{argsFor:()=>Mt,mergeManifest:()=>Rt,runKit:()=>bt,startUi:()=>xe});import nt from"node:fs";import we from"node:os";import K from"node:path";import ye from"node:http";import pt from"node:crypto";import{spawn as ft}from"node:child_process";function Rt(t,o={}){let n=structuredClone(t||{});for(let[r,e]of Object.entries(ke)){if(!(r in o))continue;let i=o[r];if(e==="int"){if(!(Number.isInteger(i)&&i>0&&i<21e8))throw new Error(`${r}: số nguyên lớn hơn 0`);n[r]=i;continue}if(typeof i!="string"||i.length>200||/[\0\r\n]/.test(i))throw new Error(`${r}: một dòng chữ`);if(e==="color"){if(i&&!/^#[0-9a-fA-F]{6}$/.test(i))throw new Error("background: màu dạng #rrggbb");n.colors={...n.colors||{},background:i};continue}if(r==="appId"&&i&&!/^[a-zA-Z][\w]*(\.[a-zA-Z][\w]*)+$/.test(i))throw new Error("appId: package name kiểu com.horus.tengame");if(r==="version"&&i&&!/^\d+(\.\d+){0,3}$/.test(i))throw new Error("version: kiểu 1.2.0");if(r==="orientation"&&!["portrait","landscape"].includes(i))throw new Error("orientation: portrait hoặc landscape");if((r==="web"||r==="icon")&&(K.isAbsolute(i)||i.split(/[\\/]/).includes("..")))throw new Error(`${r}: đường dẫn tương đối trong thư mục game`);n[r]=i}return n}function Mt(t={}){let o=String(t.what||"apk");return[...t.buildWeb?["--build-web"]:[],...ve(o,t)]}function ve(t,o){if(t==="apk")return[];if(t==="aab")return["--aab"];if(t==="play"){let n=String(o.track||"internal");if(!["internal","alpha","beta"].includes(n))throw new Error("track: internal, alpha hoặc beta");return["--play","--track",n]}if(t==="ios")return["--ios"];throw new Error(`không có kiểu build ${t}`)}function bt(t,o,{cwd:n,log:r=console.log,signal:e,env:i=process.env,node:s=process.execPath}={}){return new Promise(c=>{let d=process.platform==="win32",a=ft(s,[t,...o],{cwd:n,env:{...i,FORCE_COLOR:"0",NO_COLOR:"1"},windowsHide:!0,detached:!d}),f="",u=h=>{let k=(f+h.toString("utf8")).split(/\r?\n/);f=k.pop();for(let x of k)x.trim()&&r(x)};a.stdout.on("data",u),a.stderr.on("data",u);let p=()=>{if(d)ft("taskkill",["/pid",String(a.pid),"/t","/f"],{windowsHide:!0}).on("error",()=>{});else try{process.kill(-a.pid,"SIGKILL")}catch{a.kill("SIGKILL")}};e?.addEventListener("abort",p,{once:!0}),a.on("error",h=>{r(h.message),c(127)}),a.on("close",h=>{f.trim()&&r(f),e?.removeEventListener("abort",p),c(h??1)})})}async function xe({game:t=process.cwd(),port:o=0,open:n=!0,log:r=console.log,env:e=process.env,dir:i=we.homedir(),fetchImpl:s=fetch,token:c=pt.randomBytes(18).toString("base64url"),interval:d=4e3}={}){t=K.resolve(t);let a=K.join(t,"build-online","jobs.json"),f=e.HORUS_BUILD_SERVER||e.WEBGAME_BUILD_SERVER||q,u=[],p=0,h=null,k=l=>{for(let b of String(l).split(`
`))u.push({n:++p,t:b}),u.length>5e3&&u.shift()},x=()=>(ut(a)||[]).slice(0,20),y=(l,b)=>{let m=[{id:l,what:b.store==="testflight"?"ios":b.store==="play"?"play":b.output,track:b.track||"",at:new Date().toISOString()},...x().filter(v=>v.id!==l)].slice(0,20);nt.mkdirSync(K.dirname(a),{recursive:!0}),nt.writeFileSync(a,JSON.stringify(m,null,2))},$=(l,b,{hot:m=!1}={})=>{if(h&&h.status==="running")throw Object.assign(new Error("đang có một lượt chạy: chờ xong hoặc bấm Dừng"),{status:409});let v=new AbortController;h={id:pt.randomUUID(),title:l,status:"running",from:p+1,ac:v,t0:Date.now(),hot:m};let H=h;k(`
▶ ${l}`),b(v.signal).then(()=>{H.status="done",k("✔ xong")},w=>{H.status=v.signal.aborted||w.cancelled?"stopped":"failed",k(`${H.status==="stopped"?"■":"✖"} ${w.message}`)}).finally(()=>{H.ended=Date.now(),m&&O()})},E=(l,b)=>$(l,m=>wt([t,...b],{cwd:t,env:e,dir:i,fetchImpl:s,interval:d,log:k,signal:m,sigint:!1,onJob:(v,H)=>y(v,H)})),S=()=>({...process.env,...e,HOME:i,USERPROFILE:i}),I=null,O=()=>{let l=dt({dir:i});if(!l)return I=null,Promise.resolve();I={...I||{info:null},loading:!0};let b=[];return bt(l,["hot","info"],{cwd:t,env:S(),log:m=>b.push(m),signal:AbortSignal.timeout(6e4)}).then(m=>{let v=null;for(let H of b.slice().reverse())try{v=JSON.parse(H);break}catch{}I=v?{info:Dt(v),loading:!1,at:Date.now(),error:""}:{info:I?.info||null,loading:!1,at:Date.now(),error:`webgame hot info không trả lời (mã ${m})`}})};O();let X=l=>{let b=dt({dir:i}),m=I?.info;if(!b||!m?.ready)throw Object.assign(new Error(m?.why||"cập nhật nóng chỉ chạy trên máy build của Horus"),{status:400});if(!m.platforms[l.platform]?.key)throw Object.assign(new Error(`máy này không có khoá ký ${l.platform} của game`),{status:400});let v=Object.fromEntries(Object.entries(m.platforms).map(([D,J])=>[D,J.app])),H=W(t),w;try{w=mt(t,H)}catch{w=K.join(t,H.web||"dist")}let B=Nt(String(l.action||""),l,{apps:v,web:w});$(B.title,async D=>{let J=await bt(b,B.args,{cwd:t,env:S(),log:k,signal:D});if(D.aborted||J===130)throw Object.assign(new Error("đã dừng"),{cancelled:!0});if(J!==0)throw new Error(`webgame hot lỗi (mã ${J})`)},{hot:!0})},j=(l,b,m,v="application/json; charset=utf-8")=>{l.writeHead(b,{"content-type":v,"cache-control":"no-store","x-content-type-options":"nosniff","referrer-policy":"no-referrer"}),l.end(typeof m=="string"?m:JSON.stringify(m))},C=async l=>{let b=0,m=[];for await(let v of l){if(b+=v.length,b>64*1024)throw Object.assign(new Error("quá lớn"),{status:413});m.push(v)}try{return JSON.parse(Buffer.concat(m).toString("utf8")||"{}")}catch{throw Object.assign(new Error("không phải JSON"),{status:400})}},P=0,z=ye.createServer(async(l,b)=>{try{if(![`127.0.0.1:${P}`,`localhost:${P}`].includes(l.headers.host||""))return j(b,403,{error:"host"});let m=new URL(l.url,`http://${l.headers.host}`),v=m.pathname.startsWith("/api/")?l.headers["x-horus-token"]:m.searchParams.get("t");if(!(typeof v=="string"&&v.length===c.length&&pt.timingSafeEqual(Buffer.from(v),Buffer.from(c))))return j(b,403,m.pathname.startsWith("/api/")?{error:"token"}:"Mở trang bằng đường link lệnh in ra (có ?t=...).",m.pathname.startsWith("/api/")?void 0:"text/plain; charset=utf-8");if(l.method==="GET"&&m.pathname==="/")return j(b,200,$e.replace("__TOKEN__",c),"text/html; charset=utf-8");if(l.method==="GET"&&m.pathname==="/api/state"){let w=Number(m.searchParams.get("since"))||0,B=null,D="";try{B=W(t)}catch(ot){B=ut(K.join(t,"horus-game.json")),D=ot.message}let{ac:J,...Qt}=h||{};return j(b,200,{version:_,game:t,server:f,key:!!Z({env:{WEBGAME_BUILD_KEY:e.HORUS_BUILD_KEY||e.WEBGAME_BUILD_KEY},dir:i}),manifest:B,manifestError:D,run:h?Qt:null,lines:u.filter(ot=>ot.n>w),seq:p,jobs:x(),hot:I})}if(l.method==="PUT"&&m.pathname==="/api/key")return tt((await C(l)).key,{dir:i}),j(b,200,{ok:!0});if(l.method==="PUT"&&m.pathname==="/api/manifest"){let w=K.join(t,"horus-game.json"),B=Rt(ut(w)||{},await C(l));return nt.writeFileSync(w,JSON.stringify(B,null,2)+`
`),W(t),j(b,200,{ok:!0})}if(l.method==="POST"&&m.pathname==="/api/check"){let w=gt(t);return j(b,200,{files:w.files,mb:+(w.bytes/1048576).toFixed(1),web:K.relative(t,w.web)||".",warnings:w.warnings})}if(l.method==="POST"&&m.pathname==="/api/build"){let w=await C(l);return E(w.what==="play"?`${ht.play} (${w.track||"internal"})`:ht[w.what]||"Build",Mt(w)),j(b,200,{ok:!0})}if(l.method==="POST"&&m.pathname==="/api/follow"){let{id:w}=await C(l);if(!/^[\w-]{1,80}$/.test(String(w||"")))throw Object.assign(new Error("mã job"),{status:400});return E(`${ht.follow} ${w}`,["--job",w]),j(b,200,{ok:!0})}if(l.method==="POST"&&m.pathname==="/api/cancel"){let{id:w}=await C(l);if(!/^[\w-]{1,80}$/.test(String(w||"")))throw Object.assign(new Error("mã job"),{status:400});let B=Z({env:{WEBGAME_BUILD_KEY:e.HORUS_BUILD_KEY||e.WEBGAME_BUILD_KEY},dir:i});return j(b,200,await V(f,B,w,{fetchImpl:s}))}return l.method==="POST"&&m.pathname==="/api/hot"?(X(await C(l)),j(b,200,{ok:!0})):l.method==="POST"&&m.pathname==="/api/hot/refresh"?(await O(),j(b,200,{hot:I})):l.method==="POST"&&m.pathname==="/api/stop"?(h?.status==="running"&&(h.ac.abort(),k(h.hot?"■ đang dừng":"■ đang dừng: máy build của Horus kết thúc job")),j(b,200,{ok:!0})):j(b,404,{error:"không có"})}catch(m){return j(b,m.status||400,{error:m.message})}});await new Promise(l=>z.listen(o,"127.0.0.1",l)),P=z.address().port;let g=`http://127.0.0.1:${P}/?t=${c}`;if(r(`Horus build ${_}: trang build của ${t}
  ${g}
  (Ctrl+C để tắt)`),n){let[l,b]=process.platform==="win32"?["cmd",["/c","start","",g]]:process.platform==="darwin"?["open",[g]]:["xdg-open",[g]];try{ft(l,b,{stdio:"ignore",detached:!0,windowsHide:!0}).on("error",()=>{}).unref()}catch{}}return{url:g,port:P,token:c,close:()=>new Promise(l=>z.close(l)),get run(){return h},get hot(){return I},refreshHot:O}}var ut,ke,ht,$e,Gt=M(()=>{et();Kt();Wt();at();ut=t=>{try{return JSON.parse(nt.readFileSync(t,"utf8"))}catch{return null}},ke={name:"string",appId:"string",version:"string",versionCode:"int",web:"string",icon:"string",orientation:"string",background:"color"};ht={apk:"APK cài thử",aab:"AAB",play:"Lên Google Play",ios:"iOS lên TestFlight",follow:"Theo dõi job"};$e=`<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Horus Build</title>
<style>
:root { --bg:#f6f7f9; --panel:#fff; --ink:#1b1f24; --muted:#646c76; --line:#dfe3e8; --soft:#eef1f4; --accent:#2563eb; --accent-ink:#fff; --ok:#15803d; --warn:#b45309; --fail:#b91c1c; --ok-bg:#e7f6ec; --warn-bg:#fdf3e2; --fail-bg:#fdeaea; --run-bg:#e8effd; --code:#0f172a; --code-ink:#dbe4ee; color-scheme: light; }
@media (prefers-color-scheme: dark) { :root { --bg:#111418; --panel:#1a1e24; --ink:#e6e9ed; --muted:#9aa3ad; --line:#2c323a; --soft:#222831; --accent:#5b8cff; --accent-ink:#0b1020; --ok:#4ade80; --warn:#fbbf24; --fail:#f87171; --ok-bg:#16281d; --warn-bg:#2b2414; --fail-bg:#2d1717; --run-bg:#19223a; --code:#0b0e12; --code-ink:#cfd8e3; color-scheme: dark; } }
* { box-sizing: border-box; } [hidden] { display: none !important; }
body { margin: 0; background: var(--bg); color: var(--ink); font: 14px/1.45 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
header { background: var(--panel); border-bottom: 1px solid var(--line); padding: 12px 16px; display: flex; gap: 12px; align-items: baseline; flex-wrap: wrap; }
header h1 { font-size: 17px; margin: 0; } header .sub { color: var(--muted); font-size: 12.5px; overflow-wrap: anywhere; }
main { max-width: 1100px; margin: 0 auto; padding: 16px; display: grid; gap: 14px; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); }
.card { background: var(--panel); border: 1px solid var(--line); border-radius: 12px; padding: 16px; min-width: 0; }
.card.wide { grid-column: 1 / -1; }
.card h2 { font-size: 15px; margin: 0 0 4px; display: flex; gap: 8px; align-items: center; }
.about { color: var(--muted); font-size: 12.5px; margin: 0 0 10px; }
.row { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; margin: 8px 0; }
.field { display: grid; gap: 3px; margin: 8px 0; } .field > .k { font: 12px ui-monospace, Menlo, Consolas, monospace; color: var(--muted); }
.two { display: grid; grid-template-columns: 1fr 1fr; gap: 0 10px; }
input, select { width: 100%; background: var(--bg); color: var(--ink); border: 1px solid var(--line); border-radius: 8px; padding: 7px 9px; font: inherit; }
input:focus, select:focus { outline: 2px solid var(--accent); outline-offset: -1px; }
button.btn { background: var(--soft); color: var(--ink); border: 1px solid var(--line); border-radius: 8px; padding: 8px 13px; font: inherit; cursor: pointer; }
button.btn.primary { background: var(--accent); color: var(--accent-ink); border-color: var(--accent); font-weight: 600; }
button.btn.danger { color: var(--fail); } button.btn:disabled { opacity: .5; cursor: not-allowed; }
.pill { font-size: 11.5px; padding: 1px 8px; border-radius: 99px; background: var(--soft); color: var(--muted); white-space: nowrap; font-weight: 500; }
.pill.ok, .pill.done { background: var(--ok-bg); color: var(--ok); } .pill.warn, .pill.stopped { background: var(--warn-bg); color: var(--warn); }
.pill.failed { background: var(--fail-bg); color: var(--fail); } .pill.running { background: var(--run-bg); color: var(--accent); }
ul.warn { margin: 6px 0 0; padding-left: 18px; color: var(--warn); font-size: 12.5px; }
.bar { height: 8px; background: var(--soft); border-radius: 99px; overflow: hidden; margin: 8px 0 4px; } .bar > i { display: block; height: 100%; width: 0; background: var(--accent); transition: width .4s; }
.step { font-size: 13px; color: var(--muted); min-height: 1.4em; overflow-wrap: anywhere; }
pre { background: var(--code); color: var(--code-ink); border-radius: 10px; padding: 10px 12px; margin: 10px 0 0; height: 340px; overflow: auto; font: 12px/1.5 ui-monospace, Menlo, Consolas, monospace; white-space: pre-wrap; overflow-wrap: anywhere; }
table { width: 100%; border-collapse: collapse; font-size: 13px; } td { padding: 6px 4px; border-top: 1px solid var(--line); vertical-align: middle; } td.id { font-family: ui-monospace, Menlo, Consolas, monospace; font-size: 12px; overflow-wrap: anywhere; }
.hot-plat { border-top: 1px solid var(--line); padding: 8px 0 4px; } .hot-plat .head { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; font-weight: 600; } .hot-plat .head .btn { margin-left: auto; }
.hot-rel { display: grid; grid-template-columns: minmax(0, 1fr) 70px auto auto; gap: 6px; align-items: center; margin: 6px 0; font-size: 13px; } .hot-rel input { padding: 5px 7px; } .hot-rel .btn, .hot-plat .head .btn { padding: 5px 10px; font-size: 12.5px; }
code { font: 12.5px ui-monospace, Menlo, Consolas, monospace; overflow-wrap: anywhere; }
.toast { position: fixed; left: 50%; bottom: 18px; transform: translateX(-50%); background: var(--ink); color: var(--bg); padding: 8px 14px; border-radius: 8px; font-size: 13px; max-width: calc(100% - 32px); }
@media (max-width: 520px) { .two { grid-template-columns: 1fr; } main { padding: 12px 16px; } }
</style>
</head>
<body>
<header><h1>Horus Build</h1><span class="sub" id="where"></span></header>
<main>
  <section class="card">
    <h2>Mã build <span class="pill" id="key-pill"></span></h2>
    <p class="about">Mã Horus cấp cho team, lưu trên máy này (~/.webgame/build-key), không nằm trong repo.</p>
    <div class="row"><input type="password" id="key" autocomplete="new-password" placeholder="mã Horus cấp" style="flex:1;min-width:160px"><button class="btn" id="key-save">Lưu mã</button></div>
  </section>
  <section class="card">
    <h2>Game <span class="pill" id="m-pill"></span></h2>
    <p class="about">horus-game.json. Quảng cáo, mua hàng, Firebase do Horus cài trên máy build theo appId.</p>
    <div class="two">
      <label class="field"><span class="k">name</span><input id="m-name"></label>
      <label class="field"><span class="k">appId (Horus cấp)</span><input id="m-appId" placeholder="com.horus.tengame"></label>
      <label class="field"><span class="k">version</span><input id="m-version" placeholder="1.0.0"></label>
      <label class="field"><span class="k">versionCode</span><input id="m-versionCode" type="number" min="1"></label>
      <label class="field"><span class="k">web (thư mục build)</span><input id="m-web" placeholder="dist"></label>
      <label class="field"><span class="k">icon</span><input id="m-icon" placeholder="icon.png"></label>
      <label class="field"><span class="k">orientation</span><select id="m-orientation"><option>portrait</option><option>landscape</option></select></label>
      <label class="field"><span class="k">background</span><input id="m-background" placeholder="#101418"></label>
    </div>
    <div class="row"><button class="btn" id="m-save">Lưu</button><button class="btn" id="check">Kiểm tra bản web</button></div>
    <div class="step" id="check-out"></div><ul class="warn" id="check-warn"></ul>
  </section>
  <section class="card">
    <h2>Build</h2>
    <p class="about">Máy build của Horus gắn gamekit, ký app, và tuỳ chọn đưa thẳng lên store.</p>
    <label class="field" id="bw-row"><span class="k">Bản web</span><span><input type="checkbox" id="bw"> <span id="bw-text">build lại trước khi gửi</span></span></label>
    <label class="field"><span class="k">Làm gì</span><select id="what">
      <option value="apk">APK cài thử (tải về)</option>
      <option value="aab">AAB (tải về)</option>
      <option value="play">Lên Google Play (internal)</option>
      <option value="ios">iOS lên TestFlight</option>
    </select></label>
    <label class="field" id="track-row" hidden><span class="k">Track</span><select id="track"><option value="internal">internal</option><option value="alpha">alpha (nếu Horus cho)</option><option value="beta">beta (nếu Horus cho)</option></select></label>
    <p class="about" id="what-about"></p>
    <div class="row"><button class="btn primary" id="go">Gửi build</button></div>
  </section>
  <section class="card wide" id="hot-card" hidden>
    <h2>Cập nhật nóng <span class="pill" id="hot-pill"></span></h2>
    <p class="about">Bản web mới của game đến app đang cài, không qua store, từ lần mở app sau. Phát cho một phần người chơi trước, xem crash rồi mới lên 100%. Khoá ký và mã publish ở trên máy này, trang không hiện.</p>
    <p class="about" id="hot-why" hidden></p>
    <div id="hot-body">
      <div class="two">
        <div>
          <div id="hot-status"></div>
          <div class="row"><button class="btn" id="hot-refresh">Làm mới</button><span class="step" id="hot-at"></span></div>
        </div>
        <div>
          <label class="field"><span class="k">Nền tảng</span><select id="hot-platform"></select></label>
          <label class="field"><span class="k">id (build tag, mỗi bản một id mới)</span><input id="hot-id" maxlength="64" placeholder="v1.0.0"></label>
          <label class="field"><span class="k" id="hot-builds-k">Bản store nhận bản nóng</span><input id="hot-builds" placeholder="21"></label>
          <label class="field"><span class="k">% người chơi</span><input id="hot-pct" type="number" min="1" max="100" value="10"></label>
          <label class="field"><span class="k">Bản web</span><span><input type="checkbox" id="hot-bw" style="width:auto"> <span id="hot-bw-text">build lại trước khi phát</span></span></label>
          <div class="row"><button class="btn primary" id="hot-go">Phát bản nóng</button></div>
        </div>
      </div>
    </div>
  </section>
  <section class="card wide">
    <h2>Đang chạy <span class="pill" id="run-pill">chưa chạy</span></h2>
    <div class="bar"><i id="bar"></i></div>
    <div class="row" style="justify-content:space-between"><span class="step" id="step"></span><button class="btn danger" id="stop" disabled>Dừng</button></div>
    <pre id="log"></pre>
  </section>
  <section class="card wide">
    <h2>Job gần đây</h2>
    <table><tbody id="jobs"><tr><td class="about">Chưa có.</td></tr></tbody></table>
  </section>
</main>
<div class="toast" id="toast" hidden></div>
<script>
const T = '__TOKEN__';
const $ = (id) => document.getElementById(id);
const ABOUT = { apk: 'APK ký bằng khoá thử khi Horus chưa cài game cho team; tải về build-online/.', aab: 'Cần Horus đã cài game (appId) cho team.', play: 'Version code tự lấy cao hơn bản trên Play. Chỉ internal (Horus cho thêm alpha/beta); production do Horus phát hành.', ios: 'Build trên Mac của Horus, số build tự tăng, lên TestFlight (15 đến 25 phút). Cần Horus đã cài game cho iOS. Không có file tải về.' };
const WHAT = { apk: 'APK', aab: 'AAB', play: 'Google Play', ios: 'TestFlight' };
let since = 0, prog = {}, last = null, filled = false, hotFilled = false, hotLast = '', S = null;
const PLAT = { android: 'Android', ios: 'iOS' };
async function api(method, url, body) {
  const r = await fetch(url, { method, headers: { 'x-horus-token': T, ...(body ? { 'content-type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(j.error || r.status);
  return j;
}
function toast(t) { const e = $('toast'); e.textContent = t; e.hidden = false; clearTimeout(e._t); e._t = setTimeout(() => { e.hidden = true; }, 3500); }
function progressOf(line, p) {
  const s = /\\[(\\d+)\\/(\\d+)\\]\\s*(.*?)\\s*$/.exec(line);
  if (s && +s[1] <= +s[2]) return { step: +s[1], steps: +s[2], what: s[3], pct: null, detail: '' };
  const pc = /(?:^|[\\s:])(\\d{1,3})\\s?%/.exec(line);
  if (pc && +pc[1] <= 100) return { ...p, pct: +pc[1] };
  if (/^\\s{3}\\S/.test(line) && p.steps && !/:\\s/.test(line)) return { ...p, detail: line.trim() };
  return p;
}
function pill(el, cls, text) { el.className = 'pill ' + (cls || ''); el.textContent = text; }
function render(s) {
  S = s;
  $('where').textContent = s.game + ' · ' + s.server + ' · SDK ' + s.version;
  pill($('key-pill'), s.key ? 'ok' : 'warn', s.key ? 'đã lưu' : 'chưa có');
  pill($('m-pill'), s.manifestError ? 'warn' : 'ok', s.manifestError ? 'cần sửa' : 'ổn');
  if (s.manifestError) $('m-pill').title = s.manifestError;
  if (!filled && s.manifest) {
    filled = true;
    const m = s.manifest;
    for (const k of ['name', 'appId', 'version', 'versionCode', 'web', 'icon', 'orientation']) if (m[k] != null) $('m-' + k).value = m[k];
    // "build" of horus-game.json: the page runs it before it packs (on this machine), on by default
    $('bw').checked = !!m.build; $('bw').disabled = !m.build;
    $('bw-text').textContent = m.build ? 'build lại trước khi gửi: ' + m.build : 'tự build trước (thêm "build" vào horus-game.json, ví dụ "npm run build", để trang build giúp)';
    $('m-background').value = (m.colors && m.colors.background) || '';
  }
  const log = $('log'), atEnd = log.scrollTop + log.clientHeight >= log.scrollHeight - 8;
  for (const l of s.lines) { log.textContent += l.t + '\\n'; if (l.t.startsWith('▶')) prog = {}; prog = progressOf(l.t, prog); }
  if (s.lines.length && atEnd) log.scrollTop = log.scrollHeight;
  since = s.seq;
  const r = s.run, running = r && r.status === 'running';
  pill($('run-pill'), r ? r.status : '', r ? ({ running: 'đang chạy', done: 'xong', failed: 'lỗi', stopped: 'đã dừng' })[r.status] + ' · ' + r.title : 'chưa chạy');
  $('stop').disabled = !running; $('go').disabled = !!running;
  renderHot(s, !!running);
  const frac = prog.steps ? Math.min(1, (prog.step - 1 + (prog.pct || 0) / 100) / prog.steps) : 0;
  $('bar').style.width = (r && r.status === 'done' ? 100 : Math.round(frac * 100)) + '%';
  $('step').textContent = prog.steps ? '[' + prog.step + '/' + prog.steps + '] ' + prog.what + (prog.pct != null ? ' · ' + prog.pct + '%' : '') + (prog.detail ? ' · ' + prog.detail : '') + (running ? ' · ' + clock(Date.now() - r.t0) : '') : '';
  const js = JSON.stringify(s.jobs);
  if (js !== last) {
    last = js;
    $('jobs').innerHTML = s.jobs.length ? '' : '<tr><td class="about">Chưa có.</td></tr>';
    for (const j of s.jobs) {
      const tr = document.createElement('tr');
      tr.innerHTML = '<td class="id"></td><td></td><td></td><td style="text-align:right;white-space:nowrap"><button class="btn" data-f>Theo dõi / tải</button> <button class="btn danger" data-c>Dừng job</button></td>';
      tr.children[0].textContent = j.id; tr.children[1].textContent = WHAT[j.what] + (j.track ? ' ' + j.track : ''); tr.children[2].textContent = new Date(j.at).toLocaleString();
      tr.querySelector('[data-f]').onclick = () => api('POST', '/api/follow', { id: j.id }).catch((e) => toast(e.message));
      tr.querySelector('[data-c]').onclick = () => { if (confirm('Dừng job ' + j.id + ' trên máy build?')) api('POST', '/api/cancel', { id: j.id }).then((x) => toast('job: ' + x.status)).catch((e) => toast(e.message)); };
      $('jobs').appendChild(tr);
    }
  }
}
// hot update (on Horus's build PC only): what the kit's \`webgame hot info\` said; every action is a run in the log
function renderHot(s, running) {
  const h = s.hot, i = h && h.info;
  $('hot-card').hidden = !h;
  if (!h) return;
  pill($('hot-pill'), i && i.ready ? 'ok' : '', !i ? (h.loading ? 'đang hỏi…' : 'không rõ') : i.ready ? 'máy này phát được' : 'không dùng ở máy này');
  $('hot-why').hidden = !(i && !i.ready) && !h.error; $('hot-why').textContent = h.error || (i && i.why) || '';
  $('hot-body').hidden = !(i && i.ready);
  $('hot-at').textContent = h.loading ? 'đang hỏi server…' : h.at ? 'lúc ' + new Date(h.at).toLocaleTimeString() : '';
  for (const b of document.querySelectorAll('#hot-card button')) b.disabled = running || (b.dataset.zero === '1');
  $('hot-refresh').disabled = running || h.loading;
  if (!i || !i.ready) return;
  if (!hotFilled) {
    hotFilled = true;
    for (const [p, x] of Object.entries(i.platforms)) if (x.key) { const o = document.createElement('option'); o.value = p; o.textContent = PLAT[p] + ' · ' + x.app; $('hot-platform').appendChild(o); }
    const m = s.manifest || {};
    if (m.version) $('hot-id').value = 'v' + m.version;
    $('hot-bw').checked = !!m.build; $('hot-bw').disabled = !m.build;
    $('hot-bw-text').textContent = m.build ? 'build lại trước khi phát: ' + m.build : 'không có "build" trong horus-game.json: phát bản web đang có (build trước)';
    hotPlatform();
  }
  const js = JSON.stringify(i.platforms);
  if (js === hotLast) return;
  hotLast = js;
  const box = $('hot-status'); box.innerHTML = '';
  for (const [p, x] of Object.entries(i.platforms)) {
    if (!x.key) continue;
    const st = x.status, off = !!(st && st.off), div = document.createElement('div');
    div.className = 'hot-plat';
    div.innerHTML = '<div class="head"><span></span><code></code><span class="pill"></span></div>';
    div.querySelector('span').textContent = PLAT[p];
    div.querySelector('code').textContent = x.app;
    pill(div.querySelector('.pill'), st ? (off ? 'warn' : 'ok') : x.error ? 'failed' : '', st ? (off ? 'đang tắt' : 'đang bật') : x.error ? 'lỗi' : '…');
    if (st) div.firstChild.appendChild(button(off ? 'Bật' : 'Tắt', off ? '' : 'danger', () => hotOff(p, !off)));
    if (x.error) { const e = document.createElement('div'); e.className = 'step'; e.textContent = x.error; div.appendChild(e); }
    const rels = st ? st.releases.slice().reverse() : [];
    if (st && !rels.length) { const e = document.createElement('div'); e.className = 'step'; e.textContent = 'Chưa phát bản nào.'; div.appendChild(e); }
    for (const r of rels) {
      const row = document.createElement('div');
      row.className = 'hot-rel';
      row.innerHTML = '<span><code></code><div class="step"></div></span><input type="number" min="0" max="100" title="% người chơi">';
      row.querySelector('code').textContent = r.id + ' · ' + r.pct + '%';
      row.querySelector('.step').textContent = 'bản store ' + r.builds.join(', ') + ' · ' + r.files + ' file' + (r.at ? ' · ' + new Date(r.at).toLocaleString() : '') + (r.by ? ' · ' + r.by : '');
      const pct = row.querySelector('input'); pct.value = r.pct;
      row.appendChild(button('Lên %', '', () => hotRollout(p, r.id, pct.value)));
      const w = button('Rút lại', 'danger', () => { if (confirm('Rút lại ' + r.id + ' (' + PLAT[p] + ', đang ' + r.pct + '%)? App về bản phát trước đó (hoặc bản web trong app) từ lần mở sau.')) hot({ action: 'hot-withdraw', platform: p, id: r.id }); });
      if (r.pct === 0) { w.dataset.zero = '1'; w.disabled = true; }
      row.appendChild(w);
      div.appendChild(row);
    }
    box.appendChild(div);
  }
}
function button(text, cls, on) { const b = document.createElement('button'); b.className = 'btn ' + cls; b.textContent = text; b.onclick = on; return b; }
function hotPlatform() {
  const p = $('hot-platform').value, m = (S && S.manifest) || {};
  $('hot-builds-k').textContent = p === 'ios' ? 'Bản store nhận bản nóng: version(build), ví dụ ' + (m.version || '1.0.0') + '(1)' : 'Bản store nhận bản nóng: một versionCode Android (mỗi bản store phát riêng, id riêng)';
  $('hot-builds').value = p === 'ios' ? '' : (m.versionCode || '');
  $('hot-builds').placeholder = p === 'ios' ? (m.version || '1.0.0') + '(1)' : '21';
}
const hot = (o) => api('POST', '/api/hot', o).catch((e) => toast(e.message));
function hotRollout(p, id, v) {
  const pct = Number(v);
  if (!Number.isInteger(pct) || pct < 0 || pct > 100) { toast('% là số nguyên từ 0 đến 100'); return; }
  if (confirm('Đưa ' + id + ' (' + PLAT[p] + ') lên ' + pct + '% người chơi?')) hot({ action: 'hot-rollout', platform: p, id, pct });
}
function hotOff(p, off) {
  if (confirm(off ? 'TẮT cập nhật nóng ' + PLAT[p] + '? Mọi app ' + PLAT[p] + ' về bản web của chính nó từ lần mở sau (trong 1, 2 phút).' : 'BẬT lại cập nhật nóng ' + PLAT[p] + '? App nhận lại bản phát mới nhất hợp với nó.')) hot({ action: off ? 'hot-off' : 'hot-on', platform: p });
}
$('hot-platform').onchange = hotPlatform;
$('hot-refresh').onclick = () => api('POST', '/api/hot/refresh').catch((e) => toast(e.message));
$('hot-go').onclick = () => {
  const p = $('hot-platform').value, x = S.hot.info.platforms[p];
  const o = { action: 'hot-publish', platform: p, id: $('hot-id').value.trim(), builds: $('hot-builds').value.trim(), pct: Number($('hot-pct').value), buildWeb: $('hot-bw').checked };
  if (!o.id || !o.builds) { toast('Điền id và bản store'); return; }
  if (confirm('Phát bản nóng ' + o.id + ' cho ' + o.pct + '% người chơi ' + PLAT[p] + ' (' + x.app + ') đang cài bản store ' + o.builds + '?\\n' + (o.buildWeb ? 'Build lại bản web trước, rồi ' : '') + 'ký bằng khoá của game và gửi lên server cập nhật nóng. App nhận ở lần mở sau.')) hot(o);
};
const clock = (ms) => { const t = Math.round(ms / 1000); return Math.floor(t / 60) + ':' + String(t % 60).padStart(2, '0'); };
async function tick() { try { render(await api('GET', '/api/state?since=' + since)); } catch (e) { $('step').textContent = 'mất kết nối với lệnh horus-build (' + e.message + ')'; } setTimeout(tick, 800); }
$('key-save').onclick = () => api('PUT', '/api/key', { key: $('key').value }).then(() => { $('key').value = ''; toast('Đã lưu mã build'); }).catch((e) => toast(e.message));
$('m-save').onclick = () => {
  const f = {}; for (const k of ['name', 'appId', 'version', 'web', 'icon', 'orientation', 'background']) f[k] = $('m-' + k).value.trim();
  if ($('m-versionCode').value) f.versionCode = Number($('m-versionCode').value);
  api('PUT', '/api/manifest', f).then(() => toast('Đã lưu horus-game.json')).catch((e) => toast(e.message));
};
$('check').onclick = () => api('POST', '/api/check').then((c) => { $('check-out').textContent = (c.web === '.' ? 'thư mục game' : c.web) + ': ' + c.files + ' file, ' + c.mb + ' MB'; $('check-warn').innerHTML = ''; for (const w of c.warnings) { const li = document.createElement('li'); li.textContent = w; $('check-warn').appendChild(li); } }).catch((e) => { $('check-out').textContent = e.message; $('check-warn').innerHTML = ''; });
const syncWhat = () => { $('track-row').hidden = $('what').value !== 'play'; $('what-about').textContent = ABOUT[$('what').value]; };
$('what').onchange = syncWhat; syncWhat();
$('go').onclick = () => {
  const what = $('what').value, track = $('track').value;
  const ask = { apk: 'Gửi bản web lên máy build của Horus để làm APK cài thử?', aab: 'Gửi bản web lên máy build của Horus để làm AAB?', play: 'Gửi lên máy build của Horus và ĐƯA LÊN Google Play (' + track + ')?', ios: 'Gửi lên máy build của Horus, build iOS và ĐƯA LÊN TestFlight?' }[what];
  const buildWeb = $('bw').checked;
  if (confirm(ask + (buildWeb ? '' : '\\nNhớ build bản web mới nhất trước.'))) api('POST', '/api/build', { what, track, buildWeb }).catch((e) => toast(e.message));
};
$('stop').onclick = () => { if (confirm('Dừng lượt build này? Máy build của Horus dừng job theo.')) api('POST', '/api/stop').catch((e) => toast(e.message)); };
tick();
</script>
</body>
</html>
`});import R from"node:fs";import{spawn as zt}from"node:child_process";import Se from"node:os";import T from"node:path";import{fileURLToPath as Xt}from"node:url";function W(t){let o=T.join(t,"horus-game.json");if(!R.existsSync(o))throw new Error(`không thấy horus-game.json trong ${t} (chép file mẫu trong gói SDK rồi điền)`);let n;try{n=JSON.parse(R.readFileSync(o,"utf8"))}catch(r){throw new Error(`horus-game.json không phải JSON hợp lệ: ${r.message}`)}if(!n||typeof n!="object"||Array.isArray(n))throw new Error("horus-game.json phải là một object");if(typeof n.name!="string"||!n.name.trim()||n.name==="Tên game")throw new Error('horus-game.json: điền "name" (tên game)');if(n.repo!=null&&n.repo!==""&&(typeof n.repo!="string"||!/^(https:\/\/|ssh:\/\/|[\w.-]+@[\w.-]+:)\S+$/.test(n.repo)))throw new Error('horus-game.json: "repo" là link repo git của game, ví dụ https://github.com/team/game');for(let r of["web","icon"])if(n[r]!=null&&(typeof n[r]!="string"||T.isAbsolute(n[r])||n[r].split(/[\\/]/).includes("..")))throw new Error(`horus-game.json: "${r}" là đường dẫn tương đối nằm trong thư mục game`);if(n.iosIcons!=null){if(typeof n.iosIcons!="object"||Array.isArray(n.iosIcons))throw new Error('horus-game.json: "iosIcons" là { "tên": "file.png" }');for(let[r,e]of Object.entries(n.iosIcons)){if(!/^[A-Za-z0-9_-]{1,32}$/.test(r))throw new Error(`horus-game.json: iosIcons "${r}": tên chỉ gồm chữ, số, - và _ (tối đa 32)`);if(typeof e!="string"||T.isAbsolute(e)||e.split(/[\\/]/).includes(".."))throw new Error(`horus-game.json: iosIcons "${r}" là đường dẫn tương đối nằm trong thư mục game`)}}return n}function mt(t,o){let r=(o.web?[o.web]:Jt).map(e=>T.join(t,e)).find(e=>R.existsSync(T.join(e,"index.html")));if(!r)throw new Error(o.web?`không có index.html trong "${o.web}" (build game trước)`:`không thấy bản build web (index.html trong ${Jt.filter(e=>e!==".").join(", ")}): build game trước, hoặc ghi thư mục vào "web" của horus-game.json`);return r}function gt(t){let o=W(t),n=mt(t,o),r=new Set([...Ee,"build-online"]),e=jt(n,r).filter(([f])=>!/\.map$/.test(f)&&!(T.resolve(n)===T.resolve(t)&&/^(horus-game\.json|horus-build\.mjs|package(-lock)?\.json)$/.test(f))),i=[],s=R.readFileSync(T.join(n,"index.html"),"utf8");/\s(src|href)=["']https?:\/\//i.test(s)&&i.push("index.html tải file từ Internet (CDN): app phải chạy được khi không có mạng, nên chép các file đó vào bản build"),e.some(([f,u])=>/\.(m?js|html)$/.test(f)&&u.includes("Horus SDK"))||i.push("không thấy horus-sdk.js trong bản build: game chưa gắn SDK thì quảng cáo, mua hàng và lưu game không chạy trong app");let c=[["horus-game.json",Buffer.from(JSON.stringify(o,null,2))],...e.map(([f,u])=>[`dist/${f}`,u])],d=T.join(t,o.icon||"icon.png");R.existsSync(d)?c.push(["files/icon.png",R.readFileSync(d)]):i.push(`chưa có icon (${o.icon||"icon.png"}, PNG 1024×1024): app dùng icon tạm`);for(let[f,u]of Object.entries(o.iosIcons||{})){let p=T.join(t,u);R.existsSync(p)?c.push([`files/ios/AppIcon-${f}.png`,R.readFileSync(p)]):i.push(`iosIcons "${f}": không thấy ${u}`)}let a=vt(c);if(a.length>Yt)throw new Error(`bản build ${a.length/1048576|0} MB, quá ${Yt>>20} MB`);return{zip:a,manifest:o,web:n,files:e.length,bytes:a.length,warnings:i}}function je(t){let o=i=>{let s=t.indexOf(i);return s>=0?t[s+1]:null},n=t.includes("--ios"),r=t.includes("--play")||!!o("--track");if(n&&(r||t.includes("--aab")))throw new Error("--ios là iOS lên TestFlight; --aab / --play là Android: mỗi lần một nền tảng");let e=r?o("--track")||"internal":"";if(e==="production")throw new Error("production do người của Horus phát hành trong Play Console: gửi lên internal trước");if(e&&!["internal","alpha","beta"].includes(e))throw new Error(`--track ${e}: internal, alpha hoặc beta`);return n?{platform:"ios",output:"ipa",store:"testflight",track:""}:{platform:"android",output:r||t.includes("--aab")?"aab":"apk",store:r?"play":"",track:e}}function Ie(t,o,{log:n=console.log,signal:r,env:e=process.env}={}){return new Promise(i=>{let s=zt(t,{cwd:o,shell:!0,env:{...e,FORCE_COLOR:"0",NO_COLOR:"1"},windowsHide:!0}),c="",d=f=>{let p=(c+f.toString("utf8")).split(/\r?\n/);c=p.pop();for(let h of p)h.trim()&&n(`   ${h}`)};s.stdout.on("data",d),s.stderr.on("data",d);let a=()=>{process.platform==="win32"?zt("taskkill",["/pid",String(s.pid),"/t","/f"],{windowsHide:!0}).on("error",()=>{}):s.kill("SIGTERM")};r?.addEventListener("abort",a,{once:!0}),s.on("error",f=>{n(`   ${f.message}`),i(127)}),s.on("close",f=>{c.trim()&&n(`   ${c}`),r?.removeEventListener("abort",a),i(f??1)})})}async function wt(t,{cwd:o=process.cwd(),env:n=process.env,dir:r=Se.homedir(),log:e=console.log,interval:i=4e3,fetchImpl:s=fetch,signal:c,sigint:d=!0,onJob:a=()=>{},sdkDir:f=Ht(Xt(import.meta.url))}={}){let u=g=>{let l=t.indexOf(g);return l>=0?t[l+1]:null},p=new Set(["--key","--job","--out","--server","--track","--cancel"]),h=t.filter((g,l)=>!g.startsWith("--")&&!p.has(t[l-1]));if(t.includes("--help")||t.includes("-h"))return e(`Horus build ${_}: gửi bản build web cho Horus, nhận lại app Android.
  node horus-build.mjs [thư mục game] [--aab] [--no-wait] [--job <mã>] [--out <thư mục>]
  node horus-build.mjs --key <mã build>      lưu mã build Horus đưa (một lần)
  node horus-build.mjs ui [thư mục game]     mở trang build trên trình duyệt (như các lệnh dưới, có % và nút Dừng)
  node horus-build.mjs update [thư mục game] cập nhật Horus SDK của game từ máy chủ build (--major: cả bản đổi lớn)
  --no-update không tự cập nhật SDK lần này (mỗi lần build, lệnh tự cập nhật SDK nếu Horus có bản mới cùng major)
  --aab       bản AAB (Horus phải cài đặt game trước); mặc định là APK để cài thử
  --play      build AAB rồi máy Horus đưa thẳng lên Google Play, track internal (--track alpha|beta nếu Horus cho)
  --ios       build iOS trên Mac của Horus rồi đưa lên TestFlight (Horus phải cài đặt game cho iOS)
  --no-wait   gửi xong thì thoát, in mã job; theo dõi / lấy app sau bằng --job <mã>
  --cancel <mã>  dừng một job (Ctrl+C lúc đang chờ cũng dừng job trên máy build)
  --build-web chạy lệnh "build" của horus-game.json (build bản web) trước khi đóng gói
  --dry-run   chỉ đóng gói và kiểm tra, không gửi`),0;if(u("--key")&&(e(`đã lưu mã build vào ${tt(u("--key"),{dir:r})}`),t.length<=2))return 0;let k=h[0]==="update",x=T.resolve(o,(k?h[1]:h[0])||"."),y=u("--server")||n.HORUS_BUILD_SERVER||n.WEBGAME_BUILD_SERVER||q,$=u("--job")||u("--cancel");if($&&!/^[\w-]{1,80}$/.test($))throw new Error(`--job ${$}: không phải mã job`);let E=Z({env:{WEBGAME_BUILD_KEY:n.HORUS_BUILD_KEY||n.WEBGAME_BUILD_KEY},dir:r});if(k){if(!E)throw new Error("chưa có mã build: `node horus-build.mjs --key <mã>`");if(!f)throw new Error("chạy lệnh này bằng horus-build.mjs trong thư mục horus-sdk của game");let g=await lt({server:y,key:E,current:_,game:x,sdkDir:f,major:t.includes("--major"),fetchImpl:s,log:e});return(g.action==="same"||g.action==="none")&&e(`Horus SDK ${_} là bản mới nhất`),g.action==="failed"?1:0}if(u("--cancel")){if(!E)throw new Error("chưa có mã build: `node horus-build.mjs --key <mã>`");let g=await V(y,E,$,{fetchImpl:s});return e(`job ${$}: ${g.status==="building"?"máy build đang dừng nó":Zt[g.status]||g.status}`),0}let S=je(t),I=!1;if(!$&&E){let g={};try{g=W(x)}catch{}let l=!t.includes("--no-update")&&!t.includes("--dry-run")&&g.sdkUpdate!==!1&&n.HORUS_SDK_UPDATE!=="0";I=(await lt({server:y,key:E,current:_,game:x,sdkDir:f,update:l,fetchImpl:s,log:e})).action==="updated"}let O=!$&&t.includes("--build-web")?String(W(x).build||"").trim():"";I&&!O&&e("chú ý: bản web gửi lần này được build trước khi cập nhật SDK: build lại bản web (hoặc thêm --build-web) để app dùng SDK mới"),!$&&t.includes("--build-web")&&!O&&e('chú ý: horus-game.json không có "build" (lệnh build bản web): gửi bản web đang có');let X=O?4:3,j=g=>`[${g+(O?1:0)}/${X}]`;if(O){e(`== [1/${X}] build bản web: ${O}`);let g=await Ie(O,x,{log:e,signal:c,env:n});if(c?.aborted)throw Object.assign(new Error("đã dừng"),{cancelled:!0});if(g!==0)throw new Error(`lệnh build bản web lỗi (mã ${g}): sửa rồi build lại`)}if($){if(!E)throw new Error("chưa có mã build: `node horus-build.mjs --key <mã>`")}else{let g=gt(x);for(let v of g.warnings)e(`chú ý: ${v}`);if(e(`== ${j(1)} đóng gói ${T.relative(o,g.web)||"."}: ${g.files} file, ${(g.bytes/1048576).toFixed(1)} MB`),t.includes("--dry-run"))return e("--dry-run: không gửi"),0;if(!E)throw new Error("chưa có mã build: xin Horus rồi chạy `node horus-build.mjs --key <mã>` (hoặc đặt HORUS_BUILD_KEY)");let l=g.manifest;if(S.store&&!/^[a-zA-Z][\w]*(\.[a-zA-Z][\w]*)+$/.test(String(l.appId||"")))throw new Error('lên store cần "appId" Horus cấp trong horus-game.json');let b=At(x,{repo:l.repo});e(b.repo?`nguồn: ${b.repo}${b.branch?` ${b.branch}`:""}${b.commit?`@${b.commit.slice(0,7)}`:""}${b.dirty?" (có thay đổi chưa commit)":""}`:'chú ý: không thấy link repo git (git remote origin hay "repo" trong horus-game.json): Horus cần link repo của game, job có thể bị từ chối');let m={app:l.name,package:String(l.appId||""),...S,sdk:_,version:String(l.version||""),source:b};if($=await Lt(y,E,g.zip,m,{fetchImpl:s}),a($,m),e(`đã gửi job ${$} (${Le(m)}), máy build của Horus đang làm`),t.includes("--no-wait"))return e(`theo dõi sau: node horus-build.mjs --job ${$}`),0}e(`== ${j(2)} chờ máy build của Horus (thường vài phút, iOS 15 đến 25 phút)`);let C=await Tt(y,E,$,{fetchImpl:s,interval:i,log:e,words:Zt,signal:c,sigint:d}),P=Ot(C,"vi");if(P&&e(`   ${P}`),C.result===null)return e(P?"xong":"xong (không có file để tải)"),0;e(`== ${j(3)} tải app${C.log?` (${C.log})`:""}`);let z=T.resolve(o,u("--out")||T.join(x,"build-online"),Oe(C,$));return await It(y,E,$,z,{fetchImpl:s}),e(`xong: ${z}`),0}var Jt,Ee,Yt,Zt,Le,Oe,Vt,Wt=M(()=>{rt();et();at();Ut();Jt=["dist","build","www","public","."],Ee=new Set(["node_modules",".git",".vscode",".idea"]),Yt=200*1024*1024;Zt={pending:"đang xếp hàng",building:"đang build",done:"xong",failed:"build lỗi",cancelled:"đã dừng",stopping:"đang dừng: máy build của Horus kết thúc job (bản lên Play làm dở được xoá)",offline:"mất kết nối tới máy chủ build, đang thử lại (job vẫn chạy trên máy build)",online:"đã kết nối lại"};Le=t=>t.store==="testflight"?"iOS lên TestFlight":t.store==="play"?`AAB lên Google Play ${t.track}`:t.output.toUpperCase(),Oe=(t,o)=>`${String(t.app||"app").replace(/[^\w.-]+/g,"-").slice(0,40)||"app"}-${o}.zip`;Vt=process.argv[1]&&T.resolve(process.argv[1])===Xt(import.meta.url);Vt&&process.argv[2]==="ui"?Promise.resolve().then(()=>(Gt(),Ft)).then(t=>t.startUi({game:T.resolve(process.argv[3]||".")})).catch(t=>{console.error(`lỗi: ${t.message}`),process.exitCode=1}):Vt&&wt(process.argv.slice(2)).then(t=>{process.exitCode=t},t=>{console.error(`lỗi: ${t.message}`),process.exitCode=1})});Wt();export{je as buildMeta,gt as packGame,W as readManifest,wt as runBuild,Ie as runWebBuild,mt as webDir};
