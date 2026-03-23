import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // ✅ ADDED
import 'driver_register.dart';
import 'faculty_register.dart';
import 'student_register.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {

  // =========================
  // 🔥 BANNER AD
  // =========================
  BannerAd? _bannerAd;
  bool isAdLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: "ca-app-pub-3940256099942544/6300978111", // TEST AD
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
    loadAd(); // ✅ LOAD AD
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // ✅ CLEANUP
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Role"),
        centerTitle: true, // Center the title
        automaticallyImplyLeading: false, // Back button remove
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RoleButton(
                    role: "Driver",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverRegisterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  RoleButton(
                    role: "Faculty",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const FacultyRegisterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  RoleButton(
                    role: "Student / Parents",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentRegisterScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔥 BANNER AD (BOTTOM)
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

class RoleButton extends StatelessWidget {
  final String role;
  final VoidCallback onTap;
  const RoleButton({super.key, required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(role),
    );
  }
}