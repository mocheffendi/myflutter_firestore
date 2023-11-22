import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kebab/services/firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase FireStore',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Firebase FireStore',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FireStoreService firestoreService = FireStoreService();
  final TextEditingController controller = TextEditingController();

  String oldText = ''; // Added to store old text for updating

  // Function to fill the TextField for updating
  void fillTextFieldForUpdate(String documentId, String oldText) {
    setState(() {
      this.oldText = oldText;
      controller.text = oldText;
    });
  }

  void openNoteBox(String? docID) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: controller,
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      if (docID == null) {
                        firestoreService.addNote(controller.text);
                      } else {
                        firestoreService.updateNote(docID, controller.text);
                      }
                      controller.clear();

                      // close dialog
                      Navigator.pop(context);
                    },
                    child: const Text('add'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;
            return ListView.builder(
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];
                String docID = document.id;
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String noteText = data['note'];
                var noteTimeStamp = (data['timestamp'] as Timestamp).toDate();
                return ListTile(
                  title: Text(noteText),
                  subtitle: Text(noteTimeStamp.toString()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () {
                            openNoteBox(docID);
                            fillTextFieldForUpdate(docID, noteText);
                          },
                          icon: const Icon(Icons.edit)),
                      IconButton(
                          onPressed: () => firestoreService.deleteNote(docID),
                          icon: const Icon(Icons.delete)),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openNoteBox(null);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
