import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:testt/models/user.dart';
import 'package:testt/pages/home.dart';
import 'package:testt/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({required this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

final Reference storageRef = FirebaseStorage.instance.ref().child("posts");

class _UploadState extends State<Upload> {
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();

  File? file;
  bool isUploading = false;
  String postId = Uuid().v4();

  handleChooseFromGallery() async {
    Navigator.pop(context);
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960,
    );

    if (pickedFile != null) {
      setState(() {
        file = File(pickedFile.path); // Convert XFile to File
      });
    }
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );

    if (pickedFile != null) {
      setState(() {
        file = File(pickedFile.path); // Convert XFile to File
      });
    }
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Create Post"),
          children: [
            SimpleDialogOption(
              onPressed: handleTakePhoto,
              child: Text("Photo with camera"),
            ),
            SimpleDialogOption(
              onPressed: handleChooseFromGallery,
              child: Text("Image from Gallery"),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).colorScheme.secondary.withAlpha(153),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/upload.svg", height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              onPressed: () => selectImage(context),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.deepOrange),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              child: Text(
                "Upload image",
                style: TextStyle(color: Colors.white, fontSize: 22.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = "${tempDir.path}/img_$postId.jpg";

    // Decode and compress
    final imageFile = Im.decodeImage(file!.readAsBytesSync())!;
    final compressedBytes = Im.encodeJpg(imageFile, quality: 85);

    // Create file and write asynchronously
    final compressedImageFile = File(path);
    await compressedImageFile.writeAsBytes(compressedBytes);
    print("Compressed image size: ${file?.lengthSync()} bytes");

    setState(() {
      file = compressedImageFile;
    });
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      // 1. Verify file exists
      if (!await imageFile.exists()) {
        throw Exception("File doesn't exist at path: ${imageFile.path}");
      }

      // 2. Create reference with user-specific path
      final ref = FirebaseStorage.instance.ref().child(
        "posts/${widget.currentUser.id}/$postId.jpg",
      );

      print("Attempting upload to: posts/${widget.currentUser.id}/$postId.jpg");

      // 3. Start upload with timeout
      final TaskSnapshot snapshot = await ref
          .putFile(imageFile)
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception("Upload timed out after 30 seconds");
            },
          );

      // 4. Verify success and get download URL
      if (snapshot.state == TaskState.success) {
        final url = await snapshot.ref.getDownloadURL();
        print("Upload successful! URL: $url");
        return url;
      } else {
        throw Exception("Upload failed with state: ${snapshot.state}");
      }
    } catch (e) {
      print("Detailed upload error: $e");
      rethrow;
    }
  }

  createPostInFirestore({
    required String mediaUrl,
    required String location,
    required String description,
  }) {
    postsRef
        .doc(widget.currentUser.id)
        .collection("userPosts")
        .doc(postId)
        .set({
          "postId": postId,
          "ownerId": widget.currentUser.id,
          "username": widget.currentUser.username,
          "mediaUrl": mediaUrl,
          "description": description,
          "location": location,
          "timestamp": timestamp,
          "likes": {},
        });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    print("Uploading file: ${file?.path}");
    print("File exists: ${file?.existsSync()}");

    String mediaUrl = await uploadImage(file!);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          onPressed: clearImage,
          icon: Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text("Caption Post", style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text("data"),
          SizedBox(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image:
                          file != null
                              ? FileImage(file!)
                              : AssetImage('assets/images/placeholder.png')
                                  as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.currentUser.photoURL,
              ),
            ),
            title: SizedBox(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(hintText: "Write a caption ..."),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop, color: Colors.orange, size: 35.0),
            title: SizedBox(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: "Where was this photo taken?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: getUserLocation,
              style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              icon: Icon(Icons.my_location, color: Colors.white),
              label: Text(
                "Use your current location",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

Future<void> getUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled
    return Future.error('Location services are disabled.');
  }

  // Check permission status
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permission denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are permanently denied
    return Future.error('Location permission permanently denied.');
  }

  // If permission granted
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  List<Placemark> placemarks = await placemarkFromCoordinates(
    position.latitude,
    position.longitude,
  );

  Placemark placemark = placemarks[0];

  String completeAddress =
      "${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea}, ${placemark.postalCode}, ${placemark.country}";

  print(completeAddress);
  String formattedAddress = "${placemark.locality}, ${placemark.country}";

  locationController.text = formattedAddress;
}


  @override
  Widget build(BuildContext context) {
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
