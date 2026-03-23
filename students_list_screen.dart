import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {

  String searchText = "";
  String selectedCourse = "All";
  String selectedBranch = "All";

  final List<String> courses = [
    "All",
    "BTech",
    "Poly"
  ];

  final List<String> branches = [
    "All",
    "Civil",
    "Mechanical",
    "Electrical",
    "Computer Science",
    "Mining"
  ];

  // DELETE STUDENT
  Future<void> deleteStudent(String collection, String id) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(id)
        .delete();
  }

  // CONFIRM DELETE
  void confirmDelete(String collection, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remove Student"),
          content: const Text("Are you sure you want to remove this student?"),
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
                deleteStudent(collection, id);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Student Removed Successfully"),
                  ),
                );
              },
            ),

          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> getStudents() async {

    var btech = await FirebaseFirestore.instance
        .collection('students_btech')
        .get();

    var poly = await FirebaseFirestore.instance
        .collection('students_poly')
        .get();

    List<Map<String, dynamic>> allStudents = [];

    if (selectedCourse == "All" || selectedCourse == "BTech") {

      for (var doc in btech.docs) {
        allStudents.add({
          "data": doc,
          "collection": "students_btech"
        });
      }

    }

    if (selectedCourse == "All" || selectedCourse == "Poly") {

      for (var doc in poly.docs) {
        allStudents.add({
          "data": doc,
          "collection": "students_poly"
        });
      }

    }

    return allStudents;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Students"),
        centerTitle: true,
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getStudents(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var students = snapshot.data!;

          var filteredStudents = students.where((student) {

            var data = student["data"];

            String name =
                data['name'].toString().toLowerCase();

            String branch =
                data['branch'].toString();

            bool searchMatch =
                name.contains(searchText);

            bool branchMatch =
                selectedBranch == "All" ||
                branch == selectedBranch;

            return searchMatch && branchMatch;

          }).toList();

          return Column(
            children: [

              // TOTAL STUDENTS CARD
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    const Text(
                      "Total Students",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),

                    Text(
                      filteredStudents.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),

                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search Student",
                    prefixIcon:
                        const Icon(Icons.search),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  onChanged: (value) {
                    setState(() {
                      searchText =
                          value.toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              // FILTERS
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12),

                child: Row(
                  children: [

                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: selectedCourse,
                        decoration:
                            const InputDecoration(
                          labelText: "Course",
                          border:
                              OutlineInputBorder(),
                        ),

                        items: courses
                            .map((course) =>
                                DropdownMenuItem(
                                  value: course,
                                  child: Text(course),
                                ))
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedCourse =
                                value!;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: DropdownButtonFormField(
                        initialValue: selectedBranch,
                        decoration:
                            const InputDecoration(
                          labelText: "Branch",
                          border:
                              OutlineInputBorder(),
                        ),

                        items: branches
                            .map((branch) =>
                                DropdownMenuItem(
                                  value: branch,
                                  child:
                                      Text(branch),
                                ))
                            .toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedBranch =
                                value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // STUDENTS LIST
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(
                        child: Text(
                          "No Students Found",
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            filteredStudents.length,

                        itemBuilder:
                            (context, index) {

                          var student =
                              filteredStudents[
                                  index];

                          var data =
                              student["data"];

                          String collection =
                              student["collection"];

                          String id = data.id;

                          return Card(
                            margin:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),

                            child: ListTile(
                              leading:
                                  const CircleAvatar(
                                child: Icon(
                                    Icons.person),
                              ),

                              title: Text(
                                  data['name']),

                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [

                                  Text(
                                      "📱 Mobile: ${data['mobile']}"),

                                  Text(
                                      "🏫 Branch: ${data['branch']}"),

                                  Text(
                                      "🚌 Bus: ${data['busNo']}"),

                                  Text(
                                      "🏠 City: ${data['city']}"),
                                ],
                              ),

                              // REMOVE BUTTON
                              trailing:
                                  IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color:
                                      Colors.red,
                                ),
                                onPressed: () {
                                  confirmDelete(
                                      collection,
                                      id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}