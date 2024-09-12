import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // State variable that will refer to the profile image location.
  String? imageFile;

  // A reference to the Storage bucket for our project.
  var storageRef = FirebaseStorage.instance.ref();

  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _getFileUrl();
  }

  void _getFileUrl() async {
    try {
      // We have to search all the files to see if the user
      // has a profile pic.
      ListResult result = await storageRef.child('profilepics').listAll();
      for (Reference ref in result.items) {
        // Leverage our naming schema from _getImage()
        if (ref.name.startsWith(FirebaseAuth.instance.currentUser!.uid)) {
          imageFile = await ref.getDownloadURL();
          setState(() {});
        }
      }
    } on FirebaseException catch (e) {
      // Caught an exception from Firebase.
      if (kDebugMode) {
        print("Couldn't download profile pic for user. $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        backgroundColor: const Color.fromARGB(255, 243, 18, 2),
      ),
      backgroundColor: Colors.red,
      body: Column(
        children: [
          // Display a placeholder or the selected image
          if (imageFile == null) const Icon(Icons.account_circle, size: 72),
          if (imageFile != null)
            CircleAvatar(
              radius: 72,
              backgroundImage: NetworkImage(imageFile!),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () => _getImage(ImageSource.camera),
                  child: const Text("Camera")),
              ElevatedButton(
                  onPressed: () => _getImage(ImageSource.gallery),
                  child: const Text("Gallery")),
            ],
          ),
          if (uploading) const CircularProgressIndicator(),
        ],
      ),
    );
  }

  _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      // Extract the image file extension
      String fileExtension = '';
      int period = image.path.lastIndexOf('.');
      if (period > -1) {
        fileExtension = image.path.substring(period);
      }
      // Specify the bucket location so that it will be something like
      // `<ourBucket>/profilepics/AOBrzuwu9ZQO3kteja956exgf0U2.jpg`
      final profileImageRef = storageRef.child(
          "profilepics/${FirebaseAuth.instance.currentUser!.uid}$fileExtension");

      try {
        setState(() {
          uploading = true;
        });
        await profileImageRef.putFile(File(image.path));
        imageFile = await profileImageRef.getDownloadURL();
        setState(() {
          uploading = false;
        });
      } on FirebaseException catch (e) {
        setState(() {
          uploading = false;
        });
        if (kDebugMode) {
          print("Failed with error '${e.code}': ${e.message}");
        }
      }
    }
  }
}
