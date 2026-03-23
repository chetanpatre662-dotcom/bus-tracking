import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FacultyListScreen extends StatelessWidget {
  const FacultyListScreen({super.key});

  // DELETE FACULTY
  Future<void> deleteFaculty(String id) async {
    await FirebaseFirestore.instance
        .collection('faculty')
        .doc(id)
        .delete();
  }

  // CONFIRM DELETE
  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove Faculty"),
          content: const Text("Are you sure you want to remove this faculty?"),
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
                deleteFaculty(id);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Faculty Removed Successfully"),
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
        title: const Text("Faculty List"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faculty')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var faculty = snapshot.data!.docs;

          if (faculty.isEmpty) {
            return const Center(
              child: Text("No Faculty Found"),
            );
          }

          return ListView.builder(
            itemCount: faculty.length,
            itemBuilder: (context, index) {

              var data = faculty[index];
              String facultyId = data.id;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  title: Text(data['name'] ?? ""),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("📱 Mobile: ${data['mobile'] ?? ""}"),

                      Text("🏫 Branch: ${data['branch'] ?? ""}"),

                      Text("🚌 Bus No: ${data['busNo'] ?? ""}"),

                    ],
                  ),

                  // REMOVE BUTTON
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),

                    onPressed: () {
                      confirmDelete(context, facultyId);
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