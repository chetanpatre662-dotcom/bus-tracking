import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'students_list_screen.dart';
import 'faculty_list_screen.dart';
import 'parents_list_screen.dart';
import 'drivers_list_screen.dart';
import 'bus_students_screen.dart';
import 'live_bus_location.dart';
import 'driver_approval_screen.dart';
import 'role_selection_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  int totalStudents = 0;
  int totalFaculty = 0;
  int totalParents = 0;
  int totalDrivers = 0;

  @override
  void initState() {
    super.initState();
    getCounts();
  }

  Future<void> getCounts() async {

    var btech = await FirebaseFirestore.instance
        .collection('students_btech')
        .get();

    var poly = await FirebaseFirestore.instance
        .collection('students_poly')
        .get();

    var faculty = await FirebaseFirestore.instance
        .collection('faculty')
        .get();

    var parents = await FirebaseFirestore.instance
        .collection('parents')
        .get();

    var drivers = await FirebaseFirestore.instance
        .collection('drivers')
        .get();

    setState(() {

      totalStudents = btech.docs.length + poly.docs.length;
      totalFaculty = faculty.docs.length;
      totalParents = parents.docs.length;
      totalDrivers = drivers.docs.length;

    });
  }

  Widget dashboardCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap) {

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(
                icon,
                size: 40,
                color: color,
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget countCard(
      String title,
      int count,
      IconData icon,
      Color color) {

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Icon(
              icon,
              size: 40,
              color: color,
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          children: [

            /// COUNT CARDS
            Row(
              children: [

                Expanded(
                  child: countCard(
                    "Students",
                    totalStudents,
                    Icons.people,
                    Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: countCard(
                    "Faculty",
                    totalFaculty,
                    Icons.school,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [

                Expanded(
                  child: countCard(
                    "Parents",
                    totalParents,
                    Icons.family_restroom,
                    Colors.orange,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: countCard(
                    "Drivers",
                    totalDrivers,
                    Icons.drive_eta,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// DASHBOARD GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,

                children: [

                  dashboardCard(
                    "Students List",
                    Icons.people_alt,
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              StudentsListScreen(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Faculty List",
                    Icons.school,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FacultyListScreen(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Parents List",
                    Icons.family_restroom,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ParentsListScreen(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Drivers List",
                    Icons.drive_eta,
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DriversListScreen(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Bus Wise Students",
                    Icons.directions_bus,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BusStudentsScreen(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Live Bus Location",
                    Icons.location_on,
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LiveBusLocation(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Driver Approval",
                    Icons.verified_user,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DriverApprovalScreen(),
                        ),
                      );
                    },
                  ),

                  dashboardCard(
                    "Logout",
                    Icons.logout,
                    Colors.black,
                    () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RoleSelectionScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}