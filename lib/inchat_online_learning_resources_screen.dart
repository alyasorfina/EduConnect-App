import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class InchatOnlineLearningResourcesScreen extends StatefulWidget {
  final String chatId;
  final bool isCurrentUserTutor;

  const InchatOnlineLearningResourcesScreen({
    super.key,
    required this.chatId,
    required this.isCurrentUserTutor,
  });

  @override
  State<InchatOnlineLearningResourcesScreen> createState() =>
      _InchatOnlineLearningResourcesScreenState();
}

class _InchatOnlineLearningResourcesScreenState
    extends State<InchatOnlineLearningResourcesScreen> {
  String? subject;
  List<LearningMaterial> learningMaterials = []; // Changed to use custom class
  bool isCurrentUserTutor = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjectAndMaterials();
    _checkIfUserIsTutor();
  }

  // Define a class to hold the learning material data

  Future<void> _checkIfUserIsTutor() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        setState(() {
          isCurrentUserTutor = role == 'Tutor';
        });
      }
    } catch (e) {
      print("Error checking user role: $e");
    }
  }

  Future<void> _fetchSubjectAndMaterials() async {
    try {
      final tutorId = FirebaseAuth.instance.currentUser!.uid;
      final qualificationDoc = await FirebaseFirestore.instance
          .collection('qualifications')
          .doc(tutorId)
          .get();

      if (qualificationDoc.exists) {
        setState(() {
          subject = qualificationDoc.data()?['subject'] ?? 'Unknown Subject';
        });
      }

      final learningMaterialsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('learning_material')
          .get();

      final materials = learningMaterialsSnapshot.docs
          .map((doc) => LearningMaterial.fromMap(doc.data()))
          .toList();

      setState(() {
        learningMaterials = materials;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> _uploadPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pdfPath = result.files.first.path!;
        final fileName = result.files.first.name;

        final uri = Uri.parse('http://10.0.2.2:5001/upload');
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('file', pdfPath));

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final fileUrl = jsonDecode(responseData)['filePath'];

          final chatDoc =
              FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

          final learningMaterialDoc =
              chatDoc.collection('learning_material').doc(subject);

          await learningMaterialDoc.set(
            {
              'subject': subject,
              'pdf': FieldValue.arrayUnion([fileUrl]),
            },
            SetOptions(merge: true),
          );

          setState(() {
            learningMaterials.add(LearningMaterial(pdfList: [fileUrl]));
          });

          final chatSnapshot = await chatDoc.get();
          final participants =
              List<String>.from(chatSnapshot.data()?['participants'] ?? []);

          final userId = FirebaseAuth.instance.currentUser!.uid;

          final studentId = participants.firstWhere((id) => id != userId);

          final userDoc =
              FirebaseFirestore.instance.collection('users').doc(studentId);

          await userDoc.collection('learning_materials').doc(subject).set(
            {
              'subject': subject,
              'pdf': FieldValue.arrayUnion([fileUrl]),
            },
            SetOptions(merge: true),
          );
        }
      }
    } catch (e) {
      print('Error uploading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Learning Materials"),
      ),
      body: learningMaterials.isEmpty
          ? const Center(child: Text("No learning materials available."))
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: learningMaterials.length,
                itemBuilder: (context, index) {
                  final material = learningMaterials[index];
                  final pdfList = material.pdfList;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2,
                        ),
                        itemCount: pdfList.length,
                        itemBuilder: (context, i) {
                          final pdfUrl = pdfList[i];
                          return Card(
                            child: InkWell(
                              onTap: () async {
                                if (await canLaunch(pdfUrl)) {
                                  await launch(pdfUrl);
                                } else {
                                  print("Could not launch $pdfUrl");
                                }
                              },
                              child: Center(
                                child: Text(
                                  Uri.parse(pdfUrl).pathSegments.last,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
      floatingActionButton: isCurrentUserTutor
          ? FloatingActionButton(
              onPressed: _uploadPdf,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.add,
                color: Colors.deepPurple,
              ),
            )
          : null,
    );
  }
}

class LearningMaterial {
  final List<String> pdfList;

  LearningMaterial({required this.pdfList});

  factory LearningMaterial.fromMap(Map<String, dynamic> map) {
    return LearningMaterial(
      pdfList: (map['pdf'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pdf': pdfList,
    };
  }
}
