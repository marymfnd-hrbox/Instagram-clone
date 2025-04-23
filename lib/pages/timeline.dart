// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/widgets/header.dart';

final userRef = FirebaseFirestore.instance.collection("users");

class Timeline extends StatefulWidget {
  const Timeline({super.key});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true, 
      titleText: "FlutterShare"),
      body: Text("Timeline"),
    );
  }

}

/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/widgets/header.dart';
import 'package:testt/widgets/progress.dart';

final userRef = FirebaseFirestore.instance.collection("users");

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  void initState() {
    updateUser();
    super.initState();
  }

  createUser() async{
    await userRef.add({
      "username": "Jeff",
      "postCount": 0,
      "isAdmin": false,
    });

  }

  updateUser() async {
  final doc = await userRef.doc("s9fJZPSmmnbCnEQcayix").get();
  if (doc.exists){
    doc.reference.update({
    "username": "Mayede",
    "postCount": 9,
    "isAdmin": false,
  });
  }
  
  /* .update({
    "username": "John",
    "postCount": 9,
    "isAdmin": false,
  });
  */
}

  deleteUser() async{
    final DocumentSnapshot doc = await userRef.doc("s9fJZPSmmnbCnEQcayix").get();
    if (doc.exists){
    doc.reference.delete();
  }}


  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true, 
      titleText: "Timeline"),
      body: StreamBuilder<QuerySnapshot>(
        stream: userRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          final List<Text> children =
              snapshot.data!.docs
                  .map((doc) => Text(doc['username']))
                  .toList();
          return Container(child: ListView(children: children));
        },
      ),
    );
  }
}
*/















/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/widgets/header.dart';
import 'package:testt/widgets/progress.dart';

final userRef = FirebaseFirestore.instance.collection("users");

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<dynamic> users = [];

  @override
  void initState() {
    getUsers();
    super.initState();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true, titleText: "Timeline"),
      body:
          users.isEmpty
              ? circularProgress()
              : Container(
                child: ListView(
                  children:
                      users.map((doc) {
                        final user = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(user['username'] ?? 'No Username'),
                        );
                      }).toList(),
                ),
              ),
    );
  }

  getUsers() async {
    final QuerySnapshot snapshot = await userRef.get();

    setState(() {
      users = snapshot.docs;
    });

    // final QuerySnapshot adminSnapshot = await userRef.where("isAdmin",isEqualTo: true).get();

    /* for (var doc in snapshot.docs) {
    print(doc.data());
    print(doc.id);
    print(doc.exists);
  } */
  }
}

/* userRef.get().then((QuerySnapshot snapshot){
    snapshot.docs.forEach((DocumentSnapshot doc){
    print(doc.data());
    print(doc.id);
    print(doc.exists);
    });
  }); */

*/