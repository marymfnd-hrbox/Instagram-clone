import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/pages/home.dart';
import 'package:testt/widgets/header.dart';
import 'package:testt/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
  });

  @override
  // ignore: no_logic_in_create_state
  CommentsState createState() => CommentsState(
    postId: postId,
    postOwnerId: postOwnerId,
    postMediaUrl: postMediaUrl,
  );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();

  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    required this.postId,
    required this.postOwnerId,
    required this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection("comments")
              .doc(postId)
              .collection("comments")
              .orderBy("timestamp", descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data!.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(children: comments);
      },
    );
  }

  addComment() {
    FirebaseFirestore.instance
        .collection("comments")
        .doc(postId)
        .collection("comments")
        .add({
          "username": currentUser.username,
          "comment": commentController.text,
          "timestamp": timestamp,
          "avatarUrl": currentUser.photoURL,
          "userId": currentUser.id,
        });
        bool isNotPostOwner = postOwnerId != currentUser.id;
        
        if (isNotPostOwner){
          FirebaseFirestore.instance
        .collection("feed")
        .doc(postOwnerId)
        .collection("feedItems")
        .add({
          "type": "comment",
          "comment": commentController.text,
          "username": currentUser.username,
          "userId": currentUser.id,
          "userProfileImg": currentUser.photoURL,
          "postId": postId,
          "mediaUrl": postMediaUrl,
          "timestamp": timestamp,
        });
        }
    

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment ..."),
            ),
            trailing: OutlinedButton(
              onPressed: addComment,
              style: OutlinedButton.styleFrom(side: BorderSide.none),
              child: Text("Post"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc["username"],
      userId: doc["userId"],
      avatarUrl: doc["avatarUrl"],
      comment: doc["comment"],
      timestamp: doc["timestamp"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
