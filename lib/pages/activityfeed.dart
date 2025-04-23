// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/pages/home.dart';
import 'package:testt/widgets/header.dart';
import 'package:testt/widgets/progress.dart';

class ActivityFeed extends StatefulWidget {
  const ActivityFeed({super.key});

  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  getActiviyFeed() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance
            .collection('feed')
            .doc(currentUser.id)
            .collection("feedItems")
            .orderBy("timestamp", descending: true)
            .limit(50)
            .get();
    snapshot.docs.forEach((doc) {
      print("Activity Feed Item: ${doc.data}");
    });

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Activity Feed"),
      body: FutureBuilder(
        future: getActiviyFeed(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          return Text("Activity Feed");
        },
      ),
    );
  }
}

class ActivityFeedItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Activity Feed Item');
  }
}
