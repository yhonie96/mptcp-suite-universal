'use strict';
'require view';
'require rpc';
'require ui';

var status = rpc.declare({
 object: 'xray-traffic-rules',
 method: 'status',
 expect: {}
});

var saveDraft = rpc.declare({
 object:'xray-traffic-rules',
 method:'save_draft',
 params:[
  'adblock','youtube_tunnel','http_direct',
  'block_quic','tunnel_domains','direct_domains'
 ],
 expect:{}
});

var youtubeStatus = rpc.declare({ object:'youtube-policy', method:'status', expect:{} });var youtubeApply = rpc.declare({ object:'youtube-policy', method:'apply', params:['mode'], expect:{} });
var validateDraft = rpc.declare({
 object:"xray-traffic-rules",
 method:"validate_draft",
 expect:{}
});

var applyDraft = rpc.declare({
 object:"xray-traffic-rules",
 method:"apply_draft",
 expect:{}
});

var discardDraft = rpc.declare({
 object:'xray-traffic-rules',
 method:'discard_draft',
 expect:{}
});

function notify(r) {
 ui.addNotification(
  null,
  E('p',{},r.message || 'Selesai'),
  r.ok ? 'info' : 'error'
 );
}

function badge(ok, yes, no) {
 return E('span', {
  class: 'tr-badge ' + (ok ? 'tr-ok' : 'tr-bad')
 }, ok ? yes : no);
}

function item(title, enabled, detail) {
 return E('div', { class: 'tr-item' }, [
  E('div', {}, [
   E('strong', {}, title),
   detail ? E('div', { class: 'tr-detail' }, detail) : ''
  ]),
  badge(enabled, 'AKTIF', 'MATI')
 ]);
}

function profileCard(profile) {
 return E('div', { class: 'tr-card' }, [
  E('div', { class: 'tr-head' }, [
   E('h3', {}, profile.name),
   badge(profile.config_valid, 'VALID', 'TIDAK VALID')
  ]),
  item('Blokir iklan',
   profile.adblock,
   'geosite:category-ads-all'),
  item('YouTube melalui tunnel',
   profile.youtube_tunnel,
   'YouTube, Googlevideo, YTImg'),
  item('Full Tunnel VPS',
   !profile.http_direct,
   'TCP port 80 tanpa tunnel VPS'),
  item('DNS diarahkan oleh Xray',
   profile.dns_redirect,
   profile.dns_server || '-'),
  E('div', { class: 'tr-summary' }, [
   E('span', {}, 'Strategi: ' + profile.domain_strategy),
   E('span', {}, 'Jumlah rule: ' + profile.rule_count)
  ])
 ]);
}

function globalPanel(data) {
 var d=data.draft_settings || {};
 var ad=d.adblock != null ? d.adblock : data.main.adblock;
 var bq=d.block_quic != null ? d.block_quic : data.quic_blocked;
 var a=E("input",{type:"checkbox"});
 var q=E("input",{type:"checkbox"});
 a.checked=Boolean(ad);
 q.checked=Boolean(bq);
 function save(){return saveDraft(a.checked?"1":"0","1","0",q.checked?"1":"0","","").then(notify);}
 return E("div",{class:"tr-card",style:"margin-top:12px"},[
  E("h3",{},"Pengaturan Global"),
  E("div",{class:"tr-setting"},[E("span",{},"Blokir iklan"),a]),
  E("div",{class:"tr-setting"},[E("span",{},"Blokir QUIC (UDP 443)"),q]),
  E("div",{class:"tr-actions"},[
   E("button",{type:"button",class:"btn cbi-button-action",click:save},"Simpan Draf"),
   E("button",{type:"button",class:"btn",click:function(){return validateDraft().then(notify);}},"Validasi"),
   E("button",{type:"button",class:"btn cbi-button-positive",click:function(){return applyDraft().then(function(r){notify(r);if(r.ok)location.reload();});}},"Terapkan"),
   E("button",{type:"button",class:"btn cbi-button-negative",click:function(){return discardDraft().then(function(r){notify(r);if(r.ok)location.reload();});}},"Batalkan Draf")
  ])
 ]);
}

return view.extend({
 load: function() {
  return Promise.all([status(),youtubeStatus()]).then(function(r){r[0].youtube_policy=r[1];return r[0];});
 },

 render: function(data) {
  return E([], [
   E('style', {}, `
.tr-hero{padding:21px;border-radius:19px;color:#fff;margin-bottom:15px;background:linear-gradient(135deg,#4338ca,#2563eb);box-shadow:0 11px 28px rgba(0,0,0,.2)}
.tr-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:13px}
.tr-card{padding:18px;border:1px solid rgba(127,127,127,.25);border-radius:17px;background:linear-gradient(145deg,rgba(127,127,127,.09),rgba(127,127,127,.02));box-shadow:0 6px 18px rgba(0,0,0,.09)}
.tr-card h3{margin:0;font-size:19px}
.tr-head,.tr-item,.tr-summary{display:flex;justify-content:space-between;gap:12px;align-items:center}
.tr-item{padding:12px 0;border-bottom:1px solid rgba(127,127,127,.15)}
.tr-detail{font-size:12px;opacity:.65;margin-top:4px}
.tr-badge{padding:6px 10px;border-radius:999px;color:#fff;font-size:11px;font-weight:800;white-space:nowrap}
.tr-ok{background:#168750}.tr-bad{background:#c53030}
.tr-summary{padding-top:13px;font-size:12px;opacity:.75}
.tr-note{margin-top:13px;padding:13px;border-left:4px solid #3b82f6;background:rgba(59,130,246,.09);border-radius:9px;line-height:1.5}
.tr-setting{display:flex;justify-content:space-between;align-items:center;padding:13px 0;border-bottom:1px solid rgba(127,127,127,.15)}
.tr-setting input{width:24px;height:24px}
.tr-field{display:block;margin-top:14px}.tr-field span{display:block;margin-bottom:6px;font-weight:750}
.tr-field textarea{width:100%;box-sizing:border-box;border-radius:10px}
.tr-draft{margin-top:13px;padding:11px;border-radius:9px;background:rgba(245,158,11,.09)}
.tr-actions{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:9px;margin-top:14px}
.tr-actions .btn{width:100%;border-radius:11px!important;padding:10px!important}
@media(max-width:600px){.tr-grid{grid-template-columns:1fr}.tr-summary{align-items:flex-start;flex-direction:column}.tr-actions{grid-template-columns:1fr}}
`),

   E('h2', {}, 'Aturan Trafik'),

   E('div', { class: 'tr-hero' }, [
    E('div', {
     style: 'font-size:20px;font-weight:700'
    }, data.policy_synced
     ? 'Kebijakan kedua profil selaras'
     : 'Kebijakan profil berbeda'),
    E('div', { style: 'margin-top:5px' },
     'Akun, port, dan limit berbeda; aturan akses tetap sama.')
   ]),
    globalPanel(data),

   E('div', { class: 'tr-card' }, [
    E('div', { class: 'tr-head' }, [
     E('h3', {}, 'Kebijakan Global'),
     badge(
      data.main.config_valid && data.limit5.config_valid,
      '2/2 PROFIL VALID',
      'ADA PROFIL BERMASALAH'
     )
    ]),
    item('Blokir iklan',
     data.main.adblock && data.limit5.adblock,
     'Berlaku untuk semua profil'),
    item('YouTube melalui tunnel',
     data.main.youtube_tunnel && data.limit5.youtube_tunnel,
     'Melalui VPS saat MPTCP aktif'),
    item('Full Tunnel VPS',
     !data.main.http_direct && !data.limit5.http_direct,
     'HTTP, HTTPS, dan trafik umum melalui VPS'),
    item('DNS diarahkan oleh Xray',
     data.main.dns_redirect && data.limit5.dns_redirect,
     'Diteruskan ke Stubby DoT di VPS'),
    E('div', { class: 'tr-summary' }, [
     E('span', {}, 'Strategi: ' + data.main.domain_strategy),
     E('span', {}, 'Kebijakan tersinkronisasi')
    ])
   ]),

   E('div', { class: 'tr-card', style: 'margin-top:12px' }, [
    E('h3', {}, 'Perlindungan Global'),
    item('Blokir QUIC', data.quic_blocked,
     'UDP port 443 diblokir firewall'),
    item('GeoIP tersedia',
     data.geodata && data.geodata.geoip_exists,
     data.geodata ? data.geodata.schedule : ''),
    item('GeoSite tersedia',
     data.geodata && data.geodata.geosite_exists,
     data.geodata ? data.geodata.schedule : '')
   ]),

   E('div', { class: 'tr-card', style: 'margin-top:12px' }, [
    E('h3', {}, 'DNS Terenkripsi'),
    E('div', { class: 'tr-note' },
     'DNS dari tunnel diproses Stubby di VPS, lalu diteruskan ke ' +
     'Cloudflare menggunakan DoT port 853. Status VPS berdasarkan audit terakhir.')
   ])
  ]);
 },

 handleSaveApply: null,
 handleSave: null,
 handleReset: null
});
