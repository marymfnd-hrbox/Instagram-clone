// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:testt/models/user.dart';
import 'package:testt/pages/activityfeed.dart';
import 'package:testt/pages/create_account.dart';
import 'package:testt/pages/profile.dart';
import 'package:testt/pages/search.dart';
import 'package:testt/pages/upload.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

final GoogleSignIn googleSignIn = GoogleSignIn();
final Reference storageRef = FirebaseStorage.instance.ref();
final userRef = FirebaseFirestore.instance.collection("users");
final postsRef = FirebaseFirestore.instance.collection("posts");
final timestamp = DateTime.now();
late User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  late PageController pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();

    googleSignIn.onCurrentUserChanged.listen(
      (account) {
        handleSignIn(account);
      },
      onError: (err) {
        print("Error signing in: $err");
      },
    );

    googleSignIn
        .signInSilently(suppressErrors: false)
        .then((account) {
          handleSignIn(account);
        })
        .catchError((err) {
          print("Silent sign-in error: $err");
        });
  }

  Future<void> handleSignIn(GoogleSignInAccount? account) async {
    if (account != null) {
      // Link GoogleSignIn to FirebaseAuth
      final GoogleSignInAuthentication googleAuth = await account.authentication;

      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.FirebaseAuth.instance.signInWithCredential(credential);

      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  Future<void> createUserInFirestore() async {
    final auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    DocumentSnapshot doc = await userRef.doc(firebaseUser.uid).get();

    if (!doc.exists) {
      final username = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateAccount()),
      );

      userRef.doc(firebaseUser.uid).set({
        "id": firebaseUser.uid,
        "username": username,
        "photoURL": firebaseUser.photoURL,
        "email": firebaseUser.email,
        "displayName": firebaseUser.displayName,
        "bio": "",
        "timestamp": timestamp,
      });

      doc = await userRef.doc(firebaseUser.uid).get();
    }

    currentUser = User.fromDocument(doc);
    print("Signed in as: ${currentUser.username}");
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.FirebaseAuth.instance.signInWithCredential(credential);
      handleSignIn(googleUser);
    } catch (error) {
      print("Google Sign-In Error: $error");
    }
  }

  void logout() async {
    await auth.FirebaseAuth.instance.signOut();
    await googleSignIn.signOut();
    setState(() {
      isAuth = false;
    });
  }

  void onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  void onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          ElevatedButton(onPressed: logout, child: Text("Logout")),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser.id, currentUser: currentUser),
        ],
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).colorScheme.secondary,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera, size: 35.0)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Widget buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "FlutterShare",
              style: TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
