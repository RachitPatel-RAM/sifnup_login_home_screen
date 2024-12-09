import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_url_gen/config/api_config.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  File?_profileImage;
  final ImagePicker _picker = ImagePicker();
  Future <void> pickImage() async{
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if(pickedFile != null)
      {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
  }
  Future<String> uploadImage(File imageFile) async {
    const cloudinaryURL = "https://api.cloudinary.com/v1_1/drbp7g1t4/image/upload";
    final formData = FormData.fromMap({
      'file' : await MultipartFile.fromFile(imageFile.path),
      'upload_preset' : 'Qcart_profile'
    });
    final response = await Dio().post(cloudinaryURL,data:formData);
    return response.data['secure_url'];
  }

  Future<void> register() async {
    if(_profileImage==null){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select profile image')));
      return;
    }
    try{
      final String imageUrl = await uploadImage(_profileImage!);
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword
        (email: _emailController.text, password: _passwordController.text);
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name' : _nameController.text,
        'email' : _emailController.text,
        'profileImage' : imageUrl,
      });
      Navigator.pop(context);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register'),),
      body: Padding(padding: EdgeInsets.all(16),
      child:Column(
        children: [
          GestureDetector(
            onTap: pickImage,
            child: CircleAvatar(
              radius: 30,
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null ? Icon(Icons.add_a_photo) : null,

            ),
          ),

          SizedBox(height: 16,),

          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          SizedBox(height: 16,),
          ElevatedButton(onPressed: register, child: Text("Register"))
        ],
      )
      )
    );
  }
}
