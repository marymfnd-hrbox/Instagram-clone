import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  late final String id;
  late final String username;
  late final String email;
  late final String photoURL;
  late final String displayName;
  late final String bio;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.photoURL,
    required this.displayName,
    required this.bio,
  });

  factory User.fromDocument(DocumentSnapshot doc){
    return User(id: doc["id"],
     username: doc["username"],
      email: doc["email"],
       photoURL: doc["photoURL"],
        displayName: doc["displayName"],
         bio: doc["bio"]);
  }
}