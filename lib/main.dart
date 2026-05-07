import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MedNavigatorApp());
}

class MedNavigatorApp extends StatelessWidget {
  const MedNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedNavigator',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0EA5E9),
        scaffoldBackgroundColor: const Color(0xFFF6FAFD),
        fontFamily: 'Roboto',
      ),
      home: const LoginRegisterScreen(),
    );
  }
}

class AppUser {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String role;

  AppUser({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.role,
  });

  String get fullName => '$firstName $lastName';
}

class MedicalCall {
  final int id;
  final String patientName;
  final String patientEmail;
  String? doctorName;
  final DateTime createdAt;
  DateTime? acceptedAt;
  DateTime? completedAt;
  String status;
  final String address;
  final double patientLat;
  final double patientLng;
  final double doctorLat;
  final double doctorLng;

  MedicalCall({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.createdAt,
    required this.status,
    required this.address,
    required this.patientLat,
    required this.patientLng,
    required this.doctorLat,
    required this.doctorLng,
    this.doctorName,
    this.acceptedAt,
    this.completedAt,
  });
}

class AppData {
  static const String adminEmail = 'admin@mednavigator.uz';
  static const String adminPassword = 'Admin12345';

  static final List<AppUser> users = [
    AppUser(
      firstName: 'Ali',
      lastName: 'Valiyev',
      email: 'bemor@gmail.com',
      password: '12345678',
      role: 'Bemor',
    ),
    AppUser(
      firstName: 'Doktor',
      lastName: 'Karimov',
      email: 'doctor@gmail.com',
      password: '12345678',
      role: 'Shifokor',
    ),
  ];

  static final List<MedicalCall> calls = [
    MedicalCall(
      id: 1,
      patientName: 'Ali Valiyev',
      patientEmail: 'bemor@gmail.com',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      status: 'Bajarilgan',
      address: 'Samarqand sh., Universitet xiyoboni',
      patientLat: 39.6542,
      patientLng: 66.9597,
      doctorLat: 39.6600,
      doctorLng: 66.9700,
      doctorName: 'Doktor Karimov',
      acceptedAt: DateTime.now().subtract(
        const Duration(days: 1, hours: 1, minutes: 45),
      ),
      completedAt: DateTime.now().subtract(
        const Duration(days: 1, hours: 1, minutes: 10),
      ),
    ),
  ];
}

String formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}  ${two(date.hour)}:${two(date.minute)}';
}

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  bool isLogin = true;
  bool obscure = true;
  String selectedRole = 'Bemor';

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  void showMsg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void login() {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email == AppData.adminEmail && pass == AppData.adminPassword) {
      final admin = AppUser(
        firstName: 'Admin',
        lastName: 'MedNavigator',
        email: AppData.adminEmail,
        password: AppData.adminPassword,
        role: 'Admin',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminScreen(user: admin)),
      );
      return;
    }

    final found = AppData.users
        .where((u) => u.email == email && u.password == pass)
        .toList();
    if (found.isEmpty) {
      showMsg('Login yoki parol noto‘g‘ri');
      return;
    }

    final user = found.first;
    if (user.role == 'Bemor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PatientScreen(user: user)),
      );
    } else if (user.role == 'Shifokor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DoctorScreen(user: user)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminScreen(user: user)),
      );
    }
  }

  void register() {
    final first = firstNameCtrl.text.trim();
    final last = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (first.isEmpty || last.isEmpty || email.isEmpty || pass.isEmpty) {
      showMsg('Barcha maydonlarni to‘ldiring');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      showMsg('Email manzil noto‘g‘ri');
      return;
    }
    if (pass.length < 8 ||
        !RegExp(r'[A-Za-z]').hasMatch(pass) ||
        !RegExp(r'\d').hasMatch(pass)) {
      showMsg('Parol kamida 8 ta belgi, harf va raqamdan iborat bo‘lsin');
      return;
    }
    if (AppData.users.any((u) => u.email == email)) {
      showMsg('Bu email oldin ro‘yxatdan o‘tgan');
      return;
    }

    AppData.users.add(
      AppUser(
        firstName: first,
        lastName: last,
        email: email,
        password: pass,
        role: selectedRole,
      ),
    );

    showMsg('Ro‘yxatdan o‘tildi. Endi kirishingiz mumkin');
    setState(() => isLogin = true);
  }

  void forgotPassword() {
    final resetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Parolni tiklash'),
        content: TextField(
          controller: resetCtrl,
          decoration: const InputDecoration(
            labelText: 'Email manzil',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              showMsg(
                'Demo rejim: tiklash kodi emailga yuborildi deb hisoblanadi',
              );
            },
            child: const Text('Kod yuborish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 18,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        size: 46,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'MedNavigator',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Geolokatsiyaga asoslangan tibbiy chaqiruv tizimi',
                    ),
                    const SizedBox(height: 22),
                    if (!isLogin) ...[
                      AppTextField(
                        controller: firstNameCtrl,
                        label: 'Ism',
                        icon: Icons.person_outline,
                      ),
                      AppTextField(
                        controller: lastNameCtrl,
                        label: 'Familiya',
                        icon: Icons.badge_outlined,
                      ),
                    ],
                    AppTextField(
                      controller: emailCtrl,
                      label: 'Login / Email',
                      icon: Icons.email_outlined,
                    ),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Parol',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isLogin)
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(
                            Icons.manage_accounts_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bemor',
                            child: Text('Bemor'),
                          ),
                          DropdownMenuItem(
                            value: 'Shifokor',
                            child: Text('Shifokor'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedRole = v ?? 'Bemor'),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: isLogin ? login : register,
                        icon: Icon(
                          isLogin ? Icons.login : Icons.person_add_alt_1,
                        ),
                        label: Text(isLogin ? 'Kirish' : 'Ro‘yxatdan o‘tish'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin
                            ? 'Ro‘yxatdan o‘tish'
                            : 'Kirish sahifasiga qaytish',
                      ),
                    ),
                    if (isLogin)
                      TextButton(
                        onPressed: forgotPassword,
                        child: const Text('Login yoki parolni unutdingizmi?'),
                      ),
                    const Divider(),
                    const Text(
                      'Demo loginlar: bemor@gmail.com / doctor@gmail.com',
                    ),
                    const Text('Admin: admin@mednavigator.uz / Admin12345'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class PatientScreen extends StatefulWidget {
  final AppUser user;
  const PatientScreen({super.key, required this.user});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PatientHome(user: widget.user, refresh: () => setState(() {})),
      PatientCalls(user: widget.user),
      ProfilePage(user: widget.user),
    ];
    return MainShell(
      title: 'Bemor paneli',
      currentIndex: index,
      onTap: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.call_outlined),
          selectedIcon: Icon(Icons.call),
          label: 'Chaqiruvlar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      child: pages[index],
    );
  }
}

class PatientHome extends StatelessWidget {
  final AppUser user;
  final VoidCallback refresh;
  const PatientHome({super.key, required this.user, required this.refresh});

  void sendCall(BuildContext context) {
    final id = AppData.calls.length + 1;
    AppData.calls.add(
      MedicalCall(
        id: id,
        patientName: user.fullName,
        patientEmail: user.email,
        createdAt: DateTime.now(),
        status: 'Yangi chaqiruv',
        address: 'Samarqand sh., joriy geolokatsiya',
        patientLat: 39.6542 + Random().nextDouble() / 100,
        patientLng: 66.9597 + Random().nextDouble() / 100,
        doctorLat: 39.6600,
        doctorLng: 66.9700,
      ),
    );
    refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chaqiruv shifokorlarga yuborildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const MapPreview(
          title: 'Joriy lokatsiya va yaqin klinikalar',
          showClinics: true,
        ),
        const SizedBox(height: 16),
        const SectionTitle('Yaqin tibbiyot muassasalari'),
        const HospitalTile(
          name: 'Samarqand viloyat klinik shifoxonasi',
          distance: '1.2 km',
        ),
        const HospitalTile(
          name: 'Tez tibbiy yordam punkti',
          distance: '1.8 km',
        ),
        const HospitalTile(name: 'Oilaviy poliklinika', distance: '2.4 km'),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: () => sendCall(context),
            icon: const Icon(Icons.emergency_share),
            label: const Text('Tibbiy chaqiruv yuborish'),
          ),
        ),
      ],
    );
  }
}

class PatientCalls extends StatelessWidget {
  final AppUser user;
  const PatientCalls({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final myCalls = AppData.calls
        .where((c) => c.patientEmail == user.email)
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Mening chaqiruvlarim'),
        if (myCalls.isEmpty) const EmptyBox(text: 'Hali chaqiruv yuborilmagan'),
        ...myCalls.map((c) => CallCard(call: c, showDoctor: true)),
      ],
    );
  }
}

class DoctorScreen extends StatefulWidget {
  final AppUser user;
  const DoctorScreen({super.key, required this.user});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DoctorHome(user: widget.user, refresh: () => setState(() {})),
      DoctorCalls(user: widget.user),
      ProfilePage(user: widget.user),
    ];
    return MainShell(
      title: 'Shifokor paneli',
      currentIndex: index,
      onTap: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.medical_services_outlined),
          selectedIcon: Icon(Icons.medical_services),
          label: 'Chaqiruvlar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      child: pages[index],
    );
  }
}

class DoctorHome extends StatelessWidget {
  final AppUser user;
  final VoidCallback refresh;
  const DoctorHome({super.key, required this.user, required this.refresh});

  void accept(BuildContext context, MedicalCall call) {
    call.status = 'Qabul qilindi';
    call.doctorName = user.fullName;
    call.acceptedAt = DateTime.now();
    refresh();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RouteTrackingScreen(call: call, doctor: user, refresh: refresh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newCalls = AppData.calls
        .where((c) => c.status == 'Yangi chaqiruv')
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Yangi bemor chaqiruvlari'),
        if (newCalls.isEmpty)
          const EmptyBox(text: 'Hozircha yangi chaqiruv yo‘q'),
        ...newCalls.map(
          (c) => CallCard(
            call: c,
            action: FilledButton.icon(
              onPressed: () => accept(context, c),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Qabul qilish'),
            ),
          ),
        ),
      ],
    );
  }
}

class RouteTrackingScreen extends StatefulWidget {
  final MedicalCall call;
  final AppUser doctor;
  final VoidCallback refresh;
  const RouteTrackingScreen({
    super.key,
    required this.call,
    required this.doctor,
    required this.refresh,
  });

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  bool started = false;
  double progress = 0.12;

  void startMove() {
    setState(() {
      started = true;
      progress = min(1, progress + 0.25);
      widget.call.status = progress >= 1 ? 'Bajarilgan' : 'Yo‘lda';
      if (progress >= 1) widget.call.completedAt = DateTime.now();
    });
    widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bemor manziliga yo‘nalish')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MapPreview(
            title: 'Shifokordan bemorgacha yo‘l',
            progress: progress,
            showClinics: false,
          ),
          const SizedBox(height: 16),
          InfoPanel(
            items: [
              'Bemor: ${widget.call.patientName}',
              'Manzil: ${widget.call.address}',
              'Chaqiruv vaqti: ${formatDateTime(widget.call.createdAt)}',
              'Holat: ${widget.call.status}',
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: progress >= 1 ? null : startMove,
              icon: Icon(progress >= 1 ? Icons.done_all : Icons.navigation),
              label: Text(
                progress >= 1
                    ? 'Chaqiruv yakunlandi'
                    : started
                    ? 'Harakatni davom ettirish'
                    : 'Chaqiruvni boshlash',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorCalls extends StatelessWidget {
  final AppUser user;
  const DoctorCalls({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final done = AppData.calls
        .where((c) => c.doctorName == user.fullName)
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Men bajargan chaqiruvlar'),
        if (done.isEmpty) const EmptyBox(text: 'Hali bajarilgan chaqiruv yo‘q'),
        ...done.map((c) => CallCard(call: c, showCompleted: true)),
      ],
    );
  }
}

class AdminScreen extends StatefulWidget {
  final AppUser user;
  const AdminScreen({super.key, required this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const AdminCalls(), const AdminStats()];
    return MainShell(
      title: 'Admin panel',
      currentIndex: index,
      onTap: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: 'Chaqiruvlar',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Statistika',
        ),
      ],
      child: pages[index],
    );
  }
}

class AdminCalls extends StatelessWidget {
  const AdminCalls({super.key});

  @override
  Widget build(BuildContext context) {
    final all = AppData.calls.reversed.toList();
    final newCalls = AppData.calls
        .where((c) => c.status == 'Yangi chaqiruv')
        .length;
    final activeCalls = AppData.calls
        .where((c) => c.status == 'Qabul qilindi' || c.status == 'Yo‘lda')
        .length;
    final doneCalls = AppData.calls
        .where((c) => c.status == 'Bajarilgan')
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Yangi',
                value: '$newCalls',
                icon: Icons.notification_important_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Jarayonda',
                value: '$activeCalls',
                icon: Icons.route_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Bajarilgan',
                value: '$doneCalls',
                icon: Icons.verified_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionTitle('Barcha tibbiy chaqiruvlar'),
        if (all.isEmpty) const EmptyBox(text: 'Hali chaqiruv mavjud emas'),
        ...all.map(
          (c) => CallCard(call: c, showDoctor: true, showCompleted: true),
        ),
      ],
    );
  }
}

class AdminStats extends StatelessWidget {
  const AdminStats({super.key});

  @override
  Widget build(BuildContext context) {
    final total = AppData.calls.length;
    final done = AppData.calls.where((c) => c.status == 'Bajarilgan').length;
    final newCalls = AppData.calls
        .where((c) => c.status == 'Yangi chaqiruv')
        .length;
    final inProgress = AppData.calls
        .where((c) => c.status == 'Qabul qilindi' || c.status == 'Yo‘lda')
        .length;
    final patients = AppData.users.where((u) => u.role == 'Bemor').length;
    final doctors = AppData.users.where((u) => u.role == 'Shifokor').length;
    final percent = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0369A1), Color(0xFF14B8A6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MedNavigator analitik paneli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chaqiruvlar, foydalanuvchilar va xizmat holatini umumiy nazorat qilish',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bajarilish ko‘rsatkichi: ${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Jami chaqiruv',
                value: '$total',
                icon: Icons.call,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Bajarilgan',
                value: '$done',
                icon: Icons.done_all,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Jarayonda',
                value: '$inProgress',
                icon: Icons.timelapse,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Bemorlar',
                value: '$patients',
                icon: Icons.groups_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Shifokorlar',
                value: '$doctors',
                icon: Icons.medical_services_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Yangi',
                value: '$newCalls',
                icon: Icons.fiber_new_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Chaqiruvlar holati bo‘yicha diagramma'),
        DonutStatusChart(done: done, active: inProgress, fresh: newCalls),
        const SizedBox(height: 22),
        const SectionTitle('Haftalik chaqiruvlar diagrammasi'),
        const MiniBarChart(
          values: [4, 6, 3, 7, 10, 5, 8],
          labels: ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Oylik chaqiruvlar diagrammasi'),
        const MiniBarChart(
          values: [12, 18, 9, 22, 27, 19, 31, 26, 21, 34, 29, 38],
          labels: [
            'Yan',
            'Fev',
            'Mar',
            'Apr',
            'May',
            'Iyn',
            'Iyl',
            'Avg',
            'Sen',
            'Okt',
            'Noy',
            'Dek',
          ],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Yillik o‘sish statistikasi'),
        const MiniBarChart(
          values: [90, 130, 160, 210],
          labels: ['2023', '2024', '2025', '2026'],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Xizmat sifati indikatorlari'),
        const QualityIndicator(
          title: 'O‘rtacha qabul qilish tezligi',
          value: .82,
          label: '82%',
        ),
        const QualityIndicator(
          title: 'Chaqiruvni yakunlash darajasi',
          value: .76,
          label: '76%',
        ),
        const QualityIndicator(
          title: 'Shifokorlar faolligi',
          value: .68,
          label: '68%',
        ),
      ],
    );
  }
}

class DonutStatusChart extends StatelessWidget {
  final int done;
  final int active;
  final int fresh;

  const DonutStatusChart({
    super.key,
    required this.done,
    required this.active,
    required this.fresh,
  });

  @override
  Widget build(BuildContext context) {
    final total = max(1, done + active + fresh);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: DonutPainter(
                done: done / total,
                active: active / total,
                fresh: fresh / total,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${done + active + fresh}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('jami'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                ChartLegend(
                  color: const Color(0xFF22C55E),
                  title: 'Bajarilgan',
                  value: '$done ta',
                ),
                ChartLegend(
                  color: const Color(0xFF0284C7),
                  title: 'Jarayonda',
                  value: '$active ta',
                ),
                ChartLegend(
                  color: const Color(0xFFF97316),
                  title: 'Yangi',
                  value: '$fresh ta',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final double done;
  final double active;
  final double fresh;

  DonutPainter({required this.done, required this.active, required this.fresh});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2.3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;

    double start = -pi / 2;
    void arc(double value, Color color) {
      if (value <= 0) return;
      paint.color = color;
      final sweep = value * 2 * pi;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    arc(done, const Color(0xFF22C55E));
    arc(active, const Color(0xFF0284C7));
    arc(fresh, const Color(0xFFF97316));
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => true;
}

class ChartLegend extends StatelessWidget {
  final Color color;
  final String title;
  final String value;

  const ChartLegend({
    super.key,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class QualityIndicator extends StatelessWidget {
  final String title;
  final double value;
  final String label;

  const QualityIndicator({
    super.key,
    required this.title,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: value, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavigationDestination> destinations;

  const MainShell({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Chiqish',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginRegisterScreen()),
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: destinations,
      ),
    );
  }
}

class MapPreview extends StatelessWidget {
  final String title;
  final bool showClinics;
  final double progress;
  const MapPreview({
    super.key,
    required this.title,
    this.showClinics = false,
    this.progress = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFDFF6FF), Color(0xFFE6FFFA)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            left: 18,
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Positioned.fill(
            top: 52,
            child: CustomPaint(
              painter: MapPainter(progress: progress, showClinics: showClinics),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo xarita: real GPS va Google Maps keyingi bosqichda ulanadi',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final double progress;
  final bool showClinics;
  MapPainter({required this.progress, required this.showClinics});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(35, size.height - 55)
      ..cubicTo(
        size.width * .25,
        size.height * .55,
        size.width * .35,
        55,
        size.width - 55,
        45,
      );
    canvas.drawPath(path, roadPaint);

    final metric = path.computeMetrics().first;
    final subPath = metric.extractPath(0, metric.length * progress.clamp(0, 1));
    canvas.drawPath(subPath, routePaint);

    void circle(Offset o, Color color, IconData icon) {
      final p = Paint()..color = color;
      canvas.drawCircle(o, 18, p);
    }

    circle(Offset(35, size.height - 55), const Color(0xFF22C55E), Icons.person);
    circle(
      Offset(size.width - 55, 45),
      const Color(0xFFEF4444),
      Icons.local_hospital,
    );

    final current =
        metric
            .getTangentForOffset(metric.length * progress.clamp(0, 1))
            ?.position ??
        Offset.zero;
    circle(current, const Color(0xFF2563EB), Icons.directions_car);

    if (showClinics) {
      for (final o in [
        Offset(size.width * .25, 60),
        Offset(size.width * .72, size.height * .72),
        Offset(size.width * .5, size.height * .45),
      ]) {
        circle(o, const Color(0xFFEF4444), Icons.local_hospital);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class HospitalTile extends StatelessWidget {
  final String name;
  final String distance;
  const HospitalTile({super.key, required this.name, required this.distance});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.local_hospital)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('Masofa: $distance'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class CallCard extends StatelessWidget {
  final MedicalCall call;
  final Widget? action;
  final bool showDoctor;
  final bool showCompleted;

  const CallCard({
    super.key,
    required this.call,
    this.action,
    this.showDoctor = false,
    this.showCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = call.status == 'Bajarilgan'
        ? Colors.green
        : call.status == 'Yangi chaqiruv'
        ? Colors.orange
        : Colors.blue;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(.15),
                  child: Icon(Icons.emergency, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    call.patientName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(
                  label: Text(call.status),
                  side: BorderSide.none,
                  backgroundColor: color.withOpacity(.15),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Manzil: ${call.address}'),
            Text('Chaqiruv sanasi: ${formatDateTime(call.createdAt)}'),
            if (showDoctor && call.doctorName != null)
              Text('Shifokor: ${call.doctorName}'),
            if (showCompleted && call.completedAt != null)
              Text('Tugatilgan vaqt: ${formatDateTime(call.completedAt!)}'),
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final AppUser user;
  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
            ),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.white,
                    child: Text(
                      user.firstName[0],
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(user.role, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileTile(
          icon: Icons.email_outlined,
          title: 'Email',
          value: user.email,
        ),
        ProfileTile(icon: Icons.badge_outlined, title: 'Rol', value: user.role),
        const ProfileTile(
          icon: Icons.verified_user_outlined,
          title: 'Status',
          value: 'Faol foydalanuvchi',
        ),
      ],
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0284C7)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Text(title),
        ],
      ),
    );
  }
}

class MiniBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  const MiniBarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce(max).toDouble();
    return Container(
      height: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = (values[i] / maxValue) * 150;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${values[i]}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: h,
                  width: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0284C7), Color(0xFF14B8A6)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[i]),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Center(child: Text(text)),
    );
  }
}

class InfoPanel extends StatelessWidget {
  final List<String> items;
  const InfoPanel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(e),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
