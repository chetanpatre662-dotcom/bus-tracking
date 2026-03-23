import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusStudentsScreen extends StatefulWidget {
  const BusStudentsScreen({super.key});

  @override
  State<BusStudentsScreen> createState() => _BusStudentsScreenState();
}

class _BusStudentsScreenState extends State<BusStudentsScreen> {

  String selectedBus = "All";
  List<String> busList = ["All"];

  @override
  void initState() {
    super.initState();
    loadBusNumbers();
  }

  /// Load bus numbers dynamically
  Future<void> loadBusNumbers() async {

    var btech = await FirebaseFirestore.instance
        .collection('students_btech')
        .get();

    var poly = await FirebaseFirestore.instance
        .collection('students_poly')
        .get();

    Set<String> buses = {};

    for (var doc in btech.docs) {
      buses.add(doc['busNo'].toString());
    }

    for (var doc in poly.docs) {
      buses.add(doc['busNo'].toString());
    }

    setState(() {
      busList = ["All", ...buses];
    });
  }

  Future<List<QueryDocumentSnapshot>> getStudents() async {

    var btech = await FirebaseFirestore.instance
        .collection('students_btech')
        .get();

    var poly = await FirebaseFirestore.instance
        .collection('students_poly')
        .get();

    List<QueryDocumentSnapshot> allStudents = [];

    allStudents.addAll(btech.docs);
    allStudents.addAll(poly.docs);

    if (selectedBus == "All") {
      return allStudents;
    }

    return allStudents.where((student) {
      return student['busNo'].toString() == selectedBus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Bus Wise Students"),
      ),

      body: Column(
        children: [

          /// Bus Dropdown
          Padding(
            padding: const EdgeInsets.all(10),

            child: DropdownButtonFormField(
              initialValue: selectedBus,

              decoration: const InputDecoration(
                labelText: "Select Bus No",
                border: OutlineInputBorder(),
              ),

              items: busList.map((bus) {

                return DropdownMenuItem(
                  value: bus,
                  child: Text("Bus $bus"),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {
                  selectedBus = value.toString();
                });

              },
            ),
          ),

          /// Students List
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(

              future: getStudents(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var students = snapshot.data!;

                if (students.isEmpty) {
                  return const Center(
                    child: Text("No Students Found"),
                  );
                }

                return ListView.builder(

                  itemCount: students.length,

                  itemBuilder: (context, index) {

                    var student = students[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),

                      child: ListTile(

                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),

                        title: Text(student['name']),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text("Branch: ${student['branch']}"),

                            Text("Mobile: ${student['mobile']}"),

                            Text("City: ${student['city']}"),

                            Text("Bus No: ${student['busNo']}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}