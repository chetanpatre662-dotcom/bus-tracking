import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ ADDED
import 'driver_dashboard.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final otpController = TextEditingController();
  final routeController = TextEditingController();

  String? selectedBus;
  String verificationId = "";

  bool otpSent = false;
  bool isLoading = false;
  bool isExistingDriver = false;

  String? driverDocId;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> busList =
      List.generate(15, (index) => (index + 1).toString());

  // =========================
  // 🔥 BANNER AD
  // =========================
  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: "ca-app-pub-9332148976634523/7351534762", // TEST ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            isAdLoaded = true;
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
  void initState() {
    super.initState();
    checkIfLoggedIn();
    loadAd(); // ✅ AD LOAD
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // ✅ CLEANUP
    super.dispose();
  }

  // =========================
  // AUTO LOGIN CHECK
  // =========================

  Future<void> checkIfLoggedIn() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    if (prefs.getString('driverId') != null) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverDashboard(),
        ),
      );
    }
  }

  // =========================
  // MOBILE NUMBER CHANGE
  // =========================

  void onMobileChanged(String mobile) async {

    if (mobile.length == 10) {

      setState(() {
        isLoading = true;
      });

      QuerySnapshot driverQuery =
          await FirebaseFirestore.instance
              .collection('drivers')
              .where('mobile', isEqualTo: mobile)
              .get();

      if (driverQuery.docs.isNotEmpty) {

        var driver = driverQuery.docs.first;

        nameController.text = driver['name'];
        selectedBus = driver['busNo'];
        routeController.text = driver['route'];

        driverDocId = driver.id;

        isExistingDriver = true;

      } else {

        nameController.clear();
        routeController.clear();

        selectedBus = null;
        driverDocId = null;

        isExistingDriver = false;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // SEND OTP / LOGIN
  // =========================

  void sendOTP() async {

    if (!_formKey.currentState!.validate()) return;

    // ===== EXISTING DRIVER LOGIN =====

    if (isExistingDriver) {

      DocumentSnapshot driverDoc =
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(driverDocId)
              .get();

      bool approved = driverDoc['approved'] ?? false;

      if (!approved) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Admin approval pending")),
        );

        return;
      }

      await saveDriverLocally(driverDoc);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverDashboard(),
        ),
      );

      return;
    }

    // ===== NEW DRIVER REGISTER =====

    if (nameController.text.isEmpty ||
        selectedBus == null ||
        routeController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Fill all driver details")),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await _auth.verifyPhoneNumber(

        phoneNumber: "+91${mobileController.text}",

        verificationCompleted:
            (PhoneAuthCredential credential) async {

          await _auth.signInWithCredential(
              credential);

          registerDriver();
        },

        verificationFailed:
            (FirebaseAuthException e) {

          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content:
                  Text(e.message ??
                      "OTP Failed"),
            ),
          );
        },

        codeSent: (String verId,
            int? resendToken) {

          setState(() {

            verificationId = verId;
            otpSent = true;
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
                content:
                    Text("OTP Sent")),
          );
        },

        codeAutoRetrievalTimeout:
            (String verId) {

          verificationId = verId;
        },
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text("Error $e"),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // VERIFY OTP
  // =========================

  void verifyOTP() async {

    if (otpController.text.length != 6) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content: Text(
                "Enter valid OTP")),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text,
      );

      await _auth.signInWithCredential(
          credential);

      registerDriver();

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content: Text("Invalid OTP")),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // REGISTER DRIVER
  // =========================

  Future<void> registerDriver() async {

    String mobile = mobileController.text.trim();
    String name = nameController.text.trim();
    String busNo = selectedBus!;
    String route = routeController.text.trim();

    CollectionReference drivers =
        FirebaseFirestore.instance
            .collection('drivers');

    QuerySnapshot allDrivers =
        await drivers.get();

    int nextId = allDrivers.docs.length + 1;

    String newDriverId =
        "driver-${nextId.toString().padLeft(3, '0')}";

    await drivers.doc(newDriverId).set({

      'driverId': newDriverId,
      'name': name,
      'mobile': mobile,
      'busNo': busNo,
      'route': route,

      'approved': false,

      'createdAt':
          FieldValue.serverTimestamp(),

    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
          content: Text(
              "Registration successful. Wait for admin approval")),
    );

    setState(() {

      otpSent = false;
      driverDocId = newDriverId;
      isExistingDriver = true;
    });
  }

  // =========================
  // SAVE DRIVER LOCAL
  // =========================

  Future<void> saveDriverLocally(
      DocumentSnapshot driverDoc) async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
        'driverId', driverDoc['driverId']);

    await prefs.setString(
        'name', driverDoc['name']);

    await prefs.setString(
        'mobile', driverDoc['mobile']);

    await prefs.setString(
        'busNo', driverDoc['busNo']);

    await prefs.setString(
        'route', driverDoc['route']);

    await prefs.setString(
        'role', 'Driver');
    await prefs.setBool(
        'loggedIn', true);
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xfff4f7fb),

      appBar: AppBar(

        title: const Text(
            "Driver Login / Register"),

        backgroundColor:
            const Color(0xff0d6efd),
      ),

      body: Column(
        children: [

          Expanded(
            child: Center(

              child: SingleChildScrollView(

                padding:
                    const EdgeInsets.all(20),

                child: Container(

                  padding:
                      const EdgeInsets.all(20),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(16),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black
                            .withOpacity(0.08),

                        blurRadius: 10,
                      )
                    ],
                  ),

                  child: Form(

                    key: _formKey,

                    child: Column(

                      mainAxisSize:
                          MainAxisSize.min,

                      children: [

                        const Text(

                          "Driver Login / Register",

                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                            height: 20),

                        TextFormField(

                          controller:
                              mobileController,

                          keyboardType:
                              TextInputType
                                  .number,

                          decoration:
                              const InputDecoration(

                            labelText:
                                "Mobile Number",

                            prefixIcon:
                                Icon(Icons.phone),

                            prefixText:
                                "+91 ",

                            border:
                                OutlineInputBorder(),
                          ),

                          inputFormatters: [

                            FilteringTextInputFormatter
                                .digitsOnly,

                            LengthLimitingTextInputFormatter(
                                10),
                          ],

                          validator: (val) {

                            if (val == null ||
                                val.isEmpty)
                              return "Required";

                            if (val.length != 10)
                              return "Enter 10 digit number";

                            return null;
                          },

                          onChanged:
                              onMobileChanged,
                        ),

                        const SizedBox(
                            height: 15),

                        if (!isExistingDriver)

                          TextFormField(

                            controller:
                                nameController,

                            decoration:
                                const InputDecoration(

                              labelText:
                                  "Full Name",

                              prefixIcon:
                                  Icon(Icons.person),

                              border:
                                  OutlineInputBorder(),
                            ),
                          ),

                        const SizedBox(
                            height: 15),

                        if (!isExistingDriver)

                          DropdownButtonFormField<String>(

                            initialValue: selectedBus,

                            decoration:
                                const InputDecoration(

                              labelText:
                                  "Bus Number",

                              prefixIcon:
                                  Icon(Icons
                                      .directions_bus),

                              border:
                                  OutlineInputBorder(),
                            ),

                            items: busList
                                .map((bus) {

                              return DropdownMenuItem(

                                value: bus,

                                child:
                                    Text("Bus $bus"),
                              );
                            }).toList(),

                            onChanged: (val) {

                              setState(() {

                                selectedBus =
                                    val;
                              });
                            },
                          ),

                        const SizedBox(
                            height: 15),

                        if (!isExistingDriver)

                          TextFormField(

                            controller:
                                routeController,

                            decoration:
                                const InputDecoration(

                              labelText:
                                  "Route",

                              prefixIcon:
                                  Icon(Icons.map),

                              border:
                                  OutlineInputBorder(),
                            ),
                          ),

                        const SizedBox(
                            height: 20),

                        SizedBox(

                          width:
                              double.infinity,

                          child:
                              ElevatedButton(

                            onPressed:
                                isLoading
                                    ? null
                                    : sendOTP,

                            style:
                                ElevatedButton
                                    .styleFrom(

                              backgroundColor:
                                  Colors.orange,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                          vertical:
                                              14),
                            ),

                            child: Text(

                              isExistingDriver
                                  ? "Login"
                                  : otpSent
                                      ? "Resend OTP"
                                      : "Send OTP",

                              style:
                                  const TextStyle(
                                      fontSize:
                                          16),
                            ),
                          ),
                        ),

                        if (otpSent)
                          const SizedBox(
                              height: 15),

                        if (otpSent)

                          TextField(

                            controller:
                                otpController,

                            keyboardType:
                                TextInputType
                                    .number,

                            maxLength: 6,

                            decoration:
                                const InputDecoration(

                              labelText:
                                  "Enter OTP",

                              border:
                                  OutlineInputBorder(),

                              counterText:
                                  "",
                            ),
                          ),

                        if (otpSent)

                          SizedBox(

                            width:
                                double.infinity,

                            child:
                                ElevatedButton(

                              onPressed:
                                  verifyOTP,

                              style:
                                  ElevatedButton
                                      .styleFrom(

                                backgroundColor:
                                    Colors.black,

                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                            vertical:
                                                14),
                              ),

                              child:
                                  const Text(
                                "Verify OTP",
                                style: TextStyle(
                                    fontSize:
                                        16),
                              ),
                            ),
                          ),

                        if (isLoading)

                          const Padding(

                            padding:
                                EdgeInsets.only(
                                    top: 20),

                            child:
                                CircularProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🔥 AD SECTION
          if (isAdLoaded)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}