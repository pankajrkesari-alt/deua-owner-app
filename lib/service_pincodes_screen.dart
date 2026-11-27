import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicePincodesScreen extends StatefulWidget {
  final String actorRole;
  const ServicePincodesScreen({super.key, required this.actorRole});

  @override
  State createState() => _ServicePincodesScreenState();
}

class _ServicePincodesScreenState extends State {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  List _pincodes = [];

  ServicePincodesScreen get _w => widget as ServicePincodesScreen;
  bool get _canManage =>
      _w.actorRole.toLowerCase() == 'owner' ||
      _w.actorRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _loadPincodes();
  }

  Future _loadPincodes() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('deua_service_pincodes')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _pincodes = List.from(res as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Pin code load error: $e', isError: true);
    }
  }

  Future _openAddPinDialog() async {
    if (!_canManage) {
      _showSnack('Sirf Owner ya Admin pin code add kar sakte hain.',
          isError: true);
      return;
    }

    final pinCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    bool isActive = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDlg) => AlertDialog(
          title: const Text(
            'नया Delivery Pin Code जोड़ें',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Pin Code (6 अंक)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'एरिया / लोकेशन नाम (वैकल्पिक)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('अभी Active रखें',
                    style: TextStyle(fontSize: 13)),
                value: isActive,
                activeColor: const Color(0xFF1B7A2B),
                onChanged: (v) => setDlg(() => isActive = v),
              ),
            ],
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
                final pin = pinCtrl.text.trim();
                final area = areaCtrl.text.trim();

                if (pin.length != 6 || int.tryParse(pin) == null) {
                  _showSnack('सही 6 अंकों का Pin Code डालें।', isError: true);
                  return;
                }

                try {
                  await _supabase.from('deua_service_pincodes').upsert({
                    'pincode': pin,
                    'area_name': area.isEmpty ? null : area,
                    'is_active': isActive,
                  }, onConflict: 'pincode');

                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnack('Pin code $pin सेव हो गया!');
                  await _loadPincodes();
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

  Future _togglePin(Map row, bool value) async {
    if (!_canManage) {
      _showSnack('Sirf Owner ya Admin status badal sakte hain.', isError: true);
      return;
    }

    final id = row['id'];
    final pin = row['pincode']?.toString() ?? '';

    try {
      await _supabase
          .from('deua_service_pincodes')
          .update({'is_active': value}).eq('id', id);

      if (!mounted) return;
      await _loadPincodes();
      _showSnack(
        value
            ? 'Pin code $pin Delivery के लिए Active हो गया।'
            : 'Pin code $pin Delivery के लिए बंद कर दिया गया।',
      );
    } catch (e) {
      _showSnack('Update error: $e', isError: true);
    }
  }

  Future _deletePin(Map row) async {
    if (!_canManage) return;

    final id = row['id'];
    final pin = row['pincode']?.toString() ?? '';

    try {
      await _supabase.from('deua_service_pincodes').delete().eq('id', id);
      _showSnack('Pin code $pin हट गया।');
      await _loadPincodes();
    } catch (e) {
      _showSnack('Delete error: $e', isError: true);
    }
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
        title: Text('Delivery Pin Codes (${_pincodes.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPincodes),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1B7A2B),
              foregroundColor: Colors.white,
              onPressed: _openAddPinDialog,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add Pin'),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B7A2B)),
            )
          : _pincodes.isEmpty
              ? const Center(
                  child: Text('अभी कोई Pin Code नहीं जुड़ा है। Add Pin दबाएं।'),
                )
              : RefreshIndicator(
                  onRefresh: _loadPincodes,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
                    itemCount: _pincodes.length,
                    itemBuilder: (_, i) {
                      final row = Map.from(_pincodes[i] as Map);
                      final pin = row['pincode']?.toString() ?? '';
                      final area = (row['area_name'] ?? '').toString().trim();
                      final active = row['is_active'] == true;

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: active
                                ? const Color(0xFFE8F5E9)
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.pin_drop,
                              color: active
                                  ? const Color(0xFF1B7A2B)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          title: Text(
                            pin,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${area.isEmpty ? 'Service Area' : area} • ${active ? 'ACTIVE' : 'INACTIVE'}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: active
                                  ? const Color(0xFF1B7A2B)
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: active,
                                activeColor: const Color(0xFF1B7A2B),
                                onChanged: _canManage
                                    ? (v) => _togglePin(row, v)
                                    : null,
                              ),
                              if (_canManage)
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: Colors.red.shade700),
                                  onPressed: () => _deletePin(row),
                                ),
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
