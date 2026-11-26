import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryBoysScreen extends StatefulWidget {
  final String actorRole;
  const DeliveryBoysScreen({super.key, required this.actorRole});

  @override
  State createState() => _DeliveryBoysScreenState();
}

class _DeliveryBoysScreenState extends State {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List _boys = [];
  Map _deliveredCount = {};
  Map _deliveredAmount = {};

  DeliveryBoysScreen get _w => widget as DeliveryBoysScreen;
  bool get _canManage =>
      _w.actorRole.toLowerCase() == 'owner' ||
      _w.actorRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future _loadData() async {
    setState(() => _loading = true);
    try {
      final boysRes = await _supabase
          .from('deua_staff_accounts')
          .select()
          .eq('role', 'delivery_boy')
          .order('created_at', ascending: false);

      final ordersRes = await _supabase
          .from('deua_orders')
          .select('delivery_boy_id, status, total_amount');

      final Map countMap = {};
      final Map amtMap = {};

      for (final o in List.from(ordersRes as List)) {
        final row = Map.from(o as Map);
        final boyId = (row['delivery_boy_id'] ?? '').toString();
        if (boyId.isNotEmpty && row['status'] == 'Delivered') {
          countMap[boyId] = (countMap[boyId] ?? 0) + 1;
          final val =
              num.tryParse((row['total_amount'] ?? '0').toString()) ?? 0;
          amtMap[boyId] = (amtMap[boyId] ?? 0) + val;
        }
      }

      if (!mounted) return;
      setState(() {
        _boys = List.from(boysRes as List);
        _deliveredCount = countMap;
        _deliveredAmount = amtMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Load error: $e', isError: true);
    }
  }

  Future _openFormDialog({Map? existing}) async {
    if (!_canManage) {
      _showSnack('Sirf Owner ya Admin add/edit kar sakte hain.',
          isError: true);
      return;
    }

    final ex = existing != null ? Map.from(existing) : null;
    final nameCtrl = TextEditingController(text: ex?['name']?.toString() ?? '');
    final phoneCtrl =
        TextEditingController(text: ex?['phone']?.toString() ?? '');
    final loginCtrl =
        TextEditingController(text: ex?['login_id']?.toString() ?? '');
    final passCtrl =
        TextEditingController(text: ex?['password']?.toString() ?? '');
    bool isActive = ex == null ? true : (ex['is_active'] == true);
    bool isOnDuty = ex == null ? false : (ex['is_on_duty'] == true);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDlg) => AlertDialog(
          title: Text(
            ex == null ? 'नया Delivery Boy जोड़ें' : 'Delivery Boy अपडेट करें',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'नाम',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'फ़ोन नंबर',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: loginCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Login ID (उदा: boy_ramesh)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Account Active',
                      style: TextStyle(fontSize: 13)),
                  value: isActive,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setDlg(() => isActive = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('On Duty', style: TextStyle(fontSize: 13)),
                  value: isOnDuty,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setDlg(() => isOnDuty = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B7A2B),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final loginId = loginCtrl.text.trim().toLowerCase();
                final pass = passCtrl.text.trim();

                if (name.isEmpty || loginId.isEmpty || pass.isEmpty) {
                  _showSnack('नाम, Login ID और Password भरें।', isError: true);
                  return;
                }

                try {
                  final id = ex != null
                      ? ex['id'].toString()
                      : 'boy_${DateTime.now().millisecondsSinceEpoch}';

                  final payload = {
                    'id': id,
                    'name': name,
                    'phone': phone,
                    'login_id': loginId,
                    'email': ex?['email'] ?? '$loginId@deuafresh.local',
                    'password': pass,
                    'role': 'delivery_boy',
                    'is_active': isActive,
                    'is_on_duty': isOnDuty,
                    'reset_requested': false,
                  };

                  if (ex == null) {
                    await _supabase
                        .from('deua_staff_accounts')
                        .insert(payload);
                    _showSnack('नया Delivery Boy जुड़ गया!');
                  } else {
                    await _supabase
                        .from('deua_staff_accounts')
                        .update(payload)
                        .eq('id', ex['id']);
                    _showSnack('Delivery Boy डेटा अपडेट हो गया!');
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData();
                } catch (e) {
                  _showSnack('Save error: $e', isError: true);
                }
              },
              child: const Text('Save करें'),
            ),
          ],
        ),
      ),
    );
  }

  Future _removeBoy(Map boy) async {
    if (!_canManage) {
      _showSnack('Sirf Owner ya Admin hata sakte hain.', isError: true);
      return;
    }

    final b = Map.from(boy);
    final name = b['name']?.toString() ?? 'Delivery Boy';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name को हटाएं',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '• Disable: अकाउंट बंद होगा (पुराने ऑर्डर सुरक्षित रहेंगे)।\n'
          '• Delete: अकाउंट हमेशा के लिए हट जाएगा।',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करें'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabase.from('deua_staff_accounts').update({
                  'is_active': false,
                  'is_on_duty': false,
                }).eq('id', b['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnack('$name का अकाउंट बंद कर दिया गया।');
                await _loadData();
              } catch (e) {
                _showSnack('Disable error: $e', isError: true);
              }
            },
            child: const Text('Disable करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _supabase
                    .from('deua_staff_accounts')
                    .delete()
                    .eq('id', b['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnack('$name हट गया।');
                await _loadData();
              } catch (e) {
                _showSnack('Delete error: $e', isError: true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF1B7A2B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B7A2B),
        foregroundColor: Colors.white,
        title: Text('Delivery Boys (${_boys.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1B7A2B),
              foregroundColor: Colors.white,
              onPressed: () => _openFormDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Boy'),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B7A2B)))
          : _boys.isEmpty
              ? const Center(child: Text('अभी कोई Delivery Boy नहीं है।'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
                    itemCount: _boys.length,
                    itemBuilder: (_, i) {
                      final b = Map.from(_boys[i] as Map);
                      final id = b['id'].toString();
                      final active = b['is_active'] == true;
                      final duty = b['is_on_duty'] == true;
                      final resetReq = b['reset_requested'] == true;
                      final cnt = _deliveredCount[id] ?? 0;
                      final amt = _deliveredAmount[id] ?? 0;

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${b['name']} (${b['login_id'] ?? '-'})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      !active
                                          ? 'DISABLED'
                                          : (duty ? 'ON DUTY' : 'OFF DUTY'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: !active
                                        ? Colors.red.shade50
                                        : (duty
                                            ? const Color(0xFFE8F5E9)
                                            : Colors.grey.shade200),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'फ़ोन: ${b['phone'] ?? '-'} • पासवर्ड: ${b['password'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Delivered: $cnt • राशि: ₹$amt',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B7A2B)),
                              ),
                              if (resetReq) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Password Reset Request आई है — Edit करके नया पासवर्ड सेट करें',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900),
                                ),
                              ],
                              if (_canManage) ...[
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openFormDialog(existing: b),
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red.shade700),
                                      onPressed: () => _removeBoy(b),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                      label: const Text('हटाएं'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
