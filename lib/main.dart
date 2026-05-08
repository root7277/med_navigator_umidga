import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MedNavigatorApp());
}

class MedNavigatorApp extends StatelessWidget {
  const MedNavigatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedNavigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0284C7),
        scaffoldBackgroundColor: const Color(0xFFF6FAFD),
      ),
      home: const AuthGate(),
    );
  }
}

class AppConst {
  static const String adminEmail = 'admin@mednavigator.uz';
  static const String adminPassword = 'Admin12345';
  static const LatLng defaultLocation = LatLng(39.6542, 66.9597);
}

class FirebaseRefs {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');

  static CollectionReference<Map<String, dynamic>> get calls =>
      db.collection('medical_calls');
}

void snack(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

String authError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Email manzil noto‘g‘ri.';
    case 'email-already-in-use':
      return 'Bu email oldin ro‘yxatdan o‘tgan.';
    case 'weak-password':
      return 'Parol juda oddiy.';
    case 'user-not-found':
      return 'Bu email bo‘yicha foydalanuvchi topilmadi.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Login yoki parol noto‘g‘ri.';
    default:
      return e.message ?? 'Firebase xatoligi.';
  }
}

String formatTime(dynamic value) {
  if (value == null) return 'Aniqlanmoqda';

  DateTime date;
  if (value is Timestamp) {
    date = value.toDate();
  } else if (value is DateTime) {
    date = value;
  } else {
    return 'Aniqlanmoqda';
  }

  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
}

String statusText(String status) {
  switch (status) {
    case 'pending':
      return 'Yangi chaqiruv';
    case 'accepted':
      return 'Qabul qilindi';
    case 'on_the_way':
      return 'Shifokor yo‘lda';
    case 'completed':
      return 'Bajarilgan';
    default:
      return status;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'accepted':
      return Colors.blue;
    case 'on_the_way':
      return Colors.indigo;
    case 'completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

Future<Position?> currentPosition(BuildContext context) async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    // ignore: use_build_context_synchronously
    snack(context, 'GPS o‘chirilgan. Lokatsiyani yoqing.');
    return null;
  }

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    // ignore: use_build_context_synchronously
    snack(context, 'Lokatsiya uchun ruxsat berilmadi.');
    return null;
  }

  // ignore: deprecated_member_use
  return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}

double kmBetween(LatLng a, LatLng b) {
  return Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      ) /
      1000;
}

// ===================== AUTH GATE =====================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await FirebaseRefs.users.doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseRefs.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (!snapshot.hasData) {
          return const LoginPage();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            final userData = userSnapshot.data;

            if (userData == null) {
              return const LoginPage();
            }

            final role = userData['role'] ?? 'Bemor';

            if (role == 'Shifokor') {
              return DoctorShell(userData: userData);
            }

            return PatientShell(userData: userData);
          },
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ===================== LOGIN REGISTER =====================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  bool obscure = true;
  String selectedRole = 'Bemor';

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final firstName = firstNameCtrl.text.trim();
    final lastName = lastNameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (email == AppConst.adminEmail && password == AppConst.adminPassword) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      snack(context, 'Email va parolni kiriting.');
      return;
    }

    if (!email.contains('@')) {
      snack(context, 'Email noto‘g‘ri kiritildi.');
      return;
    }

    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);

    if (password.length < 8 || !hasLetter || !hasDigit) {
      snack(
        context,
        'Parol kamida 8 ta belgi, harf va raqamdan iborat bo‘lsin.',
      );
      return;
    }

    if (!isLogin && (firstName.isEmpty || lastName.isEmpty)) {
      snack(context, 'Ism va familiyani kiriting.');
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        final credential = await FirebaseRefs.auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final doc = await FirebaseRefs.users.doc(credential.user!.uid).get();
        final userData = doc.data();

        if (userData == null) {
          await FirebaseRefs.auth.signOut();
          if (!mounted) return;
          snack(context, 'Foydalanuvchi ma’lumotlari bazadan topilmadi.');
          return;
        }

        if (!mounted) return;

        final role = userData['role'] ?? 'Bemor';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'Shifokor'
                ? DoctorShell(userData: userData)
                : PatientShell(userData: userData),
          ),
        );
      } else {
        final credential = await FirebaseRefs.auth
            .createUserWithEmailAndPassword(email: email, password: password);

        final uid = credential.user!.uid;
        final fullName = '$firstName $lastName';

        await credential.user!.updateDisplayName(fullName);

        final userData = {
          'uid': uid,
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'email': email,
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseRefs.users.doc(uid).set(userData);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => selectedRole == 'Shifokor'
                ? DoctorShell(userData: userData)
                : PatientShell(userData: userData),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      snack(context, authError(e));
    } catch (e) {
      if (!mounted) return;
      snack(context, 'Xatolik: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> resetPassword() async {
    final resetCtrl = TextEditingController(text: emailCtrl.text.trim());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Parolni tiklash'),
          content: TextField(
            controller: resetCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email manzil',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () async {
                final email = resetCtrl.text.trim();

                if (email.isEmpty) {
                  snack(context, 'Email kiriting.');
                  return;
                }

                try {
                  await FirebaseRefs.auth.sendPasswordResetEmail(email: email);

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (!mounted) return;
                  snack(
                    context,
                    'Parolni tiklash havolasi emailingizga yuborildi.',
                  );
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;
                  snack(context, authError(e));
                } catch (e) {
                  if (!mounted) return;
                  snack(context, 'Xatolik: $e');
                }
              },
              child: const Text('Yuborish'),
            ),
          ],
        );
      },
    );

    resetCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBg(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: Color(0xFF0284C7),
                        size: 46,
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
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    if (!isLogin) ...[
                      AppField(
                        controller: firstNameCtrl,
                        label: 'Ism',
                        icon: Icons.person_outline,
                      ),
                      AppField(
                        controller: lastNameCtrl,
                        label: 'Familiya',
                        icon: Icons.badge_outlined,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedRole,
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
                          onChanged: (value) {
                            setState(() => selectedRole = value ?? 'Bemor');
                          },
                        ),
                      ),
                    ],
                    AppField(
                      controller: emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: passwordCtrl,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Parol',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: loading ? null : submit,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isLogin ? Icons.login : Icons.person_add_alt_1,
                              ),
                        label: Text(isLogin ? 'Kirish' : 'Ro‘yxatdan o‘tish'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => isLogin = !isLogin);
                      },
                      child: Text(
                        isLogin
                            ? 'Ro‘yxatdan o‘tish'
                            : 'Kirish sahifasiga qaytish',
                      ),
                    ),
                    if (isLogin)
                      TextButton(
                        onPressed: resetPassword,
                        child: const Text('Parolni unutdingizmi?'),
                      ),
                    const Divider(),
                    const Text(
                      'Admin: admin@mednavigator.uz / Admin12345',
                      textAlign: TextAlign.center,
                    ),
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

// ===================== PATIENT =====================

class PatientShell extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PatientShell({super.key, required this.userData});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PatientHome(userData: widget.userData),
      PatientCalls(userData: widget.userData),
      ProfilePage(userData: widget.userData),
    ];

    return MainShell(
      title: 'Bemor paneli',
      index: index,
      onTap: (value) => setState(() => index = value),
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

class PatientHome extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PatientHome({super.key, required this.userData});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  GoogleMapController? mapController;
  LatLng current = AppConst.defaultLocation;
  bool loadingLocation = true;
  bool sending = false;

  final List<Map<String, dynamic>> clinics = const [
    {
      'name': 'Samarqand viloyat klinik shifoxonasi',
      'lat': 39.6570,
      'lng': 66.9610,
    },
    {'name': 'Tez tibbiy yordam punkti', 'lat': 39.6500, 'lng': 66.9550},
    {'name': 'Oilaviy poliklinika', 'lat': 39.6620, 'lng': 66.9720},
  ];

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    final position = await currentPosition(context);

    if (position != null) {
      current = LatLng(position.latitude, position.longitude);
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 15));
    }

    if (mounted) {
      setState(() => loadingLocation = false);
    }
  }

  Future<void> sendCall() async {
    setState(() => sending = true);

    try {
      final position = await currentPosition(context);
      final user = FirebaseRefs.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        snack(context, 'Tizimga qayta kiring.');
        return;
      }

      final location = position == null
          ? current
          : LatLng(position.latitude, position.longitude);

      await FirebaseRefs.calls.add({
        'patientId': user.uid,
        'patientName': widget.userData['fullName'] ?? user.email ?? 'Bemor',
        'patientEmail': user.email,
        'patientLat': location.latitude,
        'patientLng': location.longitude,
        'address': 'Joriy GPS lokatsiya',
        'status': 'pending',
        'doctorId': null,
        'doctorName': null,
        'doctorLat': null,
        'doctorLng': null,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'completedAt': null,
      });

      if (!mounted) return;
      snack(context, 'Chaqiruv shifokorlarga yuborildi.');
    } catch (e) {
      if (!mounted) return;
      snack(context, 'Chaqiruv yuborishda xatolik: $e');
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('patient_current'),
        position: current,
        infoWindow: const InfoWindow(title: 'Sizning joylashuvingiz'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      ...clinics.map((clinic) {
        final location = LatLng(
          clinic['lat'] as double,
          clinic['lng'] as double,
        );

        return Marker(
          markerId: MarkerId(clinic['name'] as String),
          position: location,
          infoWindow: InfoWindow(title: clinic['name'] as String),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      }),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MapBox(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: current, zoom: 14),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              mapController = controller;
              controller.animateCamera(CameraUpdate.newLatLngZoom(current, 14));
            },
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Yaqin klinikalar'),
        if (loadingLocation)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...clinics.map((clinic) {
            final location = LatLng(
              clinic['lat'] as double,
              clinic['lng'] as double,
            );
            final distance = kmBetween(current, location);

            return HospitalTile(
              name: clinic['name'] as String,
              distance: '${distance.toStringAsFixed(1)} km',
            );
          }),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: sending ? null : sendCall,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.emergency_share),
            label: Text(
              sending ? 'Yuborilmoqda...' : 'Tibbiy chaqiruv yuborish',
            ),
          ),
        ),
      ],
    );
  }
}

class PatientCalls extends StatelessWidget {
  final Map<String, dynamic> userData;

  const PatientCalls({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseRefs.auth.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseRefs.calls.where('patientId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];

          if (at is Timestamp && bt is Timestamp) {
            return bt.compareTo(at);
          }

          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle('Mening chaqiruvlarim'),
            if (docs.isEmpty)
              const EmptyBox(text: 'Hali chaqiruv yuborilmagan.'),
            ...docs.map((doc) {
              final data = doc.data();
              final status = data['status'] ?? '';

              return CallCard(
                data: data,
                showDoctor: true,
                showCompleted: true,
                action: status == 'accepted' || status == 'on_the_way'
                    ? FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientTrackingPage(callId: doc.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_searching),
                        label: const Text('Shifokorni kuzatish'),
                      )
                    : null,
              );
            }),
          ],
        );
      },
    );
  }
}

class PatientTrackingPage extends StatelessWidget {
  final String callId;

  const PatientTrackingPage({super.key, required this.callId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shifokor harakatini kuzatish')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseRefs.calls.doc(callId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? {};

          final patient = LatLng(
            (data['patientLat'] ?? AppConst.defaultLocation.latitude)
                .toDouble(),
            (data['patientLng'] ?? AppConst.defaultLocation.longitude)
                .toDouble(),
          );

          final doctorLat = data['doctorLat'];
          final doctorLng = data['doctorLng'];

          final LatLng? doctor = doctorLat == null || doctorLng == null
              ? null
              : LatLng(doctorLat.toDouble(), doctorLng.toDouble());

          final markers = <Marker>{
            Marker(
              markerId: const MarkerId('patient'),
              position: patient,
              infoWindow: const InfoWindow(title: 'Bemor'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
            if (doctor != null)
              Marker(
                markerId: const MarkerId('doctor'),
                position: doctor,
                infoWindow: InfoWindow(title: data['doctorName'] ?? 'Shifokor'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
          };

          final polylines = <Polyline>{
            if (doctor != null)
              Polyline(
                polylineId: const PolylineId('doctor_patient_line'),
                points: [doctor, patient],
                width: 5,
                color: Colors.blue,
              ),
          };

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: doctor ?? patient,
                    zoom: 15,
                  ),
                  markers: markers,
                  polylines: polylines,
                ),
              ),
              StatusPanel(
                title: 'Holat: ${statusText(data['status'] ?? '')}',
                lines: [
                  'Shifokor: ${data['doctorName'] ?? 'Hali belgilanmagan'}',
                  'Chaqiruv vaqti: ${formatTime(data['createdAt'])}',
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===================== DOCTOR =====================

class DoctorShell extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DoctorShell({super.key, required this.userData});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DoctorHome(userData: widget.userData),
      DoctorCalls(userData: widget.userData),
      ProfilePage(userData: widget.userData),
    ];

    return MainShell(
      title: 'Shifokor paneli',
      index: index,
      onTap: (value) => setState(() => index = value),
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
  final Map<String, dynamic> userData;

  const DoctorHome({super.key, required this.userData});

  Future<void> acceptCall(BuildContext context, String callId) async {
    final user = FirebaseRefs.auth.currentUser;

    if (user == null) {
      snack(context, 'Tizimga qayta kiring.');
      return;
    }

    final position = await currentPosition(context);

    await FirebaseRefs.calls.doc(callId).update({
      'status': 'accepted',
      'doctorId': user.uid,
      'doctorName': userData['fullName'] ?? user.email ?? 'Shifokor',
      'doctorLat': position?.latitude,
      'doctorLng': position?.longitude,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorNavigationPage(
          callId: callId,
          doctorName: userData['fullName'] ?? 'Shifokor',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseRefs.calls
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];

          if (at is Timestamp && bt is Timestamp) {
            return bt.compareTo(at);
          }

          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle('Yangi bemor chaqiruvlari'),
            if (docs.isEmpty)
              const EmptyBox(text: 'Hozircha yangi chaqiruv yo‘q.'),
            ...docs.map((doc) {
              return CallCard(
                data: doc.data(),
                action: FilledButton.icon(
                  onPressed: () => acceptCall(context, doc.id),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Qabul qilish'),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class DoctorNavigationPage extends StatefulWidget {
  final String callId;
  final String doctorName;

  const DoctorNavigationPage({
    super.key,
    required this.callId,
    required this.doctorName,
  });

  @override
  State<DoctorNavigationPage> createState() => _DoctorNavigationPageState();
}

class _DoctorNavigationPageState extends State<DoctorNavigationPage> {
  StreamSubscription<Position>? subscription;
  LatLng? doctorLocation;
  bool tracking = false;

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> startTracking() async {
    final position = await currentPosition(context);

    if (position == null) return;

    setState(() {
      doctorLocation = LatLng(position.latitude, position.longitude);
      tracking = true;
    });

    await FirebaseRefs.calls.doc(widget.callId).update({
      'status': 'on_the_way',
      'doctorLat': position.latitude,
      'doctorLng': position.longitude,
    });

    await subscription?.cancel();

    subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen((position) async {
          final next = LatLng(position.latitude, position.longitude);

          doctorLocation = next;

          await FirebaseRefs.calls.doc(widget.callId).update({
            'status': 'on_the_way',
            'doctorLat': next.latitude,
            'doctorLng': next.longitude,
          });

          if (mounted) {
            setState(() {});
          }
        });

    if (!mounted) return;
    snack(context, 'Jonli tracking boshlandi.');
  }

  Future<void> completeCall() async {
    await subscription?.cancel();

    await FirebaseRefs.calls.doc(widget.callId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    snack(context, 'Chaqiruv bajarilgan deb belgilandi.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bemor manziliga yo‘l')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseRefs.calls.doc(widget.callId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? {};

          final patient = LatLng(
            (data['patientLat'] ?? AppConst.defaultLocation.latitude)
                .toDouble(),
            (data['patientLng'] ?? AppConst.defaultLocation.longitude)
                .toDouble(),
          );

          final mapDoctor =
              doctorLocation ??
              ((data['doctorLat'] != null && data['doctorLng'] != null)
                  ? LatLng(
                      data['doctorLat'].toDouble(),
                      data['doctorLng'].toDouble(),
                    )
                  : patient);

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: mapDoctor,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('patient'),
                      position: patient,
                      infoWindow: InfoWindow(
                        title: data['patientName'] ?? 'Bemor',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                    Marker(
                      markerId: const MarkerId('doctor'),
                      position: mapDoctor,
                      infoWindow: InfoWindow(title: widget.doctorName),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                  },
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: [mapDoctor, patient],
                      color: Colors.blue,
                      width: 5,
                    ),
                  },
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bemor: ${data['patientName'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Holat: ${statusText(data['status'] ?? '')}'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: tracking ? null : startTracking,
                      icon: const Icon(Icons.navigation),
                      label: Text(
                        tracking
                            ? 'Jonli tracking ishlayapti'
                            : 'Chaqiruvni boshlash',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: completeCall,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Chaqiruvni tugatish'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DoctorCalls extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DoctorCalls({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseRefs.auth.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseRefs.calls.where('doctorId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];

          if (at is Timestamp && bt is Timestamp) {
            return bt.compareTo(at);
          }

          return 0;
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionTitle('Men qabul qilgan chaqiruvlar'),
            if (docs.isEmpty)
              const EmptyBox(text: 'Hali chaqiruv qabul qilinmagan.'),
            ...docs.map((doc) {
              return CallCard(
                data: doc.data(),
                showDoctor: true,
                showCompleted: true,
              );
            }),
          ],
        );
      },
    );
  }
}

// ===================== ADMIN =====================

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [AdminCallsPage(), AdminStatsPage()];

    return MainShell(
      title: 'Admin panel',
      index: index,
      isAdmin: true,
      onTap: (value) => setState(() => index = value),
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

class AdminCallsPage extends StatelessWidget {
  const AdminCallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseRefs.calls.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];

          if (at is Timestamp && bt is Timestamp) {
            return bt.compareTo(at);
          }

          return 0;
        });

        final pending = docs
            .where((doc) => doc.data()['status'] == 'pending')
            .length;
        final active = docs.where((doc) {
          final status = doc.data()['status'];
          return status == 'accepted' || status == 'on_the_way';
        }).length;
        final completed = docs
            .where((doc) => doc.data()['status'] == 'completed')
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Yangi',
                    value: '$pending',
                    icon: Icons.fiber_new,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Jarayonda',
                    value: '$active',
                    icon: Icons.route,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Bajarilgan',
                    value: '$completed',
                    icon: Icons.done_all,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('Barcha tibbiy chaqiruvlar'),
            if (docs.isEmpty) const EmptyBox(text: 'Chaqiruv mavjud emas.'),
            ...docs.map((doc) {
              return CallCard(
                data: doc.data(),
                showDoctor: true,
                showCompleted: true,
              );
            }),
          ],
        );
      },
    );
  }
}

class AdminStatsPage extends StatelessWidget {
  const AdminStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseRefs.calls.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;
        final pending = docs
            .where((doc) => doc.data()['status'] == 'pending')
            .length;
        final active = docs.where((doc) {
          final status = doc.data()['status'];
          return status == 'accepted' || status == 'on_the_way';
        }).length;
        final completed = docs
            .where((doc) => doc.data()['status'] == 'completed')
            .length;
        final percent = total == 0 ? 0.0 : completed / total;

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
                  const SizedBox(height: 8),
                  const Text(
                    'Real-time chaqiruvlar statistikasi',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
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
                      fontWeight: FontWeight.w800,
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
                    title: 'Jami',
                    value: '$total',
                    icon: Icons.call,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Yangi',
                    value: '$pending',
                    icon: Icons.fiber_new,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Bajarilgan',
                    value: '$completed',
                    icon: Icons.done_all,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionTitle('Holatlar bo‘yicha diagramma'),
            DonutStatusChart(done: completed, active: active, fresh: pending),
            const SizedBox(height: 22),
            const SectionTitle('Haftalik diagramma'),
            const MiniBarChart(
              values: [4, 6, 3, 7, 10, 5, 8],
              labels: ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
            ),
            const SizedBox(height: 22),
            const SectionTitle('Oylik diagramma'),
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
            const SectionTitle('Xizmat sifati indikatorlari'),
            QualityIndicator(
              title: 'Qabul qilish tezligi',
              value: total == 0 ? 0 : min(1, active / total + .2),
              label:
                  '${((total == 0 ? 0 : min(1, active / total + .2)) * 100).toStringAsFixed(0)}%',
            ),
            QualityIndicator(
              title: 'Yakunlangan chaqiruvlar',
              value: percent,
              label: '${(percent * 100).toStringAsFixed(0)}%',
            ),
          ],
        );
      },
    );
  }
}

// ===================== COMMON UI =====================

class MainShell extends StatelessWidget {
  final String title;
  final Widget child;
  final int index;
  final bool isAdmin;
  final ValueChanged<int> onTap;
  final List<NavigationDestination> destinations;

  const MainShell({
    super.key,
    required this.title,
    required this.child,
    required this.index,
    required this.onTap,
    required this.destinations,
    this.isAdmin = false,
  });

  Future<void> logout(BuildContext context) async {
    if (!isAdmin) {
      await FirebaseRefs.auth.signOut();
    }

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onTap,
        destinations: destinations,
      ),
    );
  }
}

class GradientBg extends StatelessWidget {
  final Widget child;

  const GradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class MapBox extends StatelessWidget {
  final Widget child;

  const MapBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: ClipRRect(borderRadius: BorderRadius.circular(26), child: child),
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
      ),
    );
  }
}

class CallCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Widget? action;
  final bool showDoctor;
  final bool showCompleted;

  const CallCard({
    super.key,
    required this.data,
    this.action,
    this.showDoctor = false,
    this.showCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? '';
    final color = statusColor(status);

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
                  // ignore: deprecated_member_use
                  backgroundColor: color.withOpacity(.15),
                  child: Icon(Icons.emergency, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['patientName'] ?? 'Bemor',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Chip(
                  label: Text(statusText(status)),
                  // ignore: deprecated_member_use
                  backgroundColor: color.withOpacity(.14),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Manzil: ${data['address'] ?? 'GPS lokatsiya'}'),
            Text('Chaqiruv sanasi: ${formatTime(data['createdAt'])}'),
            if (showDoctor)
              Text('Shifokor: ${data['doctorName'] ?? 'Hali belgilanmagan'}'),
            if (showCompleted)
              Text('Tugatilgan vaqt: ${formatTime(data['completedAt'])}'),
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

class StatusPanel extends StatelessWidget {
  final String title;
  final List<String> lines;

  const StatusPanel({super.key, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 6),
          ...lines.map((line) => Text(line)),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfilePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseRefs.auth.currentUser;
    final fullName =
        userData['fullName'] ?? user?.displayName ?? 'Foydalanuvchi';
    final email = userData['email'] ?? user?.email ?? '';
    final role = userData['role'] ?? 'Bemor';

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
              CircleAvatar(
                radius: 54,
                backgroundColor: Colors.white,
                child: Text(
                  fullName.toString().isNotEmpty
                      ? fullName.toString()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(role, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileTile(icon: Icons.email_outlined, title: 'Email', value: email),
        ProfileTile(icon: Icons.badge_outlined, title: 'Rol', value: role),
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
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0284C7)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(title, textAlign: TextAlign.center),
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
          // ignore: deprecated_member_use
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: h,
                  width: 24,
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
                Text(labels[i], style: const TextStyle(fontSize: 11)),
              ],
            ),
          );
        }),
      ),
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
          // ignore: deprecated_member_use
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

    void drawPart(double value, Color color) {
      if (value <= 0) return;
      paint.color = color;
      final sweep = value * 2 * pi;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    drawPart(done, const Color(0xFF22C55E));
    drawPart(active, const Color(0xFF0284C7));
    drawPart(fresh, const Color(0xFFF97316));
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) {
    return oldDelegate.done != done ||
        oldDelegate.active != active ||
        oldDelegate.fresh != fresh;
  }
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
    final safeValue = value.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // ignore: deprecated_member_use
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
            child: LinearProgressIndicator(value: safeValue, minHeight: 10),
          ),
        ],
      ),
    );
  }
}
