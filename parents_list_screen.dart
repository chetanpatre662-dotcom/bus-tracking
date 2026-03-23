import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentsListScreen extends StatelessWidget {
  const ParentsListScreen({super.key});

  // DELETE FUNCTION
  Future<void> deleteParent(String id) async {
    await FirebaseFirestore.instance
        .collection('parents')
        .doc(id)
        .delete();
  }

  // CONFIRM DELETE DIALOG
  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove Parent"),
          content: const Text("Are you sure you want to remove this parent?"),
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
                deleteParent(id);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Parent Removed Successfully"),
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
        title: const Text("Parents List"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parents')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var parents = snapshot.data!.docs;

          if (parents.isEmpty) {
            return const Center(
              child: Text("No Parents Found"),
            );
          }

          return ListView.builder(
            itemCount: parents.length,
            itemBuilder: (context, index) {

              var parent = parents[index];
              String parentId = parent.id;

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),

                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  title: Text(parent['name'] ?? ""),

                  subtitle: Text(parent['mobile'] ?? ""),

                  // REMOVE BUTTON
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),

                    onPressed: () {
                      confirmDelete(context, parentId);
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