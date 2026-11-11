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
var resumeCheck=rpc.declare({object:"mptcp",method:"resume_check",expect:{}});
var resumeMptcp=rpc.declare({object:"mptcp",method:"resume",expect:{}});
var pauseMptcp=rpc.declare({object:"mptcp",method:"pause",expect:{}});

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
  var root=E('div',{});

  function draw(d){
   var h=d[0]||{}, s=d[1]||{}, primary=s.primary||'';
   var sources=s.sources||[];

   root.replaceChildren(
    E('style',{},[
     '.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:12px}',
     '.card{padding:16px;margin:12px 0;border:1px solid #555;border-radius:12px}',
     '.ok{color:#55c878}.warn{color:#e5b94f}',
     '.head{display:flex;justify-content:space-between;align-items:center;gap:8px}',
     '.card .btn{width:100%;margin-top:10px}'
    ].join('')),
    E('h2',{},'Dashboard MPTCP Suite'),
    E('div',{class:'card'},[
     E('h3',{},h.paused?'Internet Langsung':'MPTCP Aktif'),
     E('p',{class:h.http==='204'?'ok':'warn'},
      'Internet: '+(h.http==='204'?'Normal':'Gangguan')),
     E('p',{},'Mode: '+(s.mode==='primary'?'Utama + Cadangan':'Gabungkan Semua')),
     E('p',{},'Jalur utama: '+(primary||'-')),
     E('p',{},'Endpoint: '+(h.endpoint||0)+' | Subflow aktif: '+(h.subflow||0)),
     E('button',{
      class:'btn cbi-button cbi-button-apply',
      click:function(ev){
       var b=ev.currentTarget;
       b.disabled=true;
       var run=h.paused ? resumeCheck().then(function(r){
        if(!r.ok) throw new Error(r.message||'Precheck gagal');
        b.textContent='Mengaktifkan MPTCP...';
        return resumeMptcp();
       }) : pauseMptcp();
       return run.then(function(r){
        ui.addNotification(null,E('p',{},r.message||'Selesai'),r.ok?'info':'error');
        return loadAll().then(draw);
       }).catch(function(e){
        ui.addNotification(null,E('p',{},e.message),'error');
       }).finally(function(){b.disabled=false;});
      }
     },h.paused?'Periksa & Aktifkan MPTCP':'Jeda MPTCP')
    ]),
    E('div',{class:'grid'},sources.map(function(x){
     var role=x.backup?'Cadangan':
      (x.device===primary?'Utama':'Normal');
     var attrs={
      class:'btn cbi-button cbi-button-action',
      click:function(ev){
       var b=ev.currentTarget;
       b.disabled=true;b.textContent='Menguji...';
       return testPath(x.device).then(function(r){
        ui.addNotification(null,E('p',{},
         r.ok?x.name+' terhubung ke internet':
          x.name+' gagal mencapai internet'),r.ok?'info':'error');
       }).finally(function(){
        b.disabled=!x.up;b.textContent='Uji Jalur';
       });
      }
     };
     if(!x.up)attrs.disabled='';

     return E('div',{class:'card'},[
      E('div',{class:'head'},[
       E('h3',{},x.name),
       E('strong',{class:x.up?'ok':'warn'},x.up?'AKTIF':'TIDAK AKTIF')
      ]),
      E('p',{},x.device+' · '+x.ip),
      E('p',{},'Gateway: '+x.gateway),
      E('p',{},'Metric: '+x.metric+' · Peran: '+role),
      E('p',{},'Download: '+size(x.rx_bytes)),
      E('p',{},'Upload: '+size(x.tx_bytes)),
      E('button',attrs,'Uji Jalur')
     ]);
    })),
    E('button',{
     class:'btn cbi-button',
     style:'margin-top:14px',
     click:function(ev){
      var b=ev.currentTarget;
      b.disabled=true;b.textContent='Memuat...';
      return loadAll().then(draw).finally(function(){
       b.disabled=false;b.textContent='Muat Ulang';
      });
     }
    },'Muat Ulang')
   );
  }

  draw(initial);
  poll.add(function(){
   return loadAll().then(draw);
  },10);
  return root;
 },

 handleSaveApply:null,
 handleSave:null,
 handleReset:null
});
