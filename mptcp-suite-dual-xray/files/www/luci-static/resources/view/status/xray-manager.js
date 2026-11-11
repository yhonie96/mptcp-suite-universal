'use strict';
'require view';
'require rpc';
'require ui';

var status = rpc.declare({
object: 'xray-manager',
method: 'status',
expect: {}
});

var testTunnel = rpc.declare({
object: 'xray-manager',
method: 'test_tunnel',
expect: {}
});
var saveDraft = rpc.declare({
object: 'xray-manager',
method: 'save_draft',
params: [
'server', 'port', 'uuid', 'sni',
'reality_password', 'short_id', 'fingerprint'
],
expect: {}
});

var validateDraft = rpc.declare({
object: 'xray-manager',
method: 'validate_draft',
expect: {}
});

var applySafe = rpc.declare({
object: 'xray-manager',
method: 'apply_safe',
expect: {}
});
var discardDraft = rpc.declare({
object: 'xray-manager',
method: 'discard_draft',
expect: {}
});

function input(id, title, type, placeholder) {
return E('label', { class: 'x-field' }, [
E('span', {}, title),
E('input', {
id: id,
type: type || 'text',
value: placeholder || '',
autocomplete: 'off'
})
]);
}

function notify(result) {
ui.addNotification(null, E('p', {}, result.message || 'Selesai'),
result.ok ? 'info' : 'error');
}

return view.extend({
load: function() {
return status();
},

render: function(data) {
var address = String(data.server || '');
var splitAt = address.lastIndexOf(':');
var server = splitAt > 0 ? address.substring(0, splitAt) : address;
var port = splitAt > 0 ? address.substring(splitAt + 1) : '';

return E([], [
E('style', {}, `
.x-summary,.x-card{
padding:16px;border-radius:12px;margin:14px 0;
border:1px solid rgba(255,255,255,.12);
}
.x-summary{background:linear-gradient(135deg,#23395d,#315b8a);color:#fff}
.x-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}
.x-field span{display:block;margin-bottom:5px;opacity:.75}
.x-field input{width:100%;box-sizing:border-box}
.x-actions{display:grid;grid-template-columns:repeat(2,1fr);gap:10px;margin-top:16px}
.x-actions .btn{width:100%;min-width:0;white-space:normal}
@media(max-width:700px){.x-grid,.x-actions{grid-template-columns:1fr}}
.x-note{padding:11px;border-left:5px solid #d69e2e;background:rgba(214,158,46,.1)}
@media(max-width:520px){.x-grid{grid-template-columns:1fr}}
`),

E('h2', {}, 'Kelola Akun Profil'),

E('div', { class: 'x-summary' }, [
E('h3', {}, data.xray ? 'Xray Aktif' : 'Xray Tidak Aktif'),
E('div', {}, 'Tujuan aktif: ' + (data.server || '-')),
E('div', {}, 'SNI: ' + (data.sni || '-')),
E('div', {}, 'Draft: ' + (data.draft ? 'Tersedia' : 'Belum ada'))
]),

E('div', { class: 'x-note' },
'Semua nilai akun aktif ditampilkan. Perubahan dibuat sebagai draft dan tidak langsung diterapkan.'),

E('div', { class: 'x-card' }, [
E('h3', {}, 'Kelola Akun Aktif'),
E('div', { class: 'x-grid' }, [
input('x-server', 'Alamat VPS', 'text', server),
input('x-port', 'Port VPS', 'number', port),
input('x-uuid', 'UUID', 'text', data.uuid || ''),
input('x-sni', 'SNI / Server Name', 'text', data.sni || 'www.cloudflare.com'),
input('x-pass', 'REALITY Password / Public Key', 'text', data.reality_password || ''),
input('x-short', 'Short ID', 'text', data.short_id || ''),
input('x-fp', 'Fingerprint', 'text', data.fingerprint || 'chrome')
]),

E('div', { class: 'x-actions' }, [
E('button', {
class: 'btn cbi-button',
click: function(ev) {
var b = ev.currentTarget;
b.disabled = true;
b.textContent = 'Menguji…';
return testTunnel().then(notify).finally(function() {
b.disabled = false;
b.textContent = 'Uji Tunnel Aktif';
});
}
}, 'Uji Tunnel Aktif'),
E('button', {
class: 'btn cbi-button cbi-button-save',
click: function() {
return saveDraft(
document.getElementById('x-server').value || server,
Number(document.getElementById('x-port').value || port),
document.getElementById('x-uuid').value,
document.getElementById('x-sni').value || data.sni,
document.getElementById('x-pass').value,
document.getElementById('x-short').value,
document.getElementById('x-fp').value || 'chrome'
).then(function(r){notify(r);if(r.ok)setTimeout(function(){window.location.reload();},800);});
}
}, 'Simpan Perubahan'),

E('button', {
class: 'btn cbi-button cbi-button-action',
click: function() {
return validateDraft().then(function(r){notify(r);if(r.ok)setTimeout(function(){window.location.reload();},800);});
}
}, 'Validasi Draft'),

E('button', Object.assign({
class: 'btn cbi-button cbi-button-apply',
click: function() {
if (!confirm(
'Terapkan draft Xray utama?\n\n' +
'Snapshot dan rollback otomatis akan digunakan.'
))
return;
if (!confirm(
'Konfirmasi terakhir. Xray utama akan restart sementara.'
))
return;
return applySafe().then(function(result) {
notify(result);
if (result.ok)
window.setTimeout(function() {
window.location.reload();
}, 2500);
});
}
}, data.draft ? {} : { disabled: 'disabled' }),
'Terapkan Aman'),
E('button', {
class: 'btn cbi-button cbi-button-negative',
click: function() {
if (!confirm('Hapus draft akun Xray?'))
return;
return discardDraft().then(function(r){notify(r);if(r.ok)setTimeout(function(){window.location.reload();},800);});
}
}, 'Hapus Draft')
])
])
]);
},

handleSaveApply: null,
handleSave: null,
handleReset: null
});
