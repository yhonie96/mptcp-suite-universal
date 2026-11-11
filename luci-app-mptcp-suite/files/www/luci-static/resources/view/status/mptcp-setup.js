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
 ui.addNotification(null,E('p',{},r.message ||
  (r.ok ? 'Berhasil' : 'Gagal')),r.ok?'info':'error');
}

return view.extend({
 load:function(){ return getSettings(); },

 render:function(data){
  var sources=(data && data.sources)||[];
  var healthy=sources.filter(function(s){return s.up;});
  var mode=E('select',{},[
   E('option',{value:'combine'},'Gabungkan semua jalur aktif'),
   E('option',{value:'primary'},'Jalur utama + cadangan otomatis')
  ]);
  var primary=E('select',{},
   healthy.map(function(s){
    return E('option',{value:s.device},
     '%s (%s, metric %s)'.format(s.name,s.device,s.metric));
   })
  );

  mode.value=(data.mode==="primary") ? "primary" : "combine";
  if(data.primary) primary.value=data.primary;

  var cards=E('div',{'class':'setup-grid'},
   sources.map(function(s){
    var state=s.up?'Aktif':'Tidak aktif';
    return E('div',{'class':'setup-card'},[
     E('h3',{},s.name),
     E('p',{},'Perangkat: '+s.device),
     E('p',{},'IP: '+s.ip),
     E('p',{},'Metric: '+s.metric),
     E('p',{},'Status: '+state),
     E('button',{
      class:'btn cbi-button cbi-button-action',
      disabled:s.up ? null : '',
      click:function(ev){
       var b=ev.currentTarget;
       b.disabled=true; b.textContent='Menguji...';
       return testPath(s.device).then(function(r){
        notice({
         ok:r.ok,
         message:r.ok ?
          'Jalur '+s.name+' terhubung ('+r.seconds+' detik)' :
          'Jalur '+s.name+' gagal mencapai internet'
        });
       }).finally(function(){
        b.disabled=!s.up; b.textContent='Uji Jalur';
       });
      }
     },'Uji Jalur')
    ]);
   })
  );

  mode.addEventListener('change',function(){
   primary.disabled=(mode.value!=='primary');
  });
  primary.disabled=(mode.value!=="primary");

  return E('div',{},[
   E('style',{},[
    '.setup-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}',
    '.setup-card,.setup-box{padding:16px;border:1px solid #555;border-radius:10px;margin-bottom:12px}',
    '.setup-card .btn{width:100%;margin-top:8px}',
    '.setup-box select{width:100%;margin:6px 0 14px}'
   ].join('')),
   E('h2',{},'Setup Awal MPTCP Suite'),
   E('p',{},'Pilih mode koneksi. Pada mode cadangan, semua jalur aktif selain jalur utama otomatis menjadi cadangan.'),
   cards,
   E('div',{'class':'setup-box'},[
    E('label',{},'Mode koneksi'),
    mode,
    E('label',{},'Pilih jalur utama'),
    primary,
    E('button',{
     class:'btn cbi-button cbi-button-apply',
     disabled:healthy.length ? null : '',
     click:function(){
      var p=(mode.value==='primary')?primary.value:'';
      return setMode(mode.value,p).then(notice);
     }
    },'Simpan Mode')
   ]),
   E('p',{},'Mode disimpan untuk penggunaan berikutnya. MPTCP saat ini diaktifkan atau dinonaktifkan dari Dashboard.')
  ]);
 },

 handleSaveApply:null,
 handleSave:null,
 handleReset:null
});
