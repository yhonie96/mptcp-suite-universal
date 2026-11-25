'use strict';
'require view';
'require rpc';
'require ui';

var status=rpc.declare({
 object:'xray-5mbps-manager',method:'status',expect:{}
});
var save=rpc.declare({
 object:'xray-5mbps-manager',method:'save_draft',
 params:['server','port','uuid','sni','reality_password','short_id','fingerprint'],
 expect:{}
});
var testTunnel=rpc.declare({
 object:'xray-5mbps-manager',method:'test_tunnel',expect:{}
});
var validate=rpc.declare({
 object:'xray-5mbps-manager',method:'validate_draft',expect:{}
});
var applySafe=rpc.declare({
 object:'xray-5mbps-manager',method:'apply_safe',expect:{}
});
var discard=rpc.declare({
 object:'xray-5mbps-manager',method:'discard_draft',expect:{}
});

function notify(r){
 ui.addNotification(null,E('p',{},r.message||'Selesai'),
  r.ok?'info':'error');
}
function field(title,type,value,placeholder){
 var el=E('input',{
  type:type||'text',value:value||'',placeholder:placeholder||'',
  autocomplete:'off'
 });
 return {el:el,node:E('label',{class:'x5-field'},[
  E('span',{},title),el
 ])};
}

return view.extend({
 load:function(){return status();},
 render:function(data){
  var point=String(data.server||'');
  var cut=point.lastIndexOf(':');
  var host=cut>0?point.substring(0,cut):point;
  var port=cut>0?point.substring(cut+1):'';

  var server=field('Alamat VPS','text',host);
  var serverPort=field('Port VPS','number',port);
  var uuid=field('UUID','text',data.uuid||'');
  var sni=field('SNI','text',data.sni||'');
  var key=field('REALITY Password / Public Key','text',data.reality_password||'');
  var shortId=field('Short ID','text',data.short_id||'');
  var fp=field('Fingerprint','text',data.fingerprint||'chrome');

  return E([],[
   E('style',{},`
.x5-summary,.x5-card{padding:16px;border-radius:12px;margin:14px 0;
 border:1px solid rgba(127,127,127,.25)}
.x5-summary{color:#fff;background:linear-gradient(135deg,#5b2c6f,#884ea0)}
.x5-head{display:flex;justify-content:space-between;gap:10px}
.x5-badge{padding:5px 9px;border-radius:16px;color:#fff;font-weight:700;
 height:max-content;background:#2f855a}
.x5-bad{background:#c53030}
.x5-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:11px}
.x5-field span{display:block;margin-bottom:5px;opacity:.75}
.x5-field input{width:100%;box-sizing:border-box}
.x5-note{padding:10px;margin:13px 0;border-left:4px solid #4299e1}
.x5-actions{display:grid;grid-template-columns:repeat(2,1fr);gap:8px;margin-top:15px}
.x5-actions .btn{width:100%}
@media(max-width:700px){.x5-grid,.x5-actions{grid-template-columns:1fr}
.x5-head{flex-direction:column}}
`),
   E('h2',{},'Kelola Akun Profil'),
   E('div',{class:'x5-summary'},[
    E('div',{style:'font-size:20px;font-weight:700'},'Profil Xray Terbatas'),
    E('div',{},'Port lokal '+data.local_port+' · Tujuan '+data.server)
   ]),
   E('div',{class:'x5-card'},[
    E('div',{class:'x5-head'},[
     E('strong',{},'Status layanan'),
     E('span',{class:'x5-badge '+((data.running&&data.listening)?'':'x5-bad')},
      (data.running&&data.listening)?'AKTIF':'GANGGUAN')
    ]),
    E('div',{class:'x5-note'},
     'Semua nilai akun aktif ditampilkan dan dapat diganti.'),
    E('div',{class:'x5-grid'},[
     server.node,serverPort.node,uuid.node,sni.node,key.node,shortId.node,fp.node
    ]),
    E('p',{},[
     E('strong',{},'Draf: '),
     data.draft?'TERSEDIA':'BELUM ADA'
    ]),
    E('div',{class:'x5-actions'},[
     E('button',{class:'btn cbi-button',click:function(ev){
      var b=ev.currentTarget;
      b.disabled=true;b.textContent='Menguji…';
      return testTunnel().then(notify).finally(function(){
       b.disabled=false;b.textContent='Uji Tunnel Aktif';
      });
     }},'Uji Tunnel Aktif'),
     E('button',{class:'btn cbi-button cbi-button-save',click:function(){
      return save(server.el.value,serverPort.el.value,uuid.el.value,
       sni.el.value,key.el.value,shortId.el.value,fp.el.value)
       .then(function(r){notify(r);if(r.ok)setTimeout(function(){
        window.location.reload();},800);});
     }},'Simpan Perubahan'),
     E('button',{class:'btn cbi-button cbi-button-action',click:function(){
      return validate().then(notify);
     }},'Validasi'),
     E('button',Object.assign({
      class:'btn cbi-button cbi-button-apply',
      click:function(){
       if(!confirm(
        'Terapkan draf Xray profil terbatas?\n\n' +
        'Snapshot dan rollback otomatis akan digunakan.'
       ))return;
       if(!confirm(
        'Konfirmasi terakhir. Xray profil terbatas akan mulai ulang sementara.'
       ))return;
       return applySafe().then(function(r){
        notify(r);
        if(r.ok)setTimeout(function(){location.reload();},2500);
       });
      }
     },data.draft?{}:{disabled:'disabled'}),'Terapkan Aman'),
     E('button',{class:'btn cbi-button cbi-button-negative',click:function(){
      if(!confirm('Hapus draf Xray profil terbatas?'))return;
      return discard().then(function(r){notify(r);if(r.ok)location.reload();});
     }},'Hapus Draf')
    ])
   ])
  ]);
 },
 handleSaveApply:null,handleSave:null,handleReset:null
});
