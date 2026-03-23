import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'student_dashboard.dart';
import 'admin_dashboard.dart';

class FacultyRegisterScreen extends StatefulWidget {
  const FacultyRegisterScreen({super.key});

  @override
  State<FacultyRegisterScreen> createState() => _FacultyRegisterScreenState();
}

class _FacultyRegisterScreenState extends State<FacultyRegisterScreen> {

  // ================= BANNER AD =================
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-9332148976634523/7351534762', // Banner Ad
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  final adminPasswordController = TextEditingController();

  /// ADMIN SECRET LOGIN
  final String adminMobile = "9999999999";
  final String adminPassword = "admin123";

  String? selectedBus;
  String? selectedBranch;

  bool isAdminLogin = false;
  bool isExistingFaculty = false;
  bool otpSent = false;
  bool isLoading = false;

  String verificationId = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> busList = List.generate(15, (i) => (i + 1).toString());

  List<String> branchList = [
    "Civil",
    "Mechanical",
    "Electrical",
    "Computer Science",
    "Mining"
  ];

  /// Faculty Type (College / School)
  String? facultyType;

  /// ===============================
  /// MOBILE CHECK
  /// ===============================
  void onMobileChanged(String mobile) async {
    if (mobile == adminMobile) {
      setState(() {
        isAdminLogin = true;
      });
      return;
    }

    setState(() {
      isAdminLogin = false;
    });

    if (mobile.length != 10) return;

    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('faculty').where('mobile', isEqualTo: mobile).get();

    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      nameController.text = doc['name'];
      selectedBranch = doc['branch'];
      selectedBus = doc['busNo'];
      facultyType = doc['facultyType'];
      isExistingFaculty = true;
    } else {
      nameController.clear();
      selectedBranch = null;
      selectedBus = null;
      facultyType = null;
      isExistingFaculty = false;
    }

    setState(() {
      isLoading = false;
    });
  }

  /// ===============================
  /// ADMIN LOGIN
  /// ===============================
  void adminLogin() {
    if (adminPasswordController.text == adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboard(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong Password")),
      );
    }
  }

  /// ===============================
  /// GENERATE FACULTY ID
  /// ===============================
  Future<String> generateFacultyId() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('faculty').get();
    int count = snapshot.docs.length + 1;
    return "faculty-${count.toString().padLeft(3, '0')}";
  }

  /// ===============================
  /// SEND OTP / LOGIN
  /// ===============================
  void sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    if (isExistingFaculty) {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('faculty').where('mobile', isEqualTo: mobileController.text).get();

      var doc = snapshot.docs.first;
      await saveFacultyLocally(doc);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${mobileController.text}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        registerFaculty();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "OTP Failed")),
        );
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          otpSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP Sent")));
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );

    setState(() {
      isLoading = false;
    });
  }

  /// ===============================
  /// VERIFY OTP
  /// ===============================
  void verifyOTP() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpController.text,
    );

    await _auth.signInWithCredential(credential);
    registerFaculty();
  }

  /// ===============================
  /// REGISTER FACULTY
  /// ===============================
  Future<void> registerFaculty() async {
    String facultyId = await generateFacultyId();

    await FirebaseFirestore.instance.collection('faculty').doc(facultyId).set({
      "id": facultyId,
      "name": nameController.text.trim(),
      "mobile": mobileController.text.trim(),
      "branch": facultyType == "College" ? selectedBranch : null,
      "busNo": selectedBus,
      "facultyType": facultyType,
      "createdAt": FieldValue.serverTimestamp()
    });

    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('faculty').doc(facultyId).get();

    await saveFacultyLocally(doc);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentDashboard()),
    );
  }

  /// ===============================
  /// SAVE LOCAL
  /// ===============================
  Future<void> saveFacultyLocally(DocumentSnapshot doc) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('loggedIn', true);
    await prefs.setString('role', 'Faculty');

    await prefs.setString('id', doc['id']);
    await prefs.setString('name', doc['name']);
    await prefs.setString('mobile', doc['mobile']);
    await prefs.setString('busNo', doc['busNo']);
    await prefs.setString('branch', doc['branch'] ?? "");
    await prefs.setString('facultyType', doc['facultyType']);
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),

      // ================= BOTTOM BANNER =================
      bottomNavigationBar: _isAdLoaded
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,

      appBar: AppBar(
        title: const Text("Faculty Login / Register"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Faculty Login",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  /// MOBILE FIELD
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Mobile Number",
                      prefixText: "+91 ",
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10)
                    ],
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Enter mobile";
                      if (val.length != 10) return "Invalid number";
                      return null;
                    },
                    onChanged: onMobileChanged,
                    readOnly: isExistingFaculty,
                  ),

                  const SizedBox(height: 20),

                  /// ADMIN LOGIN
                  if (isAdminLogin) ...[
                    TextField(
                      controller: adminPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Admin Password",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: adminLogin,
                        child: const Text("Admin Login"),
                      ),
                    ),
                  ]

                  /// NORMAL FACULTY FORM
                  else ...[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (!isExistingFaculty && (val == null || val.isEmpty))
                          return "Enter name";
                        return null;
                      },
                      readOnly: isExistingFaculty,
                    ),

                    const SizedBox(height: 15),

                    Column(
                      children: [
                        const Text(
                          "Faculty Type",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RadioListTile<String>(
                          title: const Text("College"),
                          value: "College",
                          groupValue: facultyType,
                          onChanged: isExistingFaculty
                              ? null
                              : (val) {
                                  setState(() {
                                    facultyType = val;
                                    selectedBranch = null;
                                  });
                                },
                        ),
                        RadioListTile<String>(
                          title: const Text("School"),
                          value: "School",
                          groupValue: facultyType,
                          onChanged: isExistingFaculty
                              ? null
                              : (val) {
                                  setState(() {
                                    facultyType = val;
                                    selectedBranch = null;
                                  });
                                },
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (facultyType == "College")
                      DropdownButtonFormField<String>(
                        initialValue: selectedBranch,
                        decoration: const InputDecoration(
                          labelText: "Branch",
                          border: OutlineInputBorder(),
                        ),
                        items: branchList
                            .map((branch) => DropdownMenuItem(
                                  value: branch,
                                  child: Text(branch),
                                ))
                            .toList(),
                        onChanged: isExistingFaculty
                            ? null
                            : (val) {
                                setState(() {
                                  selectedBranch = val;
                                });
                              },
                        validator: (val) =>
                            val == null ? "Select branch" : null,
                      ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: selectedBus,
                      decoration: const InputDecoration(
                        labelText: "Bus No",
                        border: OutlineInputBorder(),
                      ),
                      items: busList
                          .map((bus) => DropdownMenuItem(
                                value: bus,
                                child: Text("Bus $bus"),
                              ))
                          .toList(),
                      onChanged: isExistingFaculty
                          ? null
                          : (val) {
                              setState(() {
                                selectedBus = val;
                              });
                            },
                      validator: (val) => val == null ? "Select bus" : null,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : sendOTP,
                        child: Text(isExistingFaculty ? "Login" : "Send OTP"),
                      ),
                    ),

                    if (otpSent) ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: "Enter OTP",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: verifyOTP,
                          child: const Text("Verify OTP"),
                        ),
                      )
                    ]
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}