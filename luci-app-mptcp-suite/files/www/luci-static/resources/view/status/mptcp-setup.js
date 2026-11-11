'use strict';
'require view';
'require rpc';
'require ui';

var getSettings=rpc.declare({
 object:'mptcp-manager',method:'settings',expect:{}
});
var testPath=rpc.declare({
 object:'mptcp-manager',method:'test',
 params:['iface'],expect:{}
});
var setMode=rpc.declare({
 object:'mptcp-manager',method:'set_mode',
 params:['mode','primary'],expect:{}
});

function notice(r){
 ui.addNotification(null,E('p',{},r.message||
  (r.ok?'Berhasil':'Gagal')),r.ok?'info':'error');
}

return view.extend({
 load:function(){return getSettings();},

 render:function(data){
  var sources=(data&&data.sources)||[];
  var healthy=sources.filter(function(s){return s.up;});
  var mode=E('select',{},[
   E('option',{value:'combine'},'Bonding semua jalur aktif'),
   E('option',{value:'primary'},'Jalur utama + cadangan')
  ]);
  var primary=E('select',{},
   healthy.map(function(s){
    return E('option',{value:s.device},
     '%s (%s, metric %s)'.format(s.name,s.device,s.metric));
   })
  );
  var primaryWrap=E('div',{class:'setup-primary'},[
   E('label',{},'Pilih jalur utama'),
   primary
  ]);

  mode.value=data.mode==='primary'?'primary':'combine';
  if(data.primary)primary.value=data.primary;

  function updateMode(){
   primary.disabled=mode.value!=='primary';
   primaryWrap.style.display=mode.value==='primary'?'block':'none';
  }
  mode.addEventListener('change',updateMode);
  updateMode();

  var cards=E('div',{class:'setup-grid'},
   sources.map(function(s){
    var role=!s.up?'TIDAK AKTIF':
     (mode.value==='combine'?'BONDING':
      (s.device===primary.value?'UTAMA':'CADANGAN'));

    var attrs={
     class:'btn cbi-button cbi-button-action setup-test',
     disabled:s.up?null:'',
     click:function(ev){
      var b=ev.currentTarget;
      b.disabled=true;
      b.textContent='Menguji jalur...';
      return testPath(s.device).then(function(r){
       notice({
        ok:r.ok,
        message:r.ok
         ?'Jalur '+s.name+' terhubung ('+r.seconds+' detik)'
         :'Jalur '+s.name+' gagal mencapai internet'
       });
      }).finally(function(){
       b.disabled=!s.up;
       b.textContent='Uji Jalur';
      });
     }
    };

    return E('div',{class:'setup-card'},[
     E('div',{class:'setup-head'},[
      E('h3',{},s.name),
      E('span',{class:s.up?'setup-on':'setup-off'},
       s.up?'AKTIF':'TERPUTUS')
     ]),
     E('div',{class:'setup-device'},
      s.device+' · '+(s.ip||'Tanpa IP')),
     E('div',{class:'setup-info'},[
      E('div',{},[
       E('span',{},'Gateway'),
       E('strong',{},s.gateway||'-')
      ]),
      E('div',{},[
       E('span',{},'Metric'),
       E('strong',{},String(s.metric||'-'))
      ])
     ]),
     E('span',{class:'setup-role'},'PERAN: '+role),
     E('button',attrs,'Uji Jalur')
    ]);
   })
  );

  return E('div',{class:'setup-wrap'},[
   E('style',{},[
    '.setup-wrap{max-width:1100px;margin:auto}',
    '.setup-title{font-size:28px;font-weight:850;margin:4px 0 14px}',
    '.setup-hero{padding:20px;border-radius:19px;color:#fff;background:linear-gradient(135deg,#155e75,#2563eb);box-shadow:0 11px 28px rgba(0,0,0,.2);margin-bottom:19px}',
    '.setup-hero strong{display:block;font-size:20px;margin-bottom:7px}',
    '.setup-hero span{line-height:1.55;opacity:.9}',
    '.setup-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(245px,1fr));gap:13px}',
    '.setup-card,.setup-box{padding:18px;border:1px solid rgba(127,127,127,.25);border-radius:17px;background:linear-gradient(145deg,rgba(127,127,127,.09),rgba(127,127,127,.02));box-shadow:0 6px 18px rgba(0,0,0,.09)}',
    '.setup-head{display:flex;justify-content:space-between;align-items:center;gap:10px}',
    '.setup-head h3{font-size:21px;margin:0}',
    '.setup-on,.setup-off{padding:5px 9px;border-radius:999px;font-size:11px;font-weight:800}',
    '.setup-on{color:#86efac;background:rgba(34,197,94,.14)}',
    '.setup-off{color:#fca5a5;background:rgba(239,68,68,.14)}',
    '.setup-device{margin:8px 0 14px;opacity:.68}',
    '.setup-info{display:grid;grid-template-columns:1fr 1fr;gap:8px}',
    '.setup-info div{padding:10px;border-radius:10px;background:rgba(127,127,127,.08)}',
    '.setup-info span{display:block;font-size:10px;opacity:.6;text-transform:uppercase;margin-bottom:4px}',
    '.setup-role{display:inline-block;margin-top:12px;padding:5px 9px;border-radius:9px;color:#93c5fd;background:rgba(59,130,246,.13);font-size:11px;font-weight:800}',
    '.setup-test{width:100%;margin-top:13px!important;border-radius:11px!important}',
    '.setup-box{margin-top:17px}',
    '.setup-box label{display:block;font-weight:750;margin:8px 0 6px}',
    '.setup-box select{width:100%;height:46px;padding:0 14px;line-height:46px;border-radius:9px;margin-bottom:12px;box-sizing:border-box}',
    '.setup-save{width:100%;margin-top:10px!important;border-radius:11px!important;padding:11px!important;font-weight:800!important}',
    '.setup-note{margin-top:14px;padding:12px;border-left:4px solid #3b82f6;background:rgba(59,130,246,.08);border-radius:8px;line-height:1.5}',
    '@media(max-width:600px){.setup-title{font-size:25px}}'
   ].join('')),

   E('h2',{class:'setup-title'},'Setup Awal MPTCP Suite'),

   E('div',{class:'setup-hero'},[
    E('strong',{},'Atur jalur internet untuk MPTCP'),
    E('span',{},
     'Mode Bonding menggabungkan seluruh jalur aktif menuju VPS. '+
     'Mode Cadangan memakai satu jalur utama dan jalur lain sebagai cadangan.')
   ]),

   cards,

   E('div',{class:'setup-box'},[
    E('label',{},'Mode koneksi'),
    mode,
    primaryWrap,
    E('button',{
     class:'btn cbi-button cbi-button-apply setup-save',
     disabled:healthy.length?null:'',
     click:function(){
      var p=mode.value==='primary'?primary.value:'';
      return setMode(mode.value,p).then(notice);
     }
    },'Simpan Mode')
   ]),

   E('div',{class:'setup-note'},
    'Aktivasi atau Jeda MPTCP dilakukan dari Dashboard. '+
    healthy.length+' dari '+sources.length+' jalur saat ini aktif.')
  ]);
 },

 handleSaveApply:null,
 handleSave:null,
 handleReset:null
});
