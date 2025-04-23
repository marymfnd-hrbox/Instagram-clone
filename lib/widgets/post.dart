// ignore_for_file: avoid_print

import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/models/user.dart';
import 'package:testt/pages/comments.dart';
import 'package:testt/pages/home.dart';
import 'package:testt/widgets/custom_image.dart';
import 'package:testt/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc["postId"],
      ownerId: doc["ownerId"],
      username: doc["username"],
      location: doc["location"],
      description: doc["description"],
      mediaUrl: doc["mediaUrl"],
      likes: doc["likes"],
    );
  }

  int getLikeCount(likes) {
    // If no likes, return 0
    if (likes == 0) {
      return 0;
    }
    int count = 0;
    // If the key is explicitly set to true, add a like
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  // ignore: no_logic_in_create_state
  _PostState createState() => _PostState(
    postId: postId,
    ownerId: ownerId,
    username: username,
    location: location,
    description: description,
    mediaUrl: mediaUrl,
    likes: likes,
    likeCount: getLikeCount(likes),
  );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final Map likes;
  late final int likeCount;
  late bool isLiked;
  bool showHeart = false;

  _PostState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
    required this.likeCount,
  });

  buildPostHeader() {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection("users").doc(ownerId).get(),

      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(
          snapshot.data as DocumentSnapshot<Object?>,
        );
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: CachedNetworkImageProvider(user.photoURL),
          ),
          title: GestureDetector(
            onTap: () => print("Showing Profile"),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: IconButton(
            onPressed: () => print("Deleting post"),
            icon: Icon(Icons.more_vert),
          ),
        );
      },
    );
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      FirebaseFirestore.instance
          .collection("posts")
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({"likes.$currentUserId": false});

      removeLikeFromActivityFeed();

      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      FirebaseFirestore.instance
          .collection("posts")
          .doc(ownerId)
          .collection("userPosts")
          .doc(postId)
          .update({"likes.$currentUserId": true});

      addLikeToActivityFeed();

      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });

      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      FirebaseFirestore.instance
          .collection("feed")
          .doc("ownerId")
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
            if (doc.exists) {
              doc.reference.delete();
            }
          });
    }
  }

  addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      FirebaseFirestore.instance
          .collection("feed")
          .doc("ownerId")
          .collection("feedItems")
          .doc(postId)
          .set({
            "type": "like",
            "username": currentUser.username,
            "userId": currentUser.id,
            "userProfileImg": currentUser.photoURL,
            "postId": postId,
            "mediaUrl": mediaUrl,
            "timestamp": timestamp,
          });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                builder:
                    (context, anim, child) => Transform.scale(
                      scale: anim.value,
                      child: Icon(
                        Icons.favorite,
                        size: 80.0,
                        color: Colors.red,
                      ),
                    ),
                duration: Duration(milliseconds: 300),
                tween: Tween(begin: 0.8, end: 1.4),
                curve: Curves.elasticOut,
                cycles: 0,
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(padding: EdgeInsets.only(top: 40, left: 20.0)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap:
                  () => showComments(
                    context,
                    postId: postId,
                    ownerId: ownerId,
                    mediaUrl: mediaUrl,
                  ),
              child: Icon(Icons.chat, size: 28.0, color: Colors.blue[900]),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                username,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [buildPostHeader(), buildPostImage(), buildPostFooter()],
    );
  }
}

showComments(
  BuildContext context, {
  required String postId,
  required String ownerId,
  required String mediaUrl,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) {
        return Comments(
          postId: postId,
          postOwnerId: ownerId,
          postMediaUrl: mediaUrl,
        );
      },
    ),
  );
}
