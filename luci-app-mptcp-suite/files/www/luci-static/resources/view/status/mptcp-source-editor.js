'use strict';
'require view';
'require rpc';
'require ui';

var status=rpc.declare({object:'mptcp-source-editor',method:'status',expect:{}});
var save=rpc.declare({object:'mptcp-source-editor',method:'save',
 params:['source','metric','enabled'],expect:{}});
var validate=rpc.declare({object:'mptcp-source-editor',method:'validate',expect:{}});
var apply=rpc.declare({object:'mptcp-source-editor',method:'apply',expect:{}});
var discard=rpc.declare({object:'mptcp-source-editor',method:'discard',expect:{}});

function note(r){ui.addNotification(null,E('p',{},r.message),r.ok?'info':'error');}

return view.extend({
 load:status,
 render:function(data){
  var sources=data.sources||[];
  var source=E('select',{},sources.map(function(s){
   return E('option',{value:s.name},s.name+' ('+s.device+')');
  }));
  var metric=E('input',{type:'number',min:'1',max:'999'});
  var enabled=E('input',{type:'checkbox'});
  function sync(){
   var s=sources.find(function(x){return x.name===source.value;});
   if(s){metric.value=s.metric;enabled.checked=s.enabled;}
  }
  source.addEventListener('change',sync); sync();

  return E('div',{},[
   E('h2',{},'Kelola Sumber Internet'),
   E('p',{},'Perubahan disimpan sebagai draft terlebih dahulu. Jaringan baru berubah setelah Terapkan ditekan.'),
   E('div',{class:'cbi-section'},[
    E('label',{},'Sumber'),source,
    E('br'),E('label',{},'Metric 1–999'),metric,
    E('br'),E('label',{},[enabled,' Aktifkan saat boot']),
    E('div',{style:'margin-top:14px'},[
     E('button',{class:'btn cbi-button',click:function(){
      return save(source.value,Number(metric.value),enabled.checked).then(note);
     }},'Simpan Draft'),' ',
     E('button',{class:'btn cbi-button',click:function(){return validate().then(note);}},'Validasi'),' ',
     E('button',{class:'btn cbi-button cbi-button-apply',click:function(){
      if(confirm('Terapkan perubahan? Rollback otomatis dijalankan jika internet gagal.'))
       return apply().then(note);
     }},'Terapkan'),' ',
     E('button',{class:'btn cbi-button-negative',click:function(){return discard().then(note);}},'Batalkan Draft')
    ])
   ])
  ]);
 },
 handleSaveApply:null,handleSave:null,handleReset:null
});
