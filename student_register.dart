import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'student_dashboard.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {

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
      adUnitId: 'ca-app-pub-9332148976634523/7351534762', //  Banner Ad
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

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final cityController = TextEditingController();
  final otpController = TextEditingController();

  String? selectedBus;
  String? role;
  String? course;
  String? branch;
  String? year;
  String? studentType; // College / School
  String? schoolClass; // 4-12

  bool otpSent = false;
  bool isExistingUser = false;

  String verificationId = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> busList = List.generate(15, (i) => (i + 1).toString());
  List<String> branches = [
    "Civil",
    "Mechanical",
    "Electrical",
    "Computer Science",
    "Mining"
  ];

  List<String> yearsPoly = ["1", "2", "3"];
  List<String> yearsBtech = ["1", "2", "3", "4"];
  List<String> schoolClasses = List.generate(9, (i) => (i + 4).toString()); // 4-12

  // ================= CHECK EXISTING USER =================
  Future<void> checkExistingUser(String mobile) async {
    if (mobile.length != 10) return;

    // ----- Parent Check -----
    var parent = await FirebaseFirestore.instance
        .collection('parents')
        .where('mobile', isEqualTo: mobile)
        .get();

    if (parent.docs.isNotEmpty) {
      var data = parent.docs.first;
      setState(() {
        isExistingUser = true;
        role = "parent";
        nameController.text = data['name'];
        cityController.text = data['city'];
        selectedBus = data['busNo'];
      });
      return;
    }

    // ----- Polytechnic Student -----
    var poly = await FirebaseFirestore.instance
        .collection('students_poly')
        .where('mobile', isEqualTo: mobile)
        .get();

    if (poly.docs.isNotEmpty) {
      var data = poly.docs.first;
      setState(() {
        isExistingUser = true;
        role = "student";
        studentType = "college";
        course = "poly";
        nameController.text = data['name'];
        cityController.text = data['city'];
        selectedBus = data['busNo'];
        branch = data['branch'];
        year = data['year'];
      });
      return;
    }

    // ----- BTech Student -----
    var btech = await FirebaseFirestore.instance
        .collection('students_btech')
        .where('mobile', isEqualTo: mobile)
        .get();

    if (btech.docs.isNotEmpty) {
      var data = btech.docs.first;
      setState(() {
        isExistingUser = true;
        role = "student";
        studentType = "college";
        course = "btech";
        nameController.text = data['name'];
        cityController.text = data['city'];
        selectedBus = data['busNo'];
        branch = data['branch'];
        year = data['year'];
      });
      return;
    }

    // ----- School Student -----
    var school = await FirebaseFirestore.instance
        .collection('students_school')
        .where('mobile', isEqualTo: mobile)
        .get();

    if (school.docs.isNotEmpty) {
      var data = school.docs.first;
      setState(() {
        isExistingUser = true;
        role = "student";
        studentType = "school";
        schoolClass = data['class'];
        nameController.text = data['name'];
        cityController.text = data['city'];
        selectedBus = data['busNo'];
      });
    }
  }

  // ================= ID GENERATOR =================
  Future<String> generateId(String type, String branch) async {
    String collection = "";
    if (type == "parent") collection = "parents";
    if (type == "poly") collection = "students_poly";
    if (type == "btech") collection = "students_btech";
    if (type == "school") collection = "students_school";

    QuerySnapshot snap =
        await FirebaseFirestore.instance.collection(collection).get();

    int count = snap.docs.length + 1;
    branch = branch.replaceAll(" ", "");

    if (type == "parent") return "PARENT${count.toString().padLeft(3, '0')}";
    if (type == "poly") return "POLY${branch}${count.toString().padLeft(3, '0')}";
    if (type == "btech") return "BTECH${branch}${count.toString().padLeft(3, '0')}";
    if (type == "school") return "SCHOOL${count.toString().padLeft(3, '0')}";
    return "ID${count.toString().padLeft(3, '0')}";
  }

  // ================= SEND OTP =================
  void sendOTP() async {
    if (mobileController.text.length != 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter valid mobile number")));
      return;
    }

    if (nameController.text.isEmpty || cityController.text.isEmpty || selectedBus == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (role == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select role")));
      return;
    }

    if (role == "student") {
      if (studentType == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Select student type")));
        return;
      }
      if (studentType == "college" && (course == null || branch == null || year == null)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Complete student details")));
        return;
      }
      if (studentType == "school" && schoolClass == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Select class")));
        return;
      }
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: "+91${mobileController.text}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        registerUser();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message!)));
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          otpSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  // ================= VERIFY OTP =================
  void verifyOTP() async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpController.text,
    );
    await _auth.signInWithCredential(credential);
    registerUser();
  }

  // ================= REGISTER / LOGIN =================
  void registerUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!isExistingUser) {
      if (role == "parent") {
        String id = await generateId("parent", "");
        await FirebaseFirestore.instance.collection('parents').doc(id).set({
          "id": id,
          "name": nameController.text,
          "mobile": mobileController.text,
          "city": cityController.text,
          "busNo": selectedBus
        });
      }

      if (role == "student") {
        if (studentType == "college") {
          String type = course == "poly" ? "students_poly" : "students_btech";
          String id = await generateId(course!, branch!);
          await FirebaseFirestore.instance.collection(type).doc(id).set({
            "id": id,
            "name": nameController.text,
            "mobile": mobileController.text,
            "city": cityController.text,
            "busNo": selectedBus,
            "branch": branch,
            "year": year
          });
        }
        if (studentType == "school") {
          String id = await generateId("school", "");
          await FirebaseFirestore.instance.collection("students_school").doc(id).set({
            "id": id,
            "name": nameController.text,
            "mobile": mobileController.text,
            "city": cityController.text,
            "busNo": selectedBus,
            "class": schoolClass
          });
        }
      }
    }

    await prefs.setBool("loggedIn", true);
    await prefs.setString("name", nameController.text);
    await prefs.setString("mobile", mobileController.text);
    await prefs.setString("busNo", selectedBus ?? "");
    await prefs.setString("role", role ?? "");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StudentDashboard()),
    );
  }

  // ================= INPUT STYLE =================
  InputDecoration fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f7fb),
      bottomNavigationBar: _isAdLoaded
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Text(
                  "Student / Parent Login",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: mobileController,
                  keyboardType: TextInputType.number,
                  onChanged: checkExistingUser,
                  enabled: !isExistingUser,
                  decoration: fieldStyle("Mobile Number", Icons.phone),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: nameController,
                  enabled: !isExistingUser,
                  decoration: fieldStyle("Name", Icons.person),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: cityController,
                  enabled: !isExistingUser,
                  decoration: fieldStyle("City", Icons.location_city),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedBus,
                  decoration: fieldStyle("Bus No", Icons.directions_bus),
                  items: busList
                      .map((b) => DropdownMenuItem(value: b, child: Text("Bus $b")))
                      .toList(),
                  onChanged: isExistingUser ? null : (v) => setState(() => selectedBus = v),
                ),
                const SizedBox(height: 20),
                RadioListTile(
                  title: const Text("Student"),
                  value: "student",
                  groupValue: role,
                  onChanged: isExistingUser ? null : (v) => setState(() => role = v.toString()),
                ),
                RadioListTile(
                  title: const Text("Parent"),
                  value: "parent",
                  groupValue: role,
                  onChanged: isExistingUser ? null : (v) => setState(() => role = v.toString()),
                ),

                if (role == "student") ...[
                  const SizedBox(height: 10),
                  RadioListTile(
                    title: const Text("College"),
                    value: "college",
                    groupValue: studentType,
                    onChanged: isExistingUser ? null : (v) => setState(() => studentType = v.toString()),
                  ),
                  RadioListTile(
                    title: const Text("School"),
                    value: "school",
                    groupValue: studentType,
                    onChanged: isExistingUser ? null : (v) => setState(() => studentType = v.toString()),
                  ),
                ],

                if (role == "student" && studentType == "college") ...[
                  RadioListTile(
                    title: const Text("BTech"),
                    value: "btech",
                    groupValue: course,
                    onChanged: isExistingUser ? null : (v) => setState(() => course = v.toString()),
                  ),
                  RadioListTile(
                    title: const Text("Polytechnic"),
                    value: "poly",
                    groupValue: course,
                    onChanged: isExistingUser ? null : (v) => setState(() => course = v.toString()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: branch,
                    decoration: fieldStyle("Branch", Icons.school),
                    items: branches
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: isExistingUser ? null : (v) => setState(() => branch = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: year,
                    decoration: fieldStyle("Year", Icons.calendar_today),
                    items: (course == "poly" ? yearsPoly : yearsBtech)
                        .map((y) => DropdownMenuItem(value: y, child: Text("Year $y")))
                        .toList(),
                    onChanged: isExistingUser ? null : (v) => setState(() => year = v),
                  ),
                ],

                if (role == "student" && studentType == "school") ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: schoolClass,
                    decoration: fieldStyle("Class", Icons.school),
                    items: schoolClasses
                        .map((c) => DropdownMenuItem(value: c, child: Text("Class $c")))
                        .toList(),
                    onChanged: isExistingUser ? null : (v) => setState(() => schoolClass = v),
                  ),
                ],

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isExistingUser ? registerUser : sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(isExistingUser ? "Login" : "Send OTP"),
                ),
                if (otpSent) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: fieldStyle("Enter OTP", Icons.lock),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0d6efd),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("Verify & Login"),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}