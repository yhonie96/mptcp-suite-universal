'use strict';
import * as fs from 'fs';

let input=ARGV[0], output=ARGV[1];
let j=json(fs.readfile(input));
let direct=input=='/etc/xray/config.json'?'direct':'direct-5mbps';
let clean=[];

for(let r in j.routing.rules){
 if(r.network=='tcp,udp' && !r.port && !r.domain &&
    !r.ip && !r.source && !r.inboundTag) continue;
 if(r.outboundTag=='vless' || r.outboundTag=='vless-5mbps')
  r.outboundTag=direct;
 push(clean,r);
}
push(clean,{type:'field',network:'tcp,udp',outboundTag:direct});
j.routing.rules=clean;
fs.writefile(output,sprintf('%.2J\n',j));
