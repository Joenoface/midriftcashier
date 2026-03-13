import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

const String baseUrl = 'https://e3b6-102-208-44-58.ngrok-free.ap';
// Change to 'http://10.0.2.2:3000' for emulator

void main() => runApp(const MidriftCashierApp());

class MidriftCashierApp extends StatelessWidget {
  const MidriftCashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MidriftCashier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)
            .copyWith(secondary: const Color(0xFF800000)),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF008080),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => token != null ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ==================== SIGNUP ====================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    if (_username.text.isEmpty || _password.text.isEmpty || _fullName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields required')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username.text.trim(),
          'password': _password.text,
          'full_name': _fullName.text.trim(),
          'role': 'cashier',
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Account created! Please login')),
        );
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Signup failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 100,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.account_balance_wallet,
                size: 100,
                color: Color(0xFF008080),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _fullName,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (min 6)',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                ),
                onPressed: _loading ? null : _signup,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LOGIN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (_username.text.isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username.text.trim(),
          'password': _password.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('full_name', data['full_name']);
        await prefs.setString('role', data['role']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf0f0f0), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    size: 120,
                    color: Color(0xFF008080),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MIDRIFTCASHIER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF800000),
                  ),
                ),
                const Text(
                  'Solve the cash short puzzle',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008080),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('LOGIN', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          color: Color(0xFF800000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HOME ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullName = 'Cashier';
  String role = 'cashier';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('full_name') ?? 'Cashier';
      role = prefs.getString('role') ?? 'cashier';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MidriftCashier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Welcome, $fullName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Role: ${role.toUpperCase()}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.point_of_sale, color: Color(0xFF008080), size: 40),
                title: const Text('Record New Sale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('Enter today\'s cash & closing balance'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewSaleScreen()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.history,
                  color: Color(0xFF008080),
                  size: 40,
                ),
                title: const Text(
                  'Sales History & Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HISTORY WITH CHARTS ====================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> records = [];
  bool loading = true;
  double totalVariance = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/sales/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          records = data['data'] ?? [];
          totalVariance = records.fold(
            0.0,
                (sum, item) => sum + (double.tryParse(item['variance']?.toString() ?? '0') ?? 0.0),
          );
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
      setState(() => loading = false);
    }
  }

  List<PieChartSectionData> _buildPieSections() {
    double cashSum = records.fold(
      0.0,
          (sum, r) => sum + (double.tryParse(r['cash_sales']?.toString() ?? '0') ?? 0),
    );
    double nonCashSum = records.fold(
      0.0,
          (sum, r) => sum + (double.tryParse(r['non_cash_sales']?.toString() ?? '0') ?? 0),
    );
    double payoutSum = records.fold(
      0.0,
          (sum, r) => sum + (double.tryParse(r['payouts']?.toString() ?? '0') ?? 0),
    );

    double total = cashSum + nonCashSum + payoutSum;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        value: cashSum,
        color: Colors.teal,
        title: 'Cash\n${(cashSum / total * 100).toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: nonCashSum,
        color: Colors.blue,
        title: 'Non-Cash\n${(nonCashSum / total * 100).toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: payoutSum,
        color: const Color(0xFF800000),
        title: 'Payouts\n${(payoutSum / total * 100).toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History & Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Records'),
            Tab(text: 'Trend'),
            Tab(text: 'Breakdown'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Records List
          loading
              ? const Center(child: CircularProgressIndicator())
              : records.isEmpty
              ? const Center(child: Text('No records yet'))
              : ListView.builder(
            itemCount: records.length,
            itemBuilder: (ctx, i) {
              final r = records[i];
              final v = double.tryParse(r['variance']?.toString() ?? '0') ?? 0;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${r['sale_date']}'),
                  subtitle: Text('Cash: ${r['cash_sales']}'),
                  trailing: Text(
                    v.toStringAsFixed(2),
                    style: TextStyle(
                      color: v >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          // Tab 2: LINE CHART - Variance Trend
          loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        records.length,
                            (i) => FlSpot(
                          i.toDouble(),
                          double.tryParse(records[i]['variance']?.toString() ?? '0') ?? 0,
                        ),
                      ),
                      isCurved: true,
                      color: const Color(0xFF008080),
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab 3: PIE CHART - Sales Breakdown
          loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Sales Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      sections: _buildPieSections(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== NEW SALE SCREEN (Fully Working + Live Variance Preview) ====================
class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _saleDateController = TextEditingController();
  final _openingController = TextEditingController(text: '0.00');
  final _cashController = TextEditingController();
  final _nonCashController = TextEditingController(text: '0.00');
  final _payoutsController = TextEditingController(text: '0.00');
  final _closingController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  double _previewVariance = 0.0;

  @override
  void initState() {
    super.initState();
    _saleDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _calculatePreviewVariance();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _saleDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _calculatePreviewVariance() {
    final opening = double.tryParse(_openingController.text) ?? 0.0;
    final cash = double.tryParse(_cashController.text) ?? 0.0;
    final nonCash = double.tryParse(_nonCashController.text) ?? 0.0; // not used in variance
    final payouts = double.tryParse(_payoutsController.text) ?? 0.0;
    final closing = double.tryParse(_closingController.text) ?? 0.0;

    setState(() {
      _previewVariance = closing - (opening + cash - payouts);
    });
  }

  Future<void> _submitSale() async {
    // Basic validation
    if (_cashController.text.isEmpty || _closingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cash Sales and Closing Balance are required')),
      );
      return;
    }

    final cash = double.tryParse(_cashController.text);
    final closing = double.tryParse(_closingController.text);

    if (cash == null || cash < 0 || closing == null || closing < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid positive numbers')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.post(
        Uri.parse('$baseUrl/sales'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sale_date': _saleDateController.text,
          'opening_balance': double.tryParse(_openingController.text) ?? 0.0,
          'cash_sales': cash,
          'non_cash_sales': double.tryParse(_nonCashController.text) ?? 0.0,
          'payouts': double.tryParse(_payoutsController.text) ?? 0.0,
          'closing_balance': closing,
          'notes': _notesController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Sale recorded successfully! Variance auto-calculated.')),
        );
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to record sale')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Daily Sale')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker
            TextField(
              controller: _saleDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Sale Date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // Opening Balance
            TextField(
              controller: _openingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Opening Balance',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculatePreviewVariance(),
            ),
            const SizedBox(height: 16),

            // Cash Sales
            TextField(
              controller: _cashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cash Sales *',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculatePreviewVariance(),
            ),
            const SizedBox(height: 16),

            // Non-Cash Sales
            TextField(
              controller: _nonCashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Non-Cash Sales (M-Pesa, Card, etc.)',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Payouts
            TextField(
              controller: _payoutsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Payouts / Expenses',
                prefixIcon: Icon(Icons.money_off),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculatePreviewVariance(),
            ),
            const SizedBox(height: 16),

            // Closing Balance
            TextField(
              controller: _closingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Closing Balance *',
                prefixIcon: Icon(Icons.account_balance),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculatePreviewVariance(),
            ),
            const SizedBox(height: 16),

            // Live Variance Preview
            Card(
              color: _previewVariance >= 0 ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'PREVIEW VARIANCE (will be auto-calculated on server)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _previewVariance.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _previewVariance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      _previewVariance > 0
                          ? 'OVER'
                          : _previewVariance < 0
                          ? 'SHORT'
                          : 'BALANCED',
                      style: TextStyle(
                        color: _previewVariance >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  foregroundColor: Colors.white,
                ),
                onPressed: _loading ? null : _submitSale,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('RECORD SALE', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}