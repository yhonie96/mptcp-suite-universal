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

function note(r){
 ui.addNotification(null,E('p',{},r.message||'Selesai'),r.ok?'info':'error');
}

return view.extend({
 load:status,

 render:function(data){
  var sources=data.sources||[];
  var source=E('select',{},sources.map(function(s){
   return E('option',{value:s.name},s.name+' ('+s.device+')');
  }));
  var metric=E('input',{type:'number',min:'1',max:'999'});
  var enabled=E('input',{type:'checkbox'});

  function current(){
   return sources.find(function(x){return x.name===source.value;})||{};
  }

  function sync(){
   var s=current();
   metric.value=s.metric||1;
   enabled.checked=Boolean(s.enabled);
   device.textContent=s.device||'-';
   state.textContent=s.state==='supported'?'DIDUKUNG':(s.state==='unknown'?'BELUM TERDETEKSI':String(s.state||'-').toUpperCase());
   state.className=s.state==='supported'?'se-ok':'se-warn';
  }

  var device=E('strong',{},'-');
  var state=E('strong',{class:'se-warn'},'-');
  source.addEventListener('change',sync);

  var root=E('div',{class:'se-wrap'},[
   E('style',{},[
    '.se-wrap{max-width:900px;margin:auto}',
    '.se-title{font-size:28px;font-weight:850;margin:4px 0 14px}',
    '.se-hero{padding:20px;border-radius:19px;color:#fff;background:linear-gradient(135deg,#155e75,#2563eb);box-shadow:0 11px 28px rgba(0,0,0,.2);margin-bottom:18px}',
    '.se-hero strong{display:block;font-size:20px;margin-bottom:7px}',
    '.se-hero span{line-height:1.55;opacity:.9}',
    '.se-box{padding:18px;border:1px solid rgba(127,127,127,.25);border-radius:17px;background:linear-gradient(145deg,rgba(127,127,127,.09),rgba(127,127,127,.02));box-shadow:0 6px 18px rgba(0,0,0,.09)}',
    '.se-box label{display:block;font-weight:750;margin:10px 0 6px}',
    '.se-box select,.se-box input[type=number]{width:100%;height:46px;padding:0 14px;line-height:46px;border-radius:9px;box-sizing:border-box;margin-bottom:10px}',
    '.se-info{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin:12px 0}',
    '.se-info div{padding:11px;border-radius:10px;background:rgba(127,127,127,.08)}',
    '.se-info span{display:block;font-size:10px;opacity:.6;text-transform:uppercase;margin-bottom:4px}',
    '.se-ok{color:#55c878}.se-warn{color:#e5b94f}',
    '.se-toggle{display:flex!important;align-items:center;gap:10px;padding:12px;border-radius:10px;background:rgba(127,127,127,.08)}',
    '.se-toggle input{width:22px;height:22px;margin:0}',
    '.se-actions{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-top:15px}',
    '.se-actions .btn{width:100%;border-radius:11px!important;padding:11px!important}',
    '.se-draft{margin-top:14px;padding:12px;border-left:4px solid '+(data.draft?'#f59e0b':'#22c55e')+';background:rgba(127,127,127,.08);border-radius:9px}',
    '@media(max-width:600px){.se-title{font-size:25px}.se-actions{grid-template-columns:1fr}}'
   ].join('')),

   E('h2',{class:'se-title'},'Kelola Sumber Internet'),

   E('div',{class:'se-hero'},[
    E('strong',{},'Atur sumber koneksi dengan aman'),
    E('span',{},'Perubahan disimpan sebagai draft, divalidasi, lalu diterapkan dengan rollback otomatis jika internet gagal.')
   ]),

   E('div',{class:'se-box'},[
    E('label',{},'Sumber internet'),
    source,

    E('div',{class:'se-info'},[
     E('div',{},[E('span',{},'Perangkat'),device]),
     E('div',{},[E('span',{},'Status MPTCP'),state])
    ]),

    E('label',{},'Metric 1–999'),
    metric,

    E('label',{class:'se-toggle'},[
     enabled,
     E('span',{},'Aktifkan saat boot')
    ]),

    E('div',{class:'se-actions'},[
     E('button',{class:'btn cbi-button',click:function(){
      return save(source.value,Number(metric.value),enabled.checked).then(note);
     }},'Simpan Draft'),

     E('button',{class:'btn cbi-button',click:function(){
      return validate().then(note);
     }},'Validasi'),

     E('button',{class:'btn cbi-button cbi-button-apply',click:function(){
      if(confirm('Terapkan perubahan? Rollback otomatis dijalankan jika internet gagal.'))
       return apply().then(note);
     }},'Terapkan'),

     E('button',{class:'btn cbi-button-negative',click:function(){
      return discard().then(note);
     }},'Batalkan Draft')
    ]),

    E('div',{class:'se-draft'},
     data.draft
      ?'Draft tersedia dan belum diterapkan.'
      :'Tidak ada draft perubahan.')
   ])
  ]);

  sync();
  return root;
 },

 handleSaveApply:null,
 handleSave:null,
 handleReset:null
});
