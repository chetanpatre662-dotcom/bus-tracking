import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriversListScreen extends StatelessWidget {
  const DriversListScreen({super.key});

  // DELETE DRIVER
  Future<void> deleteDriver(String id) async {
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(id)
        .delete();
  }

  // CONFIRM DELETE DIALOG
  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove Driver"),
          content: const Text("Are you sure you want to remove this driver?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                deleteDriver(id);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Driver Removed Successfully"),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Drivers List"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('approved', isEqualTo: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var drivers = snapshot.data!.docs;

          if (drivers.isEmpty) {
            return const Center(child: Text("No Drivers Found"));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {

              var driver = drivers[index];
              String driverId = driver.id;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  title: Text(driver['name'] ?? ""),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("📱 Mobile: ${driver['mobile'] ?? ""}"),
                      Text("🚌 Bus No: ${driver['busNo'] ?? ""}"),

                    ],
                  ),

                  // REMOVE BUTTON
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      confirmDelete(context, driverId);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}