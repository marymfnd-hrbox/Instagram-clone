import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:testt/models/user.dart';
import 'package:testt/pages/home.dart';
import 'package:testt/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  const EditProfile({required this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _bioValid = true;
  bool _displayNameValid = true;

  bool isLoading = false;
  User? user;

  @override
  void initState() {
    super.initState();
    displayNameController = TextEditingController();
    bioController = TextEditingController();
    getUser();
  }

  getUser() async {
    setState(() => isLoading = true);
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(widget.currentUserId)
              .get();

      if (doc.exists) {
        user = User.fromDocument(doc);
        displayNameController.text = user?.displayName ?? "";
        bioController.text = user?.bio ?? "";
      }
    } catch (e) {
      print("Error getting user: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text("Display Name", style: TextStyle(color: Colors.grey)),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "Update Display Name",
            errorText: _displayNameValid ? null : "Display Name is too short",
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text("Bio", style: TextStyle(color: Colors.grey)),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "Update Bio",
            errorText: _bioValid ? null : "Bio is too long",
          ),
        ),
      ],
    );
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;

      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    if (_displayNameValid & _bioValid) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(widget.currentUserId)
          .update({
            "displayName": displayNameController.text,
            "bio": bioController.text,
          });
      SnackBar snackBar = SnackBar(content: Text("Profile updated!"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  logout() async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Edit Profile", style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.done, size: 30.0, color: Colors.green),
          ),
        ],
      ),
      body:
          isLoading
              ? circularProgress()
              : ListView(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                  
                          radius: 50.0,
                          child: ClipOval(
                            child: Image(
                              image:
                                  (user?.photoURL.isNotEmpty ?? false)
                                      ? CachedNetworkImageProvider(
                                        user!.photoURL,
                                      )
                                      : const AssetImage(
                                            "assets/images/default_avatar.png",
                                          )
                                          as ImageProvider,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.low,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: logout,
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}
