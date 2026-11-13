'use strict';
'require view';
'require rpc';
'require ui';
'require poll';

var status=rpc.declare({object:'mptcp',method:'status',expect:{}});
var settings=rpc.declare({object:'mptcp-manager',method:'settings',expect:{}});
var testPath=rpc.declare({
 object:'mptcp-manager',method:'test',params:['iface'],expect:{}
});
var pauseMptcp=rpc.declare({object:'mptcp',method:'pause',expect:{}});

function size(n){
 n=Number(n)||0;
 if(n>=1073741824)return(n/1073741824).toFixed(2)+' GiB';
 if(n>=1048576)return(n/1048576).toFixed(1)+' MiB';
 if(n>=1024)return(n/1024).toFixed(1)+' KiB';
 return n+' B';
}

function loadAll(){return Promise.all([status(),settings()]);}

return view.extend({
 load:loadAll,

 render:function(initial){
  var root=E('div',{class:'ms-wrap'});

  function draw(d){
   var h=d[0]||{}, s=d[1]||{}, primary=s.primary||'';
   var sources=s.sources||[];
   var activeSources=sources.filter(function(x){return x.up;}).length;
   var active=!h.paused;
   var actionAttrs={
    class:'btn cbi-button cbi-button-apply ms-action'
   };
   if(h.paused||Number(h.profile_count||0)===0)
    actionAttrs.disabled='';
   var internet=h.http==='204';

   function stat(label,value,good){
    return E('div',{class:'ms-stat'},[
     E('span',{class:'ms-stat-label'},label),
     E('strong',{class:good===false?'ms-warn':'ms-good'},String(value))
    ]);
   }

   root.replaceChildren(
    E('style',{},[
     '.ms-wrap{max-width:1100px;margin:auto}',
     '.ms-title{margin:4px 0 16px;font-size:28px;font-weight:800}',
     '.ms-hero{position:relative;overflow:hidden;padding:22px;border-radius:20px;color:#fff;box-shadow:0 12px 30px rgba(0,0,0,.22);background:linear-gradient(135deg,'+(active?'#155e75,#2563eb':'#92400e,#ea580c')+')}',
     '.ms-hero:after{content:"";position:absolute;width:220px;height:220px;border-radius:50%;right:-80px;top:-100px;background:rgba(255,255,255,.12)}',
     '.ms-hero-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;position:relative;z-index:1}',
     '.ms-mode{font-size:23px;font-weight:850;letter-spacing:.4px}',
     '.ms-badge{padding:7px 12px;border-radius:999px;background:rgba(255,255,255,.18);font-size:12px;font-weight:800}',
     '.ms-desc{margin:10px 0 18px;opacity:.92;line-height:1.55;position:relative;z-index:1}',
     '.ms-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:9px;position:relative;z-index:1}',
     '.ms-stat{padding:12px;border-radius:13px;background:rgba(0,0,0,.16);backdrop-filter:blur(5px)}',
     '.ms-stat-label{display:block;font-size:11px;opacity:.75;margin-bottom:5px;text-transform:uppercase;letter-spacing:.7px}',
     '.ms-stat strong{font-size:19px}',
     '.ms-good{color:#a7f3d0}.ms-warn{color:#fde68a}',
     '.ms-action{width:100%;margin-top:16px!important;padding:12px!important;border-radius:12px!important;font-weight:800!important;position:relative;z-index:1}',
     '.ms-section{display:flex;justify-content:space-between;align-items:center;margin:24px 2px 10px}',
     '.ms-section h3{margin:0;font-size:19px}',
     '.ms-section span{font-size:12px;opacity:.65}',
     '.ms-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:13px}',
     '.ms-wan{padding:17px;border:1px solid rgba(127,127,127,.25);border-radius:17px;background:linear-gradient(145deg,rgba(127,127,127,.08),rgba(127,127,127,.02));box-shadow:0 6px 18px rgba(0,0,0,.09)}',
     '.ms-wan-head{display:flex;justify-content:space-between;gap:10px;align-items:center}',
     '.ms-wan-name{font-size:20px;font-weight:800}',
     '.ms-online,.ms-offline{padding:5px 9px;border-radius:999px;font-size:11px;font-weight:800}',
     '.ms-online{color:#86efac;background:rgba(34,197,94,.14)}',
     '.ms-offline{color:#fca5a5;background:rgba(239,68,68,.14)}',
     '.ms-device{margin:7px 0 14px;font-size:13px;opacity:.68}',
     '.ms-info{display:grid;grid-template-columns:1fr 1fr;gap:8px}',
     '.ms-info div{padding:9px;border-radius:10px;background:rgba(127,127,127,.08)}',
     '.ms-info span{display:block;font-size:10px;opacity:.6;text-transform:uppercase;margin-bottom:3px}',
     '.ms-role{display:inline-block;margin-top:12px;padding:5px 9px;border-radius:9px;background:rgba(59,130,246,.13);color:#93c5fd;font-size:11px;font-weight:700}',
     '.ms-test{width:100%;margin-top:13px!important;border-radius:11px!important}',
     '.ms-refresh{width:100%;margin-top:15px!important;border-radius:11px!important}',
     '@media(max-width:600px){.ms-title{font-size:25px}.ms-stats{grid-template-columns:1fr 1fr}.ms-stat:last-child{grid-column:1/3}.ms-mode{font-size:20px}}'
    ].join('')),

    E('h2',{class:'ms-title'},'Dashboard MPTCP Suite'),

    E('div',{class:'ms-hero'},[
     E('div',{class:'ms-hero-head'},[
      E('div',{class:'ms-mode'},active?'FULL TUNNEL VPS':'DIRECT PER JALUR'),
      E('span',{class:'ms-badge'},active?'MPTCP AKTIF':'MPTCP DIJEDA')
     ]),
     E('div',{class:'ms-desc'},
      active
       ? 'HTTP, HTTPS, YouTube, dan trafik umum diamankan melalui VPS menggunakan gabungan jalur MPTCP.'
       : 'Tunnel VPS dihentikan. Trafik keluar langsung melalui ISP berdasarkan aturan setiap jalur.'),
     E('div',{class:'ms-stats'},[
      stat('Internet',internet?'Normal':'Gangguan',internet),
      stat('Endpoint',h.endpoint||0,(h.endpoint||0)>0||h.paused),
      stat('Subflow aktif',h.subflow||0,(h.subflow||0)>0||h.paused)
     ]),
     E('button',Object.assign(actionAttrs,{
      click:function(ev){
       if(h.paused)return;
       var b=ev.currentTarget;
       b.disabled=true;
       return pauseMptcp().then(function(r){
        ui.addNotification(null,E("p",{},r.message||"Selesai"),r.ok?"info":"error");
        return loadAll().then(draw);
       }).finally(function(){b.disabled=false;});
      }
     }),h.paused?'Aktivasi MPTCP Diblokir':'Jeda MPTCP')
    ]),

    E('div',{class:'ms-section'},[
     E('h3',{},'Jalur Internet'),
     E('span',{},activeSources+' aktif dari '+sources.length+' sumber')
    ]),

    E('div',{class:'ms-grid'},sources.map(function(x){
     var role=!x.up?'Tidak aktif':(active?'Bonding':(x.backup?'Cadangan':'Direct'));
     var attrs={
      class:'btn cbi-button cbi-button-action ms-test',
      click:function(ev){
       var b=ev.currentTarget;
       b.disabled=true;
       b.textContent='Menguji jalur...';
       return testPath(x.device).then(function(r){
        ui.addNotification(null,E('p',{},
         r.ok?x.name+' terhubung ke internet':x.name+' gagal mencapai internet'),
         r.ok?'info':'error');
       }).finally(function(){
        b.disabled=!x.up;
        b.textContent='Uji Jalur';
       });
      }
     };
     if(!x.up)attrs.disabled='';

     return E('div',{class:'ms-wan'},[
      E('div',{class:'ms-wan-head'},[
       E('div',{class:'ms-wan-name'},x.name),
       E('span',{class:x.up?'ms-online':'ms-offline'},x.up?'AKTIF':'TERPUTUS')
      ]),
      E('div',{class:'ms-device'},x.device+' · '+(x.ip||'Tanpa IP')),
      E('div',{class:'ms-info'},[
       E('div',{},[E('span',{},'Gateway'),x.gateway||'-']),
       E('div',{},[E('span',{},'Metric'),String(x.metric||'-')]),
       E('div',{},[E('span',{},'Download'),size(x.rx_bytes)]),
       E('div',{},[E('span',{},'Upload'),size(x.tx_bytes)])
      ]),
      E('span',{class:'ms-role'},'PERAN: '+role.toUpperCase()),
      E('button',attrs,'Uji Jalur')
     ]);
    })),

    E('button',{
     class:'btn cbi-button ms-refresh',
     click:function(ev){
      var b=ev.currentTarget;
      b.disabled=true;
      b.textContent='Memuat data...';
      return loadAll().then(draw).finally(function(){
       b.disabled=false;
       b.textContent='Muat Ulang Dashboard';
      });
     }
    },'Muat Ulang Dashboard')
   );
  }

  draw(initial);
  poll.add(function(){return loadAll().then(draw);},10);
  return root;
 },

 handleSaveApply:null,
 handleSave:null,
 handleReset:null
});
