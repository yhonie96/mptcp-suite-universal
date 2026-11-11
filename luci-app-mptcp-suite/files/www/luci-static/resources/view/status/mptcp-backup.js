'use strict';
'require view';
'require rpc';
'require ui';

var status = rpc.declare({
 object: 'mptcp-backup',
 method: 'status',
 expect: {}
});

var createBackup = rpc.declare({
 object: 'mptcp-backup',
 method: 'create',
 expect: {}
});

var validateBackup = rpc.declare({
 object: 'mptcp-backup',
 method: 'validate',
 params: [ 'name' ],
 expect: {}
});

var deleteBackup = rpc.declare({
 object: 'mptcp-backup',
 method: 'delete',
 params: [ 'name' ],
 expect: {}
});

var previewRestore = rpc.declare({
 object: 'mptcp-restore',
 method: 'preview',
 params: [ 'name' ],
 expect: {}
});

var restoreSafe = rpc.declare({
 object: 'mptcp-restore',
 method: 'restore_safe',
 params: [ 'name' ],
 expect: {}
});

function notify(result) {
 ui.addNotification(
  null,
  E('p', {}, result.message || 'Selesai'),
  result.ok ? 'info' : 'error'
 );
}

function sizeText(bytes) {
 return Math.max(1, Math.ceil(Number(bytes || 0) / 1024)) + ' KB';
}

function runPreview(name) {
 return previewRestore(name).then(function(result) {
  if (!result.ok) {
   notify(result);
   return;
  }

  ui.showModal('Preview Restore', [
   E('p', {}, result.message),
   E('ul', {}, [
    E('li', {}, 'File UI: ' + result.ui),
    E('li', {}, 'Backend RPC: ' + result.rpc),
    E('li', {}, 'ACL: ' + result.acl),
    E('li', {}, 'Pengaturan BSBF: ' +
     (result.bsbf ? 'tersedia' : 'tidak tersedia')),
    E('li', {}, 'Jaringan: DIKUNCI'),
    E('li', {}, 'Xray aktif: DIKUNCI')
   ]),
   E('div', { class: 'right' }, [
    E('button', {
     class: 'btn cbi-button',
     click: ui.hideModal
    }, 'Tutup')
   ])
  ]);
 });
}

function runRestore(name) {
 if (!confirm(
  'Restore UI dan pengaturan BSBF dari backup ini?\n\n' +
  'Jaringan dan Xray tidak akan diubah.'
 ))
  return;

 if (!confirm(
  'Konfirmasi terakhir.\n\n' +
  'Snapshot kondisi sekarang akan dibuat otomatis. Lanjutkan?'
 ))
  return;

 return restoreSafe(name).then(function(result) {
  notify(result);

  if (result.ok)
   window.setTimeout(function() {
    window.location.reload();
   }, 2500);
 });
}

return view.extend({
 load: function() {
  return status();
 },

 render: function(data) {
  var backups = data.backups || [];

  var cards = backups.map(function(backup) {
   return E('div', { class: 'backup-card' }, [
    E('div', { class: 'backup-name' }, backup.name),

    E('div', { class: 'backup-info' }, [
     E('span', {}, 'Ukuran: ' + sizeText(backup.size)),
     E('span', {},
      'SHA-256: ' + String(backup.checksum).substring(0, 16) + '…')
    ]),

    E('div', { class: 'backup-actions' }, [
     E('button', {
      class: 'btn cbi-button',
      click: function() {
       return validateBackup(backup.name).then(notify);
      }
     }, 'Validasi'),

     E('button', {
      class: 'btn cbi-button',
      click: function() {
       return runPreview(backup.name);
      }
     }, 'Preview'),

     E('button', {
      class: 'btn cbi-button cbi-button-action',
      click: function() {
       return runRestore(backup.name);
      }
     }, 'Restore UI/BSBF'),

     E('button', {
      class: 'btn cbi-button cbi-button-negative',
      click: function() {
       if (!confirm('Hapus backup ' + backup.name + '?'))
        return;

       return deleteBackup(backup.name).then(function(result) {
        notify(result);
        if (result.ok)
         window.location.reload();
       });
      }
     }, 'Hapus')
    ])
   ]);
  });

  return E([], [
   E('style', {}, `
.backup-summary {
 padding:16px;margin-bottom:16px;border-radius:12px;
 color:#fff;background:linear-gradient(135deg,#23395d,#315b8a);
}
.backup-lock {
 padding:12px;margin:12px 0;border-left:5px solid #38a169;
 background:rgba(56,161,105,.10);
}
.backup-card {
 padding:15px;margin:13px 0;border-radius:12px;
 border:1px solid rgba(127,127,127,.25);
 background:var(--background-color-high,#292929);
}
.backup-name {
 font-size:17px;font-weight:700;overflow-wrap:anywhere;
}
.backup-info {
 display:grid;gap:5px;margin:10px 0;opacity:.75;
 overflow-wrap:anywhere;
}
.backup-actions {
 display:grid;grid-template-columns:repeat(2,minmax(0,1fr));
 gap:8px;margin-top:13px;
}
.backup-actions .btn { width:100% }
@media(max-width:480px) {
 .backup-actions { grid-template-columns:1fr }
}
`),

   E('h2', {}, 'Backup & Restore'),

   E('div', { class: 'backup-summary' }, [
    E('div', { style: 'font-size:20px;font-weight:700' },
     backups.length + ' backup tersedia'),
    E('div', { style: 'margin-top:5px' },
     'Backup lokal dilindungi dengan izin file 600.')
   ]),

   E('div', { class: 'backup-lock' }, [
    E('strong', {}, 'Restore Aman'),
    E('div', {},
     'Hanya UI MPTCP dan pengaturan BSBF yang dipulihkan.'),
    E('div', {}, 'Konfigurasi jaringan dan Xray tetap dikunci.')
   ]),

   E('button', {
    class: 'btn cbi-button cbi-button-action',
    click: function() {
     return createBackup().then(function(result) {
      notify(result);
      if (result.ok)
       window.setTimeout(function() {
        window.location.reload();
       }, 900);
     });
    }
   }, 'Buat Backup Terbaru'),

   E('div', {},
    cards.length ? cards : [ E('p', {}, 'Belum ada backup.') ])
  ]);
 },

 handleSaveApply: null,
 handleSave: null,
 handleReset: null
});
