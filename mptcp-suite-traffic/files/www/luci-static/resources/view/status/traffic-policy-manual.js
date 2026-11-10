'use strict';
'require view';
'require form';
'require rpc';
'require ui';

var applyManual = rpc.declare({
 object: 'mptcp-suite-traffic',
 method: 'apply',
 expect: {}
});

return view.extend({
 render: function() {
  var m = new form.Map('traffic_policy', 'Aturan Jalur Manual',
   'Domain dan IPv4/CIDR diarahkan melalui WWAN.');
  this.map = m;

  var s = m.section(form.GridSection, 'rule', 'Daftar Aturan');
  s.anonymous = false;
  s.addremove = true;
  s.sortable = true;

  var o = s.option(form.Flag, 'enabled', 'Aktif');
  o.default = '1'; o.rmempty = false;

  o = s.option(form.Value, 'name', 'Nama');
  o.rmempty = false;

  o = s.option(form.ListValue, 'target', 'Jalur');
  o.value('wwan', 'Secondary / WWAN');
  o.value('default', 'Default / WAN1');
  o.default = 'wwan'; o.rmempty = false;

  o = s.option(form.DynamicList, 'domain', 'Domain');
  o.datatype = 'hostname';

  o = s.option(form.DynamicList, 'ipv4', 'IPv4 / CIDR');

  return m.render();
 },

 handleSaveApply: function() {
  return this.map.save()
   .then(function() { return ui.changes.apply(false); })
   .then(function() { return applyManual(); })
   .then(function(r) {
    ui.addNotification(null, E('p', {}, r.message || 'Selesai'),
     r.ok ? 'info' : 'error');
    if (!r.ok) throw new Error(r.message || 'Penerapan gagal');
   });
 },

 handleSave: function() {
  return this.map.save();
 },

 handleReset: function() {
  var self = this;
  return ui.changes.revert()
   .then(function() { return self.map.reset(); })
   .then(function() { window.location.reload(); });
 }
});
