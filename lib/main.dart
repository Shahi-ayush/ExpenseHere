import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

import 'core/services/nepali_date_service.dart';
import 'src/storage.dart';
import 'src/auth_service.dart';
import 'src/db.dart';
import 'src/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GroceryTrackerApp());
}

class GroceryTrackerApp extends StatelessWidget {
  const GroceryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4AB878);
    const accent = Color(0xFFEF9F27);

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: accent),
      scaffoldBackgroundColor: const Color(0xFF0E1610),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0E1610), elevation: 0),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF141F18),
        border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF243A2C)), borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HISAAB',
      theme: theme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await DatabaseProvider.database();
    final savedUser = await _auth.getSavedUser();
    setState(() {
      _user = savedUser;
      _loading = false;
    });
  }

  void _onSignedIn(AppUser user) async {
    await _auth.saveSession(user.id);
    setState(() => _user = user);
  }

  void _onSignedOut() async {
    await _auth.signOut();
    setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return SignInPage(onSignedIn: _onSignedIn, auth: _auth);
    }
    return GroceryHomePage(user: _user!, onSignedOut: _onSignedOut);
  }
}

class SignInPage extends StatefulWidget {
  final void Function(AppUser) onSignedIn;
  final AuthService auth;

  const SignInPage({super.key, required this.onSignedIn, required this.auth});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _isSignUp = false;
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _validateForm() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _nameError = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final name = _nameCtrl.text.trim();

    bool isValid = true;

    if (_isSignUp && name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      isValid = false;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (_isSignUp && password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _signInEmail() async {
    if (!_validateForm()) return;

    setState(() => _loading = true);
    final user = await widget.auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (!mounted) return;
    if (user != null) {
      widget.onSignedIn(user);
    } else {
      setState(() => _passwordError = 'Invalid email or password');
    }
  }

  Future<void> _signUpEmail() async {
    if (!_validateForm()) return;

    setState(() => _loading = true);
    final success = await widget.auth.signUpWithEmail(
      DateTime.now().millisecondsSinceEpoch.toString(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (success) {
      final user = await widget.auth.signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
      if (user != null) widget.onSignedIn(user);
    } else {
      setState(() => _emailError = 'An account already exists with this email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E1610), Color(0xFF141F18), Color(0xFF0D2318)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0x264AB878),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x404AB878), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.receipt, color: Color(0xFF4AB878), size: 36),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Start tracking your grocery expenses' : 'Sign in to continue to HISAAB',
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isSignUp) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          enabled: !_loading,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Your Name',
                            hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
                            filled: true,
                            fillColor: const Color(0xFF141F18),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: _nameError != null ? Colors.red : const Color(0xFF243A2C), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _nameError != null ? Colors.red : const Color(0xFF243A2C), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF4AB878), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        if (_nameError != null) ...[
                          const SizedBox(height: 6),
                          Text(_nameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email Address', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
                          filled: true,
                          fillColor: const Color(0xFF141F18),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: _emailError != null ? Colors.red : const Color(0xFF243A2C), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _emailError != null ? Colors.red : const Color(0xFF243A2C), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF4AB878), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      if (_emailError != null) ...[
                        const SizedBox(height: 6),
                        Text(_emailError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        enabled: !_loading,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isSignUp ? 'At least 6 characters' : 'Enter your password',
                          hintStyle: const TextStyle(color: Color(0x55FFFFFF)),
                          filled: true,
                          fillColor: const Color(0xFF141F18),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: _passwordError != null ? Colors.red : const Color(0xFF243A2C), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _passwordError != null ? Colors.red : const Color(0xFF243A2C), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF4AB878), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: const Color(0x77FFFFFF)),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      if (_passwordError != null) ...[
                        const SizedBox(height: 6),
                        Text(_passwordError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : (_isSignUp ? _signUpEmail : _signInEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4AB878),
                        disabledBackgroundColor: const Color(0xFF4AB878).withAlpha(100),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E1610))))
                          : Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(color: Color(0xFF0E1610), fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF243A2C), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                        style: const TextStyle(color: Color(0xFF4AB878), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF172B1F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF243A2C)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: const Color(0x264AB878), borderRadius: BorderRadius.circular(8)),
                          child: const Center(child: Icon(Icons.shield, color: Color(0xFF4AB878), size: 16)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your data is secure and encrypted. No third-party services.',
                            style: TextStyle(color: Color(0xFFB8C2AA), fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
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

class GroceryHomePage extends StatefulWidget {
  final AppUser user;
  final VoidCallback onSignedOut;

  const GroceryHomePage({super.key, required this.user, required this.onSignedOut});

  @override
  State<GroceryHomePage> createState() => _GroceryHomePageState();
}

class _GroceryHomePageState extends State<GroceryHomePage> {
  final GroceryStorage _storage = GroceryStorage();
  final NepaliDateService _dateService = NepaliDateService();
  final List<GroceryItem> _items = [];
  bool _loading = true;
  int _selectedIndex = 0;
  NepaliDateTime _viewingMonth = NepaliDateTime.now();
  String _searchQuery = '';
  String _sortBy = 'time'; // 'time', 'amount'
  bool _isAscending = false;
  NepaliDateTime _itemsFilterMonth = NepaliDateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _storage.readItems(widget.user.id);
      setState(() {
        _items
          ..clear()
          ..addAll(list..sort((a, b) => b.date.compareTo(a.date)));
      });
    } catch (_) {
      setState(() {
        _items.clear();
      });
    }
    setState(() => _loading = false);
  }

  double get _totalSpent => _items.fold(0.0, (sum, item) => sum + item.total);
  double get _avgBasket => _items.isEmpty ? 0.0 : _totalSpent / _items.length;

  double get _thisMonthSpent {
    final now = NepaliDateTime.now();
    return _items
        .where((item) => _dateService.isSameBSMonth(item.date, now))
        .fold(0.0, (sum, item) => sum + item.total);
  }

  double get _thisMonthUnits {
    final now = NepaliDateTime.now();
    return _items
        .where((item) => _dateService.isSameBSMonth(item.date, now))
        .fold(0.0, (sum, item) => sum + item.quantity);
  }

  double get _thisMonthAvgBasket {
    final now = NepaliDateTime.now();
    final monthItems = _items.where((item) => _dateService.isSameBSMonth(item.date, now)).toList();
    return monthItems.isEmpty ? 0.0 : _thisMonthSpent / monthItems.length;
  }

  int get _shoppingDays {
    final now = NepaliDateTime.now();
    return _items
        .where((item) => _dateService.isSameBSMonth(item.date, now))
        .map((item) {
          final bsDate = _dateService.convertADToBS(item.date);
          return "${bsDate.year}-${bsDate.month}-${bsDate.day}";
        })
        .toSet()
        .length;
  }

  List<double> get _weeklySpend {
    final now = NepaliDateTime.now();
    final dates = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    return dates.map((day) {
      return _items
          .where((item) {
            final bsItem = _dateService.convertADToBS(item.date);
            return bsItem.year == day.year && bsItem.month == day.month && bsItem.day == day.day;
          })
          .fold(0.0, (sum, item) => sum + item.total);
    }).toList();
  }

  Future<void> _addItem() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddItemSheet(),
    );

    if (result != null) {
      final item = GroceryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.user.id,
        name: result['name'] as String,
        quantity: result['qty'] as double,
        unit: 'pcs',
        price: result['price'] as double,
        date: (result['date'] as DateTime?) ?? DateTime.now(),
      );
      await _storage.insertItem(item);
      if (!mounted) return;
      await _load();
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    widget.onSignedOut();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF4AB878) : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4AB878) : Colors.white38,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboardTab(context),
      _buildItemsTab(context),
      _buildReportsTab(context),
      _buildAccountTab(context),
    ];

    return Scaffold(
      extendBody: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: true,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: pages[_selectedIndex],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF4AB878),
        onPressed: _addItem,
        child: const Icon(Icons.add, color: Color(0xFF0E1610), size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 65,
        color: const Color(0xFF0E1610),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(1, Icons.list_alt_outlined, Icons.list_alt, 'Items'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.bar_chart_outlined, Icons.bar_chart, 'Reports'),
            _buildNavItem(3, Icons.person_outline, Icons.person, 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    final firstName = widget.user.displayName?.split(' ').first ?? 'User';
    final hour = DateTime.now().hour;
    String greeting = 'Good evening';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $firstName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spend overview — ${_dateService.formatBSMonthYear(NepaliDateTime.now())}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF142E20),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E402C), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Color(0xFF4AB878), size: 26),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildHeroCard(context),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(context, 'Avg basket', 'NPR ${_thisMonthAvgBasket.toStringAsFixed(0)}', Icons.shopping_cart, const Color(0xFF4AB878))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, 'Total units', '${_thisMonthUnits.toStringAsFixed(0)} pcs', Icons.inventory_2, const Color(0xFFEF9F27))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildChartCard(context)),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildInsightCard(context)),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildSectionHeader('Recent purchases', 'See all →')),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: _items.take(5).map((item) => _buildRecentItemRow(item)).toList()),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildItemsTab(BuildContext context) {
    List<GroceryItem> filteredItems = _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMonth = _dateService.isSameBSMonth(item.date, _itemsFilterMonth);
      return matchesSearch && matchesMonth;
    }).toList();

    if (_sortBy == 'time') {
      filteredItems.sort((a, b) => _isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
    } else if (_sortBy == 'amount') {
      filteredItems.sort((a, b) => _isAscending ? a.total.compareTo(b.total) : b.total.compareTo(a.total));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'All items',
            Icons.list_alt,
            trailing: InkWell(
              onTap: () async {
                final picked = await showNepaliDatePicker(
                  context: context,
                  initialDate: _itemsFilterMonth,
                  firstDate: NepaliDateTime(2000),
                  lastDate: NepaliDateTime.now(),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() {
                    _itemsFilterMonth = NepaliDateTime(picked.year, picked.month);
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF141F18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF243A2C)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dateService.formatBSMonthYear(_itemsFilterMonth).toUpperCase(),
                      style: const TextStyle(color: Color(0xFF4AB878), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4AB878), size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Highlighted text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4AB878).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4AB878).withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag, color: Color(0xFF4AB878), size: 16),
                const SizedBox(width: 8),
                Text(
                  'TOTAL ITEMS PURCHASED: ${filteredItems.length}',
                  style: const TextStyle(color: Color(0xFF4AB878), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search items...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              filled: true,
              fillColor: const Color(0xFF141F18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Time', _sortBy == 'time', () => setState(() => _sortBy = 'time')),
                const SizedBox(width: 8),
                _buildFilterChip('Amount', _sortBy == 'amount', () => setState(() => _sortBy = 'amount')),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: Colors.white10),
                const SizedBox(width: 16),
                _buildFilterChip(_isAscending ? 'Oldest' : 'Newest', false, () => setState(() => _isAscending = !_isAscending), icon: _isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text('No items found.', style: TextStyle(color: Colors.white38)))
                : ListView.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _buildItemRow(filteredItems[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4AB878) : const Color(0xFF141F18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFF243A2C)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: isSelected ? Colors.black : Colors.white70), const SizedBox(width: 4)],
            Text(
              label,
              style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(BuildContext context) {
    final weeks = ['Wk1', 'Wk2', 'Wk3', 'Wk4'];
    final weekValues = List<double>.filled(4, 0.0);
    
    final filteredItems = _items.where((item) => 
      _dateService.isSameBSMonth(item.date, _viewingMonth)
    ).toList();

    for (final item in filteredItems) {
      final bsDate = _dateService.convertADToBS(item.date);
      final weekOfMonth = ((bsDate.day - 1) ~/ 7).clamp(0, 3);
      weekValues[weekOfMonth] += item.total;
    }

    final monthTotal = filteredItems.fold(0.0, (sum, item) => sum + item.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPageHeader('Reports', Icons.bar_chart),
          ),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildCalendar(context, _viewingMonth)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(context, 'Month total', 'NPR ${monthTotal.toStringAsFixed(0)}', Icons.receipt_long, const Color(0xFF4AB878), small: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard(context, 'Purchases', '${filteredItems.length}', Icons.storefront, const Color(0xFFEF9F27), small: true)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildSpendByWeekChart(context, weeks, weekValues)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: filteredItems.isEmpty 
                ? [const Center(child: Text('No data for this month', style: TextStyle(color: Colors.white38)))]
                : filteredItems.map((item) => _buildReportRow(item)).toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF172B1F), Color(0xFF1A3525)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF243A2C)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: const Color(0x264AB878), borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Icon(Icons.person, color: Color(0xFF4AB878), size: 28)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.user.displayName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          Text(widget.user.email ?? '', style: const TextStyle(color: Color(0xFFB8C2AA), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('NPR ${_totalSpent.toStringAsFixed(0)} tracked across ${_items.length} purchases. Your personal ledger.', style: const TextStyle(color: Color(0xFFB8C2AA), fontSize: 12, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Purchases', '${_items.length}', Icons.receipt, const Color(0xFF4AB878), small: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard(context, 'Avg basket', 'NPR ${_avgBasket.toStringAsFixed(0)}', Icons.account_balance_wallet, const Color(0xFFEF9F27), small: true)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Security', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF1E3025))),
            child: Column(
              children: [
                const TextField(
                  obscureText: true,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password update feature coming soon')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3025), foregroundColor: const Color(0xFF4AB878)),
                    child: const Text('Change Password'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildAccountAction(Icons.photo, 'Attach photos to track brands or receipts'),
          const SizedBox(height: 10),
          _buildAccountAction(Icons.calendar_today, 'Browse month-by-month from Reports'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await _signOut();
              if (!mounted) return;
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Colors.red.withValues(alpha: 0.1), foregroundColor: Colors.red),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final total = _thisMonthSpent;
    final formatter = NumberFormat('#,###', 'en_US');
    final parts = total.toStringAsFixed(2).split('.');
    final integerPart = formatter.format(int.parse(parts[0]));
    final decimalPart = parts[1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // Removed fixed height to allow content to breathe and avoid overflow
      decoration: BoxDecoration(
        color: const Color(0xFF0D2318),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1E3025)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4AB878).withValues(alpha: 0.12),
                    const Color(0xFF4AB878).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Use min size
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF142E20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFF1E402C)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: const Text(
                        'HISAAB',
                        style: TextStyle(color: Color(0xFF4AB878), fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Text(
                        NepaliDateFormat('EEE, MMM d').format(NepaliDateTime.now()),
                        style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28), // Replaced Spacer with fixed gap
                const Text(
                  'TOTAL TRACKED',
                  style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'NPR ',
                      style: TextStyle(color: Color(0xFF4AB878), fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      integerPart,
                      style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w700, letterSpacing: -1),
                    ),
                    Text(
                      '.$decimalPart',
                      style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Replaced Spacer with fixed gap
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
                    children: [
                      TextSpan(
                        text: '$_shoppingDays shopping days ',
                        style: const TextStyle(color: Color(0xFF4AB878), fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: 'this month'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.all(small ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF141F18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E3025)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 18 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context) {
    final data = _weeklySpend;
    final maxValue = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    final monthName = NepaliDateFormat('MMMM').format(NepaliDateTime.now()).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1610),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2A22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY SPEND — $monthName',
            style: const TextStyle(color: Color(0x77FFFFFF), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (index) {
              final value = data[index];
              final height = maxValue == 0 ? 10.0 : 20 + (value / maxValue) * 70;
              final isTop = value == maxValue && value > 0;
              final date = NepaliDateTime.now().subtract(Duration(days: 6 - index));

              return Tooltip(
                message: 'NPR ${value.toStringAsFixed(0)} on ${NepaliDateFormat('MMM d').format(date)}',
                triggerMode: TooltipTriggerMode.tap,
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: isTop
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF63D996), Color(0xFF4AB878)],
                              )
                            : null,
                        color: isTop ? null : const Color(0xFF1A2E22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NepaliDateFormat('d').format(date),
                      style: TextStyle(
                        color: isTop ? Colors.white70 : const Color(0x44FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, NepaliDateTime date) {
    final daysInMonth = _dateService.getDaysInMonth(date.year, date.month);
    final startWeekday = _dateService.getStartWeekday(date.year, date.month); // 1 (Sun) to 7 (Sat)

    // Set of dates with spending
    final spentDates = _items
        .where((item) => _dateService.isSameBSMonth(item.date, date))
        .map((item) => _dateService.convertADToBS(item.date).day)
        .toSet();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141F18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E3025)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dateService.formatBSMonthYear(date).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        int year = _viewingMonth.year;
                        int month = _viewingMonth.month - 1;
                        if (month < 1) {
                          year--;
                          month = 12;
                        }
                        _viewingMonth = NepaliDateTime(year, month);
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF4AB878), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () async {
                      final picked = await showNepaliDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: NepaliDateTime(2000),
                        lastDate: NepaliDateTime.now(),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() {
                          _viewingMonth = NepaliDateTime(picked.year, picked.month);
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, color: Color(0xFF4AB878), size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        int year = _viewingMonth.year;
                        int month = _viewingMonth.month + 1;
                        if (month > 12) {
                          year++;
                          month = 1;
                        }
                        _viewingMonth = NepaliDateTime(year, month);
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF4AB878), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => SizedBox(width: 20, child: Center(child: Text(d, style: const TextStyle(color: Color(0x44FFFFFF), fontSize: 9, fontWeight: FontWeight.w700)))) )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (startWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - (startWeekday - 1) + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();

              final hasSpent = spentDates.contains(dayNumber);
              final now = NepaliDateTime.now();
              final isToday = dayNumber == now.day && date.month == now.month && date.year == now.year;

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isToday ? Border.all(color: const Color(0xFF4AB878), width: 1.2) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hasSpent)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 1.2),
                        ),
                      ),
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: isToday ? const Color(0xFF4AB878) : Colors.white,
                        fontSize: 11,
                        fontWeight: isToday || hasSpent ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpendByWeekChart(BuildContext context, List<String> labels, List<double> values) {
    final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF1E3025))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spend by week', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(values.length, (index) {
              final height = maxValue == 0 ? 20.0 : 20 + (values[index] / maxValue) * 60;
              final value = values[index];
              return Expanded(
                child: Tooltip(
                  message: 'NPR ${value.toStringAsFixed(0)} for ${labels[index]}',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: height, width: 18, decoration: BoxDecoration(color: values[index] > maxValue * 0.65 ? const Color(0xFF4AB878) : const Color(0xFF1E3025), borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 8),
                      Text(labels[index], style: const TextStyle(color: Color(0x55FFFFFF), fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    final largest = _items.isEmpty ? 0.0 : _items.map((item) => item.total).reduce((a, b) => a > b ? a : b);
    final largestItem = _items.isEmpty ? null : _items.firstWhere((item) => item.total == largest, orElse: () => _items.first);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF172B1F), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF243A2C))),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0x264AB878), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.spa, color: Color(0xFF4AB878), size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              largestItem == null
                  ? 'Add items to start tracking your biggest spend days.'
                  : 'Biggest purchase: ${largestItem.name} for NPR ${largestItem.total.toStringAsFixed(0)} on ${_dateService.formatBSDateLong(largestItem.date)}.',
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: const TextStyle(
              color: Color(0xFF4AB878),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildPageHeader(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF142E20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E402C)),
            ),
            child: Icon(icon, color: const Color(0xFF4AB878), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildRecentItemRow(GroceryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3025))),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF1A2E22), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF243A2C))),
            child: Center(child: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('${item.quantity} ${item.unit} · ${_dateService.formatBSMonthDay(item.date)}, ${_dateService.convertADToBS(item.date).year}', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
              ],
            ),
          ),
          Text('NPR ${item.total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF4AB878), fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildItemRow(GroceryItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3025))),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF1A2E22), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(item.name.isNotEmpty ? item.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('${item.quantity} ${item.unit} · ${_dateService.formatBSDateShort(item.date)}', style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
              ],
            ),
          ),
          Text('NPR ${item.total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF4AB878), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildReportRow(GroceryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E3025))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_dateService.formatBSDateLong(item.date), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(item.name, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
            ],
          ),
          Text('NPR ${item.total.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF4AB878), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAccountAction(IconData icon, String text) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF1E3025))),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: const Color(0x264AB878), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF4AB878), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13))),
        ],
      ),
    );
  }
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  double _qty = 1.0;
  NepaliDateTime _selectedDate = NepaliDateTime.now();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _total => (double.tryParse(_priceCtrl.text) ?? 0.0) * _qty;

  Future<void> _pickDate() async {
    final picked = await showNepaliDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: NepaliDateTime(2000),
      lastDate: NepaliDateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4AB878),
              onPrimary: Color(0xFF0E1610),
              surface: Color(0xFF141F18),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1610),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFF243A2C), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Add New Purchase', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            const Text('Item Name', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'e.g. Fresh Milk', hintStyle: TextStyle(color: Color(0x33FFFFFF))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF243A2C))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _qty = (_qty - 1).clamp(0.5, 999)),
                              icon: const Icon(Icons.remove, color: Color(0xFF4AB878), size: 20),
                            ),
                            Text(_qty % 1 == 0 ? _qty.toInt().toString() : _qty.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            IconButton(
                              onPressed: () => setState(() => _qty += 1),
                              icon: const Icon(Icons.add, color: Color(0xFF4AB878), size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rate (NPR)', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: '0.00', hintStyle: TextStyle(color: Color(0x33FFFFFF))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date of Purchase', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF243A2C))),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Color(0xFF4AB878), size: 18),
                              const SizedBox(width: 12),
                              Text(NepaliDateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF141F18), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF4AB878).withValues(alpha: 0.1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('NPR ${_total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF4AB878), fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  final price = double.tryParse(_priceCtrl.text) ?? 0.0;
                  if (name.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and valid price')));
                    return;
                  }
                  Navigator.of(context).pop({'name': name, 'price': price, 'qty': _qty, 'date': _selectedDate.toDateTime()});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4AB878),
                  foregroundColor: const Color(0xFF0E1610),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
