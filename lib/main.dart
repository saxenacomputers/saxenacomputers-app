import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaxenaComputerApp());
}

class SaxenaComputerApp extends StatefulWidget {
  const SaxenaComputerApp({super.key});

  @override
  State<SaxenaComputerApp> createState() => _SaxenaComputerAppState();
}

class _SaxenaComputerAppState extends State<SaxenaComputerApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saxena Computer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF990000),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF990000)),
        useMaterial3: true,
      ),
      home: _error != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Firebase Error: $_error', style: const TextStyle(color: Colors.red)),
                ),
              ),
            )
          : !_initialized
              ? const Scaffold(
                  backgroundColor: Color(0xFF990000),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.computer, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text('SAXENA COMPUTER', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 20),
                        CircularProgressIndicator(color: Colors.white),
                      ],
                    ),
                  ),
                )
              : const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SarkariUpdatesScreen(),
    const CscServicesScreen(),
    const ShopContactScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF990000),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SAXENA COMPUTER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('CSC & Digital Seva Kendra • Ganjdundwara', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Panel',
            onPressed: () => _showAdminPinDialog(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Sarkari Updates'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'CSC Services'),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'Centre Info'),
        ],
      ),
    );
  }

  void _showAdminPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Login'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Admin PIN dalein (Default: 1234)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == '1234') {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPostScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Galat PIN!')));
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class SarkariUpdatesScreen extends StatelessWidget {
  const SarkariUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF7A0000),
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.amber,
              tabs: [
                Tab(text: 'Latest Jobs'),
                Tab(text: 'Admit Card'),
                Tab(text: 'Results'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                UpdatesListTab(sectionFilter: 'jobs'),
                UpdatesListTab(sectionFilter: 'admit'),
                UpdatesListTab(sectionFilter: 'result'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UpdatesListTab extends StatelessWidget {
  final String sectionFilter;
  const UpdatesListTab({super.key, required this.sectionFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('updates')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Abhi koi update uplabdh nahi hai.'));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final sec = (data['section'] ?? '').toString().toLowerCase();
          if (sectionFilter == 'jobs') return sec.contains('job') || sec.contains('vacancy') || sec == '';
          if (sectionFilter == 'admit') return sec.contains('admit');
          if (sectionFilter == 'result') return sec.contains('result');
          return true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('Is category mein abhi koi post nahi hai.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final badge = (data['badge'] ?? '').toString();
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF990000),
                  child: Icon(Icons.campaign, color: Colors.white, size: 20),
                ),
                title: Text(
                  data['shortTitle'] ?? data['title'] ?? 'New Update',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF000080)),
                ),
                subtitle: Text(data['dept'] ?? 'Saxena Computer Update'),
                trailing: badge.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(badge, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UpdateDetailScreen(data: data)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UpdateDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const UpdateDetailScreen({super.key, required this.data});

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF990000),
        foregroundColor: Colors.white,
        title: Text(data['shortTitle'] ?? 'Details', style: const TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['title'] ?? '', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF990000))),
            const SizedBox(height: 4),
            Text(data['dept'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            _infoSection('Short Information (Overview)', data['overview']),
            _infoSection('Eligibility / Qualification', data['eligibility']),
            _infoSection('Required Documents (Zaroori Kagaz)', data['docs']),
            _infoSection('Selection / Form Process', data['process']),
            const SizedBox(height: 16),
            if ((data['officialUrl'] ?? '').toString().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Apply Online / Official Link'),
                  onPressed: () => _openUrl(data['officialUrl']),
                ),
              ),
            const SizedBox(height: 10),
            if ((data['pdfUrl'] ?? '').toString().isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download Notification / PDF'),
                  onPressed: () => _openUrl(data['pdfUrl']),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.storefront, color: Color(0xFF990000)),
                label: const Text('Form Bharwane ke liye Saxena Computer Aayein'),
                onPressed: () => _openUrl('https://saxenacomputers.shop'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String heading, dynamic content) {
    final text = (content ?? '').toString().trim();
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFF000080),
            child: Text(heading, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class CscServicesScreen extends StatelessWidget {
  const CscServicesScreen({super.key});

  final List services = const [
    {'name': 'Aay Praman Patra (Income Certificate)', 'docs': 'Aadhaar Card, Photo, Ration Card / Family ID, Self Declaration'},
    {'name': 'Jaati Praman Patra (Caste Certificate)', 'docs': 'Aadhaar Card, Photo, Father/Family Caste Proof, Ration Card'},
    {'name': 'Niwas Praman Patra (Domicile)', 'docs': 'Aadhaar Card, Photo, Bijli Bill / Ration Card / Voter ID'},
    {'name': 'UP Scholarship Online Form', 'docs': 'Previous Marksheet, Income & Caste Certificate, Bank Passbook, Aadhaar'},
    {'name': 'New PAN Card & Correction', 'docs': 'Aadhaar Card (Mobile Linked), 2 Passport Size Photos'},
    {'name': 'Ayushman Card & e-Shram Card', 'docs': 'Aadhaar Card, Ration Card, Active Mobile Number'},
    {'name': 'PF Withdrawal, Train Ticket & Money Transfer', 'docs': 'UAN Number / Aadhaar / Bank Details'},
    {'name': 'Color Printout, Lamination & Urgent Photo', 'docs': 'Saxena Computer par turant suvidha uplabdh'},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final item = services[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF990000))),
                const SizedBox(height: 6),
                Text('Zaroori Documents: ${item['docs']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShopContactScreen extends StatelessWidget {
  const ShopContactScreen({super.key});

  Future<void> _launchWeb() async {
    final uri = Uri.parse('https://saxenacomputers.shop');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saxena Computer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF990000))),
          const Text('Common Services Centre (CSC) & Online Form Portal', style: TextStyle(fontSize: 14, color: Colors.black54)),
          const Divider(height: 24),
          const ListTile(
            leading: Icon(Icons.location_on, color: Color(0xFF990000)),
            title: Text('Address'),
            subtitle: Text('In front of Ganjdundwara PG College, Ganjdundwara, Kasganj (U.P.)'),
          ),
          const ListTile(
            leading: Icon(Icons.access_time, color: Color(0xFF990000)),
            title: Text('Opening Hours'),
            subtitle: Text('8:00 AM to 8:00 PM (7 Days Open)'),
          ),
          const ListTile(
            leading: Icon(Icons.language, color: Color(0xFF990000)),
            title: Text('Official Website'),
            subtitle: Text('https://saxenacomputers.shop'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF990000), foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
              icon: const Icon(Icons.public),
              label: const Text('Visit Website (saxenacomputers.shop)'),
              onPressed: _launchWeb,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});

  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  String _section = 'jobs';
  final _shortTitle = TextEditingController();
  final _badge = TextEditingController(text: 'NEW');
  final _title = TextEditingController();
  final _dept = TextEditingController();
  final _overview = TextEditingController();
  final _eligibility = TextEditingController();
  final _docs = TextEditingController();
  final _process = TextEditingController();
  final _officialUrl = TextEditingController();
  final _pdfUrl = TextEditingController();
  bool _loading = false;

  Future<void> _submitPost() async {
    if (_shortTitle.text.isEmpty || _title.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('updates').add({
        'section': _section,
        'shortTitle': _shortTitle.text.trim(),
        'badge': _badge.text.trim(),
        'title': _title.text.trim(),
        'dept': _dept.text.trim(),
        'overview': _overview.text.trim(),
        'eligibility': _eligibility.text.trim(),
        'docs': _docs.text.trim(),
        'process': _process.text.trim(),
        'officialUrl': _officialUrl.text.trim(),
        'pdfUrl': _pdfUrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post Live Ho Gayi (Website + App)!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sarkari Update Dalein'), backgroundColor: const Color(0xFF990000), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _section,
              decoration: const InputDecoration(labelText: 'Category Chunein', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'jobs', child: Text('Latest Jobs')),
                DropdownMenuItem(value: 'admit', child: Text('Admit Card')),
                DropdownMenuItem(value: 'result', child: Text('Result')),
              ],
              onChanged: (val) => setState(() => _section = val!),
            ),
            const SizedBox(height: 10),
            TextField(controller: _shortTitle, decoration: const InputDecoration(labelText: 'Short Title (List mein dikhega)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _badge, decoration: const InputDecoration(labelText: 'Badge (e.g. NEW, OUT)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Full Post Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _dept, decoration: const InputDecoration(labelText: 'Department / Board Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _overview, maxLines: 3, decoration: const InputDecoration(labelText: 'Overview / Important Dates & Fees', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _eligibility, maxLines: 2, decoration: const InputDecoration(labelText: 'Eligibility / Age Limit', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _docs, maxLines: 2, decoration: const InputDecoration(labelText: 'Required Documents', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _process, maxLines: 2, decoration: const InputDecoration(labelText: 'How to Apply / Process', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _officialUrl, decoration: const InputDecoration(labelText: 'Official / Apply Link', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _pdfUrl, decoration: const InputDecoration(labelText: 'Notification PDF Link', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                onPressed: _loading ? null : _submitPost,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Update (App + Website)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
