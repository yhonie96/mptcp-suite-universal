'use strict';
import * as fs from 'fs';

let input=ARGV[0], output=ARGV[1];
let tunnel=ARGV[2], direct=ARGV[3];
if(!input || !output || !tunnel || !direct)
 exit(2);

let j=json(fs.readfile(input)), clean=[];
if(!j || !j.routing || !j.routing.rules)
 exit(3);

// Argumen ketiga adalah freedom_tag: dialer tunnel yang membawa
// redirect paksa ke VPS. Memakainya sebagai tujuan Direct akan
// memaksa seluruh trafik ke port VPS dan mematikan internet mode
// Direct. Pilih outbound freedom yang benar-benar polos (tanpa
// redirect) dari config sendiri bila ada; fallback ke argumen.
if(j.outbounds){
 for(let o in j.outbounds){
  if(o.protocol=='freedom' && !(o.settings && o.settings.redirect)){
   direct=o.tag;
   break;
  }
 }
}

for(let r in j.routing.rules){
 if(r.network=='tcp,udp' && !r.port && !r.domain &&
    !r.ip && !r.source && !r.inboundTag) continue;
 if(r.outboundTag==tunnel) r.outboundTag=direct;
 push(clean,r);
}
push(clean,{type:'field',network:'tcp,udp',outboundTag:direct});
j.routing.rules=clean;
fs.writefile(output,sprintf('%.2J\n',j));
