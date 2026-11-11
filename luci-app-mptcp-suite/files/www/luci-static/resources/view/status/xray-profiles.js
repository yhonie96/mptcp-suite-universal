'use strict';
'require view';
'require rpc';
'require ui';

var status=rpc.declare({
 object:'xray-profiles',method:'status',expect:{}
});
var saveMeta=rpc.declare({
 object:'xray-profiles',method:'save_draft',
 params:['id','name','server','vps_port','local_port','limit_label'],
 expect:{}
});
var applyMeta=rpc.declare({
 object:'xray-profiles',method:'apply_draft',expect:{}
});
var removeProfile=rpc.declare({
 object:'xray-profiles',method:'delete',params:['id'],expect:{}
});

var runtimeDryRun=rpc.declare({
 object:'xray-profile-runtime',method:'dry_run',
 params:['id'],expect:{}
});
var runtimeTest=rpc.declare({
 object:'xray-profile-runtime',method:'test_tunnel',
 params:['id'],expect:{}
});
var runtimeActivate=rpc.declare({
 object:'xray-profile-runtime',method:'activate',
 params:['id'],expect:{}
});
var runtimeDeactivate=rpc.declare({
 object:'xray-profile-runtime',method:'deactivate',
 params:['id'],expect:{}
});
var runtimeDelete=rpc.declare({
 object:'xray-profile-runtime',method:'delete_full',
 params:['id'],expect:{}
});
var saveAccount=rpc.declare({
 object:'xray-profile-builder',method:'save_draft',
 params:['id','uuid','sni','reality_password','short_id','fingerprint'],
 expect:{}
});
var validateAccount=rpc.declare({
 object:'xray-profile-builder',method:'validate_draft',expect:{}
});
var generateProfile=rpc.declare({
 object:'xray-profile-builder',method:'generate',expect:{}
});

function notify(r){
 ui.addNotification(null,E('p',{},r.message||'Selesai'),
  r.ok?'info':'error');
}

function field(title,id,type,value,placeholder){
 return E('label',{class:'xp-field'},[
  E('span',{},title),
  E('input',{
   id:id,
   type:type||'text',
   value:value||'',
   placeholder:placeholder||'',
   autocomplete:'off'
  })
 ]);
}

function val(id){
 return document.getElementById(id).value.trim();
}

function stop(result){
 if(!result || !result.ok){
  notify(result||{ok:false,message:'Proses gagal'});
  throw new Error(result ? result.message : 'Proses gagal');
 }
 return result;
}

return view.extend({
 load:function(){
  return status();
 },

 render:function(data){
  var profiles=data.profiles||[];

  var cards=profiles.map(function(p){
   var active=p.running&&p.listening;

   var actions=[];

   if(p.id==='main'||p.id==='limit5'){
    actions.push(E('a',{
     class:'btn cbi-button cbi-button-action',
     href:L.url(
      'admin','status','mptcp-suite',
      p.id==='main'?'xray':'xray5'
     )
    },'Kelola Akun'));
   }

   if(!p.protected){
    actions.push(E('button',{
     class:'btn cbi-button',
     click:function(ev){
      var b=ev.currentTarget;
      b.disabled=true;
      b.textContent='Memeriksa…';

      return runtimeDryRun(p.id).then(function(r){
       notify(r);
      }).finally(function(){
       b.disabled=false;
       b.textContent='Periksa Profil';
      });
     }
    },'Periksa Profil'));

    actions.push(E('button',{
     class:'btn cbi-button',
     click:function(ev){
      var b=ev.currentTarget;
      b.disabled=true;
      b.textContent='Menguji…';

      return runtimeTest(p.id).then(function(r){
       notify(r);
      }).finally(function(){
       b.disabled=false;
       b.textContent='Uji Tunnel';
      });
     }
    },'Uji Tunnel'));

    if(p.enabled){
     actions.push(E('button',{
      class:'btn cbi-button cbi-button-negative',
      click:function(){
       if(!confirm(
        'Nonaktifkan profil '+p.name+'?\n\n'+
        'Service profil akan dihentikan dan dinonaktifkan saat boot.'
       ))return;

       return runtimeDeactivate(p.id).then(function(r){
        notify(r);
        if(r.ok)setTimeout(function(){
         location.reload();
        },900);
       });
      }
     },'Nonaktifkan'));
    }
    else {
     actions.push(E('button',{
      class:'btn cbi-button cbi-button-apply',
      click:function(){
       if(!confirm(
        'Aktifkan profil '+p.name+'?\n\n'+
        'Konfigurasi dan tunnel akan diuji dahulu. '+
        'Rollback otomatis dilakukan jika service gagal.'
       ))return;

       return runtimeActivate(p.id).then(function(r){
        notify(r);
        if(r.ok)setTimeout(function(){
         location.reload();
        },1200);
       });
      }
     },'Aktifkan Aman'));
    }

    actions.push(E('button',{
     class:'btn cbi-button cbi-button-negative',
     click:function(){
      if(p.enabled){
       notify({
        ok:false,
        message:'Nonaktifkan profil sebelum menghapus lengkap.'
       });
       return;
      }

      if(!confirm(
       'Hapus lengkap profil '+p.name+'?\n\n'+
       'Metadata, service, dan konfigurasi akun akan dihapus permanen.'
      ))return;

      if(!confirm(
       'Konfirmasi terakhir: hapus profil '+p.id+'?'
      ))return;

      return runtimeDelete(p.id).then(function(r){
       notify(r);
       if(r.ok)setTimeout(function(){
        location.reload();
       },900);
      });
     }
    },'Hapus Lengkap'));
   }
   else {
    actions.push(E('button',{
     class:'btn cbi-button cbi-button-negative',
     click:function(){
      notify({
       ok:false,
       message:'Profil sistem dilindungi dan tidak dapat dihapus.'
      });
     }
    },'Hapus Profil (Dilindungi)'));
   }

   return E('div',{class:'xp-card'},[
    E('div',{class:'xp-head'},[
     E('div',{},[
      E('div',{class:'xp-name'},p.name),
      E('div',{class:'xp-meta'},
       (p.target||p.server+':'+p.vps_port)+
       ' · Lokal '+p.local_port)
     ]),
     E('span',{
      class:'xp-badge '+(active?'xp-ok':'xp-warn')
     },active?'AKTIF':p.enabled?'GANGGUAN':'NONAKTIF')
    ]),

    E('div',{class:'xp-grid'},[
     E('div',{},['Limit: ',E('strong',{},p.limit)]),
     E('div',{},['Port VPS: ',E('strong',{},p.vps_port)]),
     E('div',{},['Service: ',E('strong',{},p.service)]),
     E('div',{},['ID: ',E('strong',{},p.id)])
    ]),

    actions.length
     ? E('div',{class:'xp-actions'},actions)
     : ''
   ]);
  });

  return E([],[
   E('style',{},`
.xp-summary{padding:21px;border-radius:19px;margin:14px 0;color:#fff;background:linear-gradient(135deg,#4338ca,#2563eb);box-shadow:0 11px 28px rgba(0,0,0,.2)}
.xp-wizard,.xp-card{padding:18px;margin:13px 0;border-radius:17px;border:1px solid rgba(127,127,127,.25);background:linear-gradient(145deg,rgba(127,127,127,.09),rgba(127,127,127,.02));box-shadow:0 6px 18px rgba(0,0,0,.09)}
.xp-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}
.xp-name{font-size:21px;font-weight:850}.xp-meta{opacity:.68;margin-top:6px;overflow-wrap:anywhere}
.xp-badge{padding:6px 10px;border-radius:999px;color:#fff;font-size:11px;font-weight:800;height:max-content}
.xp-ok{background:#168750}.xp-warn{background:#b7791f}
.xp-grid,.xp-form-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:9px;margin-top:14px}
.xp-grid div{padding:11px;background:rgba(127,127,127,.09);border-radius:10px;overflow-wrap:anywhere}
.xp-field span{display:block;margin-bottom:6px;font-weight:750;opacity:.78}
.xp-field input{width:100%;height:44px;padding:0 12px;box-sizing:border-box;border-radius:9px}
.xp-note{padding:13px;margin:12px 0;border-left:4px solid #3b82f6;background:rgba(59,130,246,.09);border-radius:9px;line-height:1.5}
.xp-actions{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:9px;margin-top:14px}
.xp-actions .btn,.xp-create{width:100%;box-sizing:border-box;border-radius:11px!important;padding:10px!important}
.xp-create{margin-top:15px}
@media(max-width:520px){.xp-grid,.xp-form-grid,.xp-actions{grid-template-columns:1fr}.xp-head{flex-direction:column}}
`),

   E('h2',{},'Profil Xray'),

   E('div',{class:'xp-summary'},[
    E('div',{style:'font-size:20px;font-weight:700'},
     profiles.length+' profil terdaftar'),
    E('div',{},
     'Tambah profil baru melalui satu form. Profil baru tetap nonaktif.')
   ]),

   E('div',{},cards),

   E('div',{class:'xp-wizard'},[
    E('h3',{},'Tambah Profil Xray'),

    E('div',{class:'xp-note'},
     'Pastikan akun dan port sudah tersedia di VPS. Label kecepatan hanya informasi; limit sebenarnya diatur pada VPS.'),

    E('div',{class:'xp-form-grid'},[
     field('ID profil','xp-id','text','','contoh: limit10'),
     field('Nama profil','xp-name','text','','contoh: 10 Mbps'),
     field('IP / domain VPS','xp-server','text',
      profiles[0] ? profiles[0].server : ''),
     field('Port VPS','xp-vps','number','','contoh: 16445'),
     field('Port lokal','xp-local','number','','contoh: 12347'),
     field('Label limit','xp-limit','text','','contoh: 10 Mbps'),

     field('UUID','xp-uuid','password','','Rahasia'),
     field('SNI','xp-sni','text','www.cloudflare.com'),
     field('REALITY Public Key / Password',
      'xp-key','password','','Rahasia'),
     field('Short ID','xp-short','password','','Rahasia'),
     field('Fingerprint','xp-fp','text','chrome')
    ]),

    E('button',{
     class:'btn cbi-button cbi-button-action xp-create',
     click:function(ev){
      var button=ev.currentTarget;
      var id=val('xp-id');

      if(!id){
       notify({ok:false,message:'ID profil wajib diisi'});
       return;
      }

      if(!confirm(
       'Buat profil '+id+'?\n\n'+
       'Konfigurasi dan service akan dibuat, tetapi profil tetap nonaktif.'
      ))return;

      button.disabled=true;
      button.textContent='Membuat Profil…';

      return saveMeta(
       id,val('xp-name'),val('xp-server'),
       val('xp-vps'),val('xp-local'),val('xp-limit')
      )
      .then(stop)
      .then(function(){return applyMeta();})
      .then(stop)
      .then(function(){
       return saveAccount(
        id,val('xp-uuid'),val('xp-sni'),
        val('xp-key'),val('xp-short'),val('xp-fp')
       );
      })
      .then(stop)
      .then(function(){return validateAccount();})
      .then(stop)
      .then(function(){return generateProfile();})
      .then(stop)
      .then(function(r){
       notify({
        ok:true,
        message:'Profil berhasil dibuat dan tetap nonaktif.'
       });
       setTimeout(function(){location.reload();},1000);
       return r;
      })
      .catch(function(err){
       notify({
        ok:false,
        message:'Pembuatan berhenti aman: '+err.message
       });
      })
      .finally(function(){
       button.disabled=false;
       button.textContent='Buat Profil';
      });
     }
    },'Buat Profil')
   ])
  ]);
 },

 handleSaveApply:null,
 handleSave:null,
 handleReset:null
});
