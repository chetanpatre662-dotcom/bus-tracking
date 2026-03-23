import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverApprovalScreen extends StatelessWidget {

  approveDriver(String id) async {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(id)
        .update({'approved': true});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("Driver Approval")),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('approved', isEqualTo: false)
            .snapshots(),

        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {

         if (!snapshot.hasData) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

          return ListView(
            children: snapshot.data!.docs.map((doc) {

              return ListTile(
                title: Text(doc['name']),
                subtitle: Text(doc['mobile']),
                trailing: ElevatedButton(
                  child: Text("Approve"),
                  onPressed: () {
                    approveDriver(doc.id);
                  },
                ),
              );

            }).toList(),
          );
        },
      ),
    );
  }
}