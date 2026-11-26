import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kOwnerRecoveryKey = 'Deua199800';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cvbubouqkoladwhemzcf.supabase.co',
    anonKey: 'sb_publishable_gSYtFINdgJzEQwYLJ9M8pg_zxMs6SK5',
  );
  runApp(const DeuaOwnerApp());
}

class DeuaOwnerApp extends StatelessWidget {
  const DeuaOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEUA FRESH Owner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7A2B),
          primary: const Color(0xFF1B7A2B),
        ),
      ),
      home: const AuthGateScreen(),
    );
  }
}

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State {
  final _supabase = Supabase.instance.client;
  bool _checking = true;
  Map? _activeUser;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('logged_in_user_id') ?? '';
      if (savedId.isNotEmpty) {
        final rows = await _supabase
            .from('deua_staff_accounts')
            .select()
            .eq('id', savedId);
        final list = List.from(rows as List);
        if (list.isNotEmpty) {
          final acc = Map.from(list.first as Map);
          if (acc['is_active'] == true) {
            if (!mounted) return;
            setState(() {
              _activeUser = acc;
              _checking = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _checking = false);
  }

  Future _onLoggedIn(Map user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logged_in_user_id', user['id'].toString());
    if (!mounted) return;
    setState(() => _activeUser = user);
  }

  Future _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    if (!mounted) return;
    setState(() => _activeUser = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B7A2B))),
      );
    }
    if (_activeUser == null) {
      return LoginScreen(onSuccess: _onLoggedIn);
    }
    return OwnerDashboardScreen(
      currentUser: _activeUser!,
      onLogout: _onLogout,
      onUserUpdated: (u) => setState(() => _activeUser = u),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Future Function(Map user) onSuccess;
  const LoginScreen({super.key, required this.onSuccess});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State {
  final _supabase = Supabase.instance.client;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  Future _login() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'कृपया Gmail ID और Password दोनों डालें।');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _supabase
          .from('deua_staff_accounts')
          .select()
          .eq('email', email);
      final list = List.from(rows as List);
      if (list.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'यह Gmail ID रजिस्टर्ड नहीं है।';
        });
        return;
      }

      final acc = Map.from(list.first as Map);
      if (acc['is_active'] != true) {
        setState(() {
          _loading = false;
          _error = 'आपका अकाउंट अभी बंद (Inactive) है। Owner से संपर्क करें।';
        });
        return;
      }

      if (acc['password'].toString() != pass) {
        setState(() {
          _loading = false;
          _error = 'गलत Password! सही Password डालें या Forgot Password का उपयोग करें।';
        });
        return;
      }

      await widget.onSuccess(acc);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Login error: $e';
      });
    }
  }

  void _openForgotPasswordDialog() {
    final fEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final fKeyCtrl = TextEditingController();
    final fNewPassCtrl = TextEditingController();
    bool busy = false;
    String? infoMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dCtx, setDlg) => AlertDialog(
          title: const Text('Forgot Password • पासवर्ड रीसेट', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• Admin: अपनी Gmail ID डालकर Owner को Reset Request भेजें।\n'
                  '• Owner: Recovery Key डालकर नया Password तुरंत सेट करें।',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Gmail ID', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fKeyCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Owner Recovery Key (सिर्फ Owner के लिए)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fNewPassCtrl,
                  decoration: const InputDecoration(
                    labelText: 'नया Password (सिर्फ Owner के लिए)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (infoMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(infoMsg!, style: const TextStyle(fontSize: 12, color: Color(0xFF1B7A2B), fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('बंद करें')),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      final em = fEmailCtrl.text.trim().toLowerCase();
                      if (em.isEmpty) {
                        setDlg(() => infoMsg = 'पहले Gmail ID डालें।');
                        return;
                      }
                      setDlg(() => busy = true);
                      try {
                        final rows = await _supabase.from('deua_staff_accounts').select().eq('email', em);
                        final list = List.from(rows as List);
                        if (list.isEmpty) {
                          setDlg(() {
                            busy = false;
                            infoMsg = 'यह Gmail ID नहीं मिली।';
                          });
                          return;
                        }
                        await _supabase
                            .from('deua_staff_accounts')
                            .update({'reset_requested': true})
                            .eq('email', em);
                        setDlg(() {
                          busy = false;
                          infoMsg = 'Owner को Reset Request भेज दी गई है। Owner नया Password जनरेट करेंगे।';
                        });
                      } catch (_) {
                        setDlg(() {
                          busy = false;
                          infoMsg = 'Request भेजने में समस्या आई।';
                        });
                      }
                    },
              child: const Text('Admin Request'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
              onPressed: busy
                  ? null
                  : () async {
                      final em = fEmailCtrl.text.trim().toLowerCase();
                      final key = fKeyCtrl.text.trim();
                      final np = fNewPassCtrl.text.trim();
                      if (em.isEmpty || key != kOwnerRecoveryKey || np.length < 4) {
                        setDlg(() => infoMsg = 'सही Gmail ID, Owner Recovery Key और कम से कम 4 अक्षर का नया Password डालें।');
                        return;
                      }
                      setDlg(() => busy = true);
                      try {
                        final rows = await _supabase
                            .from('deua_staff_accounts')
                            .select()
                            .eq('email', em)
                            .eq('role', 'owner');
                        if ((rows as List).isEmpty) {
                          setDlg(() {
                            busy = false;
                            infoMsg = 'यह Owner Gmail ID नहीं है।';
                          });
                          return;
                        }
                        await _supabase
                            .from('deua_staff_accounts')
                            .update({'password': np, 'reset_requested': false})
                            .eq('email', em);
                        _emailCtrl.text = em;
                        _passCtrl.text = np;
                        setDlg(() {
                          busy = false;
                          infoMsg = 'Owner Password बदल गया! अब Login करें।';
                        });
                      } catch (_) {
                        setDlg(() {
                          busy = false;
                          infoMsg = 'Password अपडेट नहीं हो पाया।';
                        });
                      }
                    },
              child: const Text('Owner Reset'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.lock, color: Color(0xFF1B7A2B), size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('DEUA FRESH OWNER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B7A2B))),
                  const Text('Login Required • लॉगिन ज़रूरी', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('बिना ID और Password के ऐप नहीं खुलेगा', style: TextStyle(fontSize: 12.5, color: Colors.black54)),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Gmail ID (उदा: name@gmail.com)',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openForgotPasswordDialog,
                      child: const Text('Forgot Password? • पासवर्ड भूल गए?', style: TextStyle(color: Color(0xFF1B7A2B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                      onPressed: _loading ? null : _login,
                      child: Text(_loading ? 'जांच हो रही है...' : 'Login • लॉगिन करें', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OwnerDashboardScreen extends StatefulWidget {
  final Map currentUser;
  final Future Function() onLogout;
  final void Function(Map updatedUser) onUserUpdated;

  const OwnerDashboardScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    required this.onUserUpdated,
  });

  @override
  State createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State {
  final _supabase = Supabase.instance.client;
  int _tabIndex = 0;
  bool _loading = true;

  List _orders = [];
  List _products = [];
  List _categories = [];
  List _staffList = [];

  String _orderFilter = 'All';
  String _selectedProductCat = 'all';
  String _productSearch = '';
  final _searchCtrl = TextEditingController();

  bool get _isOwner => widget.currentUser['role'].toString() == 'owner';
  bool get _canOrders => _isOwner || widget.currentUser['can_orders'] == true;
  bool get _canProducts => _isOwner || widget.currentUser['can_products'] == true;
  bool get _canCategories => _isOwner || widget.currentUser['can_categories'] == true;
  bool get _canHisab => _isOwner || widget.currentUser['can_hisab'] == true;

  List> _allowedTabs() {
    final List> tabs = [];
    if (_canOrders) {
      tabs.add({'key': 'orders', 'title': 'लाइव ऑर्डर • Live Orders', 'label': 'Orders', 'icon': Icons.receipt_long});
    }
    if (_canProducts) {
      tabs.add({'key': 'products', 'title': 'सामान व रेट • Products', 'label': 'Products', 'icon': Icons.inventory_2});
    }
    if (_canCategories) {
      tabs.add({'key': 'categories', 'title': 'सभी श्रेणियां • Categories', 'label': 'Categories', 'icon': Icons.category});
    }
    if (_canHisab) {
      tabs.add({'key': 'hisab', 'title': 'दुकान हिसाब • Shop Summary', 'label': 'Hisab', 'icon': Icons.bar_chart});
    }
    if (_isOwner) {
      tabs.add({'key': 'staff', 'title': 'एडमिन व एक्सेस • Admins', 'label': 'Admins', 'icon': Icons.admin_panel_settings});
    }
    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future _loadAllData() async {
    setState(() => _loading = true);
    String? err;

    try {
      final meRows = await _supabase
          .from('deua_staff_accounts')
          .select()
          .eq('id', widget.currentUser['id'].toString());
      final meList = List.from(meRows as List);
      if (meList.isNotEmpty) {
        final freshMe = Map.from(meList.first as Map);
        if (freshMe['is_active'] != true) {
          await widget.onLogout();
          return;
        }
        widget.onUserUpdated(freshMe);
      }
    } catch (_) {}

    if (_canOrders) {
      try {
        final ordRes = await _supabase.from('deua_orders').select().order('created_at', ascending: false);
        _orders = List.from(ordRes as List);
      } catch (e) {
        err ??= 'Orders error: $e';
      }
    }

    if (_canCategories || _canProducts || _canHisab) {
      try {
        final catRes = await _supabase.from('deua_main_categories').select().order('sort_order');
        _categories = List.from(catRes as List);
      } catch (e) {
        err ??= 'Categories error: $e';
      }
      try {
        final prodRes = await _supabase.from('deua_products').select().order('created_at', ascending: false);
        _products = List.from(prodRes as List);
      } catch (e) {
        err ??= 'Products error: $e';
      }
    }

    if (_isOwner) {
      try {
        final stRes = await _supabase.from('deua_staff_accounts').select().order('created_at');
        _staffList = List.from(stRes as List);
      } catch (e) {
        err ??= 'Admins error: $e';
      }
    }

    if (!mounted) return;
    final maxIdx = _allowedTabs().isEmpty ? 0 : _allowedTabs().length - 1;
    setState(() {
      if (_tabIndex > maxIdx) _tabIndex = 0;
      _loading = false;
    });
    if (err != null) _showMsg(err, isError: true);
  }

  void _showMsg(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1B7A2B),
      ),
    );
  }

  Widget _netImg(String? url, {double width = 52, double height = 52}) {
    final clean = (url ?? '').trim();
    if (clean.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B)),
      );
    }
    return Image.network(
      clean,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFE8F5E9),
        child: const Icon(Icons.eco, color: Color(0xFF1B7A2B)),
      ),
    );
  }

  String _categoryLabel(String catId) {
    for (final item in _categories) {
      final c = Map.from(item as Map);
      if (c['id'].toString() == catId) {
        final h = (c['hindi_name'] ?? '').toString();
        final e = (c['name'] ?? '').toString();
        return h.isNotEmpty ? '$h ($e)' : e;
      }
    }
    return catId;
  }

  String _randomPassword() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final code = (ms % 8999) + 1000;
    return 'Deua@$code';
  }

  void _openAdminForm({Map? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existing?['email']?.toString() ?? '');
    final passCtrl = TextEditingController(
      text: existing?['password']?.toString() ?? _randomPassword(),
    );

    bool active = existing?['is_active'] ?? true;
    bool canOrders = existing?['can_orders'] ?? true;
    bool canProducts = existing?['can_products'] ?? false;
    bool canCategories = existing?['can_categories'] ?? false;
    bool canHisab = existing?['can_hisab'] ?? false;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (mCtx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(mCtx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Admin Access बदलें' : 'नया Admin जोड़ें + ID/Password बनाएं',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Admin का नाम', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  enabled: !isEdit,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Admin Gmail ID (Login ID)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: passCtrl,
                        decoration: const InputDecoration(labelText: 'Login Password', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setModal(() => passCtrl.text = _randomPassword()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('New Pass'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Account Active (Login की अनुमति)'),
                  value: active,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setModal(() => active = v),
                ),
                const Divider(),
                const Text('किस चीज़ का Access देना है (Owner तय करेगा):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Orders Access (ऑर्डर देखना व status बदलना)'),
                  value: canOrders,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setModal(() => canOrders = v),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Products Access (सामान जोड़ना, rate व stock बदलना)'),
                  value: canProducts,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setModal(() => canProducts = v),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Categories Access (श्रेणी जोड़ना व बदलना)'),
                  value: canCategories,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setModal(() => canCategories = v),
                ),
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hisab / Sales Access (बिक्री व रिपोर्ट देखना)'),
                  value: canHisab,
                  activeColor: const Color(0xFF1B7A2B),
                  onChanged: (v) => setModal(() => canHisab = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                    onPressed: saving
                        ? null
                        : () async {
                            final nm = nameCtrl.text.trim();
                            final em = emailCtrl.text.trim().toLowerCase();
                            final pw = passCtrl.text.trim();
                            if (nm.isEmpty || !em.contains('@') || pw.length < 4) {
                              _showMsg('नाम, सही Gmail ID और कम से कम 4 अक्षर का Password डालें।', isError: true);
                              return;
                            }
                            setModal(() => saving = true);
                            try {
                              final id = isEdit
                                  ? existing['id'].toString()
                                  : 'admin_${DateTime.now().millisecondsSinceEpoch}';
                              await _supabase.from('deua_staff_accounts').upsert({
                                'id': id,
                                'name': nm,
                                'email': em,
                                'password': pw,
                                'role': 'admin',
                                'is_active': active,
                                'can_orders': canOrders,
                                'can_products': canProducts,
                                'can_categories': canCategories,
                                'can_hisab': canHisab,
                                'reset_requested': false,
                              });
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              await _loadAllData();
                              _showMsg('Admin ID: $em | Pass: $pw save ho gaya!');
                            } catch (e) {
                              setModal(() => saving = false);
                              _showMsg('Admin save error: $e', isError: true);
                            }
                          },
                    child: Text(saving ? 'सेव हो रहा है...' : 'Save Admin & Access', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staffTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 84),
          itemCount: _staffList.length,
          itemBuilder: (_, i) {
            final st = Map.from(_staffList[i] as Map);
            final isMainOwner = st['role'].toString() == 'owner';
            final reqReset = st['reset_requested'] == true;
            final List<String> perms = [];
            if (st['can_orders'] == true) perms.add('Orders');
            if (st['can_products'] == true) perms.add('Products');
            if (st['can_categories'] == true) perms.add('Categories');
            if (st['can_hisab'] == true) perms.add('Hisab');

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(st['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMainOwner ? const Color(0xFFE8F5E9) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isMainOwner ? 'OWNER' : (st['is_active'] == true ? 'ADMIN' : 'BLOCKED'),
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isMainOwner ? const Color(0xFF1B7A2B) : Colors.blue.shade800),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${st['email']}'),
                    Text('Password: ${st['password']}', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                    Text('Access: ${perms.isEmpty ? "None" : perms.join(", ")}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B7A2B))),
                    if (reqReset && !isMainOwner)
                      const Text('⚠ Forgot Password Request aayi hai! Edit dabayein.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ],
                ),
                trailing: isMainOwner
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF1B7A2B)),
                            onPressed: () => _openAdminForm(existing: st),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              await _supabase.from('deua_staff_accounts').delete().eq('id', st['id']);
                              await _loadAllData();
                              _showMsg('Admin account hata diya gaya.');
                            },
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B7A2B),
        foregroundColor: Colors.white,
        onPressed: () => _openAdminForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('नया Admin + ID/Pass', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future _updateOrderStatus(dynamic orderId, String newStatus) async {
    try {
      await _supabase.from('deua_orders').update({'status': newStatus}).eq('id', orderId);
      await _loadAllData();
      _showMsg('Order status "$newStatus" kar diya gaya.');
    } catch (e) {
      _showMsg('Status error: $e', isError: true);
    }
  }

  Future _toggleProductStock(String prodId, bool newValue) async {
    try {
      await _supabase.from('deua_products').update({'in_stock': newValue}).eq('id', prodId);
      await _loadAllData();
      _showMsg(newValue ? 'Saman In Stock kar diya gaya.' : 'Saman Out of Stock kar diya gaya.');
    } catch (e) {
      _showMsg('Stock error: $e', isError: true);
    }
  }

  void _openProductForm({Map? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final imgCtrl = TextEditingController(text: existing?['image_url']?.toString() ?? '');
    final discCtrl = TextEditingController(text: (existing?['discount_percent'] ?? 10).toString());

    String selectedCat = existing?['main_category_id']?.toString() ??
        (_categories.isNotEmpty ? Map.from(_categories.first as Map)['id'].toString() : 'fruits');

    final existingPacks = existing?['packs'] is List ? List.from(existing!['packs'] as List) : [];
    final p1 = existingPacks.isNotEmpty ? Map.from(existingPacks[0] as Map) : {};
    final p2 = existingPacks.length > 1 ? Map.from(existingPacks[1] as Map) : {};

    final p1LabelCtrl = TextEditingController(text: p1['label']?.toString() ?? '500g');
    final p1PriceCtrl = TextEditingController(text: p1['price']?.toString() ?? '');
    final p1MrpCtrl = TextEditingController(text: p1['mrp']?.toString() ?? '');

    final p2LabelCtrl = TextEditingController(text: p2['label']?.toString() ?? '1kg');
    final p2PriceCtrl = TextEditingController(text: p2['price']?.toString() ?? '');
    final p2MrpCtrl = TextEditingController(text: p2['mrp']?.toString() ?? '');

    bool saving = false;
    final bool hasValidCat = _categories.any((c) => Map.from(c as Map)['id'].toString() == selectedCat);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (mCtx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(mCtx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? 'सामान बदलें • Edit Product' : 'नया सामान जोड़ें • Add Product', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    if (isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await _supabase.from('deua_products').delete().eq('id', existing['id']);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          await _loadAllData();
                          _showMsg('Saman delete kar diya gaya.');
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  value: hasValidCat ? selectedCat : null,
                  decoration: const InputDecoration(labelText: 'श्रेणी चुनें (Select Category)', border: OutlineInputBorder(), isDense: true),
                  items: _categories.map((item) {
                    final c = Map.from(item as Map);
                    final id = c['id'].toString();
                    return DropdownMenuItem(value: id, child: Text(_categoryLabel(id)));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setModal(() => selectedCat = v.toString());
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'सामान का नाम • Hindi + English', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imgCtrl,
                        onChanged: (_) => setModal(() {}),
                        decoration: const InputDecoration(labelText: 'Real Photo URL (https://...)', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: _netImg(imgCtrl.text, width: 48, height: 48)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: discCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'छूट % (Discount %)', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                const Text('Pack 1 (ज़रूरी • Required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: TextField(controller: p1LabelCtrl, decoration: const InputDecoration(labelText: 'Size', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 6),
                    Expanded(child: TextField(controller: p1PriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate ₹', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 6),
                    Expanded(child: TextField(controller: p1MrpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP ₹', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Pack 2 (वैकल्पिक • Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: TextField(controller: p2LabelCtrl, decoration: const InputDecoration(labelText: 'Size', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 6),
                    Expanded(child: TextField(controller: p2PriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate ₹', border: OutlineInputBorder(), isDense: true))),
                    const SizedBox(width: 6),
                    Expanded(child: TextField(controller: p2MrpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP ₹', border: OutlineInputBorder(), isDense: true))),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final p1Price = double.tryParse(p1PriceCtrl.text.trim()) ?? 0;
                            if (name.isEmpty || p1Price <= 0) {
                              _showMsg('नाम और सही rate ज़रूर भरें।', isError: true);
                              return;
                            }
                            final p1Mrp = double.tryParse(p1MrpCtrl.text.trim()) ?? p1Price;
                            final List packsList = [
                              {
                                'label': p1LabelCtrl.text.trim().isEmpty ? '1 pack' : p1LabelCtrl.text.trim(),
                                'price': p1Price,
                                'mrp': p1Mrp < p1Price ? p1Price : p1Mrp,
                              }
                            ];
                            final p2Price = double.tryParse(p2PriceCtrl.text.trim()) ?? 0;
                            if (p2LabelCtrl.text.trim().isNotEmpty && p2Price > 0) {
                              final p2Mrp = double.tryParse(p2MrpCtrl.text.trim()) ?? p2Price;
                              packsList.add({
                                'label': p2LabelCtrl.text.trim(),
                                'price': p2Price,
                                'mrp': p2Mrp < p2Price ? p2Price : p2Mrp,
                              });
                            }
                            setModal(() => saving = true);
                            try {
                              final id = isEdit ? existing['id'].toString() : 'prod_${DateTime.now().millisecondsSinceEpoch}';
                              await _supabase.from('deua_products').upsert({
                                'id': id,
                                'main_category_id': selectedCat,
                                'sub_category_id': 'sub_$selectedCat',
                                'name': name,
                                'discount_percent': int.tryParse(discCtrl.text.trim()) ?? 0,
                                'image_url': imgCtrl.text.trim(),
                                'fallback_emoji': '',
                                'card_bg': existing?['card_bg']?.toString() ?? '#F1F8E9',
                                'packs': packsList,
                                'in_stock': existing?['in_stock'] ?? true,
                              });
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              await _loadAllData();
                              _showMsg(isEdit ? 'Saman update ho gaya!' : 'Naya saman jud gaya!');
                            } catch (e) {
                              setModal(() => saving = false);
                              _showMsg('Save error: $e', isError: true);
                            }
                          },
                    child: Text(saving ? 'सेव हो रहा है...' : 'सेव करें • Save Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCategoryForm({Map? existing}) {
    final isEdit = existing != null;
    final hindiCtrl = TextEditingController(text: existing?['hindi_name']?.toString() ?? '');
    final engCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final imgCtrl = TextEditingController(text: existing?['image_url']?.toString() ?? '');
    final sortCtrl = TextEditingController(text: (existing?['sort_order'] ?? (_categories.length + 1)).toString());
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (mCtx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(mCtx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'श्रेणी बदलें • Edit Category' : 'नई श्रेणी जोड़ें • Add Category', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: hindiCtrl, decoration: const InputDecoration(labelText: 'हिंदी नाम • Hindi Name', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                TextField(controller: engCtrl, decoration: const InputDecoration(labelText: 'English Name', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imgCtrl,
                        onChanged: (_) => setModal(() {}),
                        decoration: const InputDecoration(labelText: 'Real Photo URL (https://...)', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: _netImg(imgCtrl.text, width: 48, height: 48)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: sortCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'क्रम संख्या (Sort Order)', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7A2B), foregroundColor: Colors.white),
                    onPressed: saving
                        ? null
                        : () async {
                            final hName = hindiCtrl.text.trim();
                            final eName = engCtrl.text.trim();
                            if (hName.isEmpty || eName.isEmpty) {
                              _showMsg('Hindi aur English dono naam bharein.', isError: true);
                              return;
                            }
                            setModal(() => saving = true);
                            try {
                              final id = isEdit ? existing['id'].toString() : 'cat_${DateTime.now().millisecondsSinceEpoch}';
                              final photo = imgCtrl.text.trim();
                              await _supabase.from('deua_main_categories').upsert({
                                'id': id,
                                'name': eName,
                                'hindi_name': hName,
                                'emoji': '',
                                'image_url': photo,
                                'sort_order': int.tryParse(sortCtrl.text.trim()) ?? (_categories.length + 1),
                              });
                              await _supabase.from('deua_sub_categories').upsert({
                                'id': 'sub_$id',
                                'main_category_id': id,
                                'name': 'All $eName',
                                'emoji': '',
                                'image_url': photo,
                                'bg_color': '#E8F5E9',
                                'sort_order': 1,
                              });
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              await _loadAllData();
                              _showMsg(isEdit ? 'Category update ho gayi!' : 'Nayi category jud gayi!');
                            } catch (e) {
                              setModal(() => saving = false);
                              _showMsg('Category error: $e', isError: true);
                            }
                          },
                    child: Text(saving ? 'सेव हो रहा है...' : 'सेव करें • Save Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade800;
      case 'Out for Delivery':
        return Colors.blue.shade700;
      case 'Delivered':
        return const Color(0xFF1B7A2B);
      case 'Cancelled':
        return Colors.red.shade700;
      default:
        return Colors.black87;
    }
  }

  Widget _ordersTab() {
    final List filtered = [];
    for (final item in _orders) {
      final o = Map.from(item as Map);
      if (_orderFilter == 'All' || (o['status'] ?? 'Pending').toString() == _orderFilter) {
        filtered.add(o);
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            scrollDirection: Axis.horizontal,
            children: ['All', 'Pending', 'Out for Delivery', 'Delivered', 'Cancelled'].map((st) {
              final sel = _orderFilter == st;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(st),
                  selected: sel,
                  selectedColor: const Color(0xFF1B7A2B),
                  labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                  onSelected: (_) => setState(() => _orderFilter = st),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: filtered.isEmpty
                ? ListView(children: const [SizedBox(height: 120), Center(child: Text('अभी कोई ऑर्डर नहीं है • No orders found'))])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final ord = Map.from(filtered[i] as Map);
                      final status = (ord['status'] ?? 'Pending').toString();
                      final items = ord['items'] is List ? List.from(ord['items'] as List) : [];
                      final sColor = _statusColor(status);

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${ord['customer_name']} • ${ord['customer_phone']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: sColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text(status, style: TextStyle(color: sColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('पता: ${ord['delivery_address']}', style: const TextStyle(fontSize: 12.5)),
                              const Divider(height: 14),
                              ...items.map((it) {
                                final m = Map.from(it as Map);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text('• ${m['name']} (${m['pack']}) x ${m['qty']}', style: const TextStyle(fontSize: 13))),
                                      Text('₹${((m['price'] as num? ?? 0) * (m['qty'] as num? ?? 1)).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('कुल: ₹${ord['total_amount']} (${ord['payment_method'] ?? 'COD'})', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1B7A2B))),
                                  PopupMenuButton(
                                    onSelected: (val) => _updateOrderStatus(ord['id'], val.toString()),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'Pending', child: Text('Pending')),
                                      PopupMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                                      PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
                                      PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: const Color(0xFF1B7A2B), borderRadius: BorderRadius.circular(8)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Status बदलें', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                          Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _productsTab() {
    final List filtered = [];
    for (final item in _products) {
      final p = Map.from(item as Map);
      final matchCat = _selectedProductCat == 'all' || p['main_category_id'].toString() == _selectedProductCat;
      final matchSearch = _productSearch.isEmpty || p['name'].toString().toLowerCase().contains(_productSearch.toLowerCase());
      if (matchCat && matchSearch) filtered.add(p);
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _productSearch = v),
              decoration: InputDecoration(
                hintText: 'सामान खोजें • Search Product...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B7A2B)),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('सभी (${_products.length})'),
                    selected: _selectedProductCat == 'all',
                    selectedColor: const Color(0xFF1B7A2B),
                    labelStyle: TextStyle(color: _selectedProductCat == 'all' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11.5),
                    onSelected: (_) => setState(() => _selectedProductCat = 'all'),
                  ),
                ),
                ..._categories.map((item) {
                  final c = Map.from(item as Map);
                  final id = c['id'].toString();
                  final sel = _selectedProductCat == id;
                  final label = (c['hindi_name'] ?? c['name']).toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: sel,
                      selectedColor: const Color(0xFF1B7A2B),
                      labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11.5),
                      onSelected: (_) => setState(() => _selectedProductCat = id),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final prod = Map.from(filtered[i] as Map);
                  final inStock = prod['in_stock'] == true;
                  final packs = prod['packs'] is List ? List.from(prod['packs'] as List) : [];
                  final packText = packs.map((x) {
                    final m = Map.from(x as Map);
                    return '${m['label']}: ₹${m['price']}';
                  }).join(' | ');

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: _netImg(prod['image_url']?.toString(), width: 52, height: 52)),
                      title: Text(prod['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(packText, style: const TextStyle(fontSize: 12, color: Color(0xFF1B7A2B), fontWeight: FontWeight.w600)),
                          Text(inStock ? 'In Stock • उपलब्ध' : 'Out of Stock • खत्म', style: TextStyle(fontSize: 11, color: inStock ? Colors.black54 : Colors.red)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(value: inStock, activeColor: const Color(0xFF1B7A2B), onChanged: (val) => _toggleProductStock(prod['id'].toString(), val)),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.black87, size: 20), onPressed: () => _openProductForm(existing: prod)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B7A2B),
        foregroundColor: Colors.white,
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('नया सामान • Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _categoriesTab() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = Map.from(_categories[i] as Map);
            final id = cat['id'].toString();
            int count = 0;
            for (final item in _products) {
              if (Map.from(item as Map)['main_category_id'].toString() == id) count++;
            }

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: _netImg(cat['image_url']?.toString(), width: 52, height: 52)),
                title: Text('${cat['hindi_name'] ?? ''} (${cat['name'] ?? ''})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('कुल सामान: $count • Order: ${cat['sort_order'] ?? i + 1}'),
                trailing: IconButton(icon: const Icon(Icons.edit, color: Color(0xFF1B7A2B)), onPressed: () => _openCategoryForm(existing: cat)),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1B7A2B),
        foregroundColor: Colors.white,
        onPressed: () => _openCategoryForm(),
        icon: const Icon(Icons.add),
        label: const Text('नई श्रेणी • Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _summaryTab() {
    double totalRevenue = 0;
    double deliveredRevenue = 0;
    int pendingCount = 0;

    for (final item in _orders) {
      final o = Map.from(item as Map);
      final st = (o['status'] ?? 'Pending').toString();
      final amt = (o['total_amount'] as num? ?? 0).toDouble();
      if (st != 'Cancelled') totalRevenue += amt;
      if (st == 'Delivered') deliveredRevenue += amt;
      if (st == 'Pending') pendingCount++;
    }

    Widget statCard(String title, String value, IconData icon, Color color) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        statCard('कुल बिक्री • Total Order Value', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, const Color(0xFF1B7A2B)),
        const SizedBox(height: 8),
        statCard('पहुंचाए गए ऑर्डर • Delivered Sales', '₹${deliveredRevenue.toStringAsFixed(0)}', Icons.check_circle_outline, Colors.teal),
        const SizedBox(height: 8),
        statCard('पेंडिंग ऑर्डर • Pending Orders', '$pendingCount', Icons.pending_actions, Colors.orange.shade800),
        const SizedBox(height: 8),
        statCard('कुल सामान व श्रेणियां • Catalog', '${_products.length} Items • ${_categories.length} Categories', Icons.inventory_2_outlined, Colors.blue.shade700),
      ],
    );
  }

  Widget _pageByKey(String key) {
    switch (key) {
      case 'orders':
        return _ordersTab();
      case 'products':
        return _productsTab();
      case 'categories':
        return _categoriesTab();
      case 'hisab':
        return _summaryTab();
      case 'staff':
        return _staffTab();
      default:
        return _ordersTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _allowedTabs();
    final safeIdx = _tabIndex < tabs.length ? _tabIndex : 0;
    final currentTab = tabs.isNotEmpty
        ? tabs[safeIdx]
        : {'key': 'orders', 'title': 'DEUA FRESH OWNER', 'label': 'Orders', 'icon': Icons.receipt_long};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B7A2B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_isOwner ? "OWNER" : "ADMIN"} • ${widget.currentUser['name']}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent),
            ),
            Text(currentTab['title'].toString(), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => await widget.onLogout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B7A2B)))
          : tabs.isEmpty
              ? const Center(child: Text('आपको अभी कोई Access नहीं मिला है। Owner से संपर्क करें।'))
              : _pageByKey(currentTab['key'].toString()),
      bottomNavigationBar: tabs.length < 2
          ? null
          : NavigationBar(
              selectedIndex: safeIdx,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFE8F5E9),
              onDestinationSelected: (i) => setState(() => _tabIndex = i),
              destinations: tabs.map((t) {
                final ic = t['icon'] as IconData;
                return NavigationDestination(
                  icon: Icon(ic),
                  selectedIcon: Icon(ic, color: const Color(0xFF1B7A2B)),
                  label: t['label'].toString(),
                );
              }).toList(),
            ),
    );
  }
}
