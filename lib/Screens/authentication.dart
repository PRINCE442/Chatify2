// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:chatify2/Widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  var _enteredPhoneNumber = '';
  File? _selectedImage;
  var _isAuthenticating = false;

  void _submitCredentials() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    if (!_isLogin && _selectedImage == null) {
      return showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('OOPPSS'),
                content: const Text('You need to take a Picture to SignUp'),
                actions: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel')),
                ],
              ));
    }

    if (isValid == true) {
      _form.currentState!.save();
      try {
        setState(() {
          _isAuthenticating = true;
        });
        if (_isLogin == true) {
          await _firebase.signInWithEmailAndPassword(
              email: _enteredEmail, password: _enteredPassword);
        } else {
          final userSignUp = await _firebase.createUserWithEmailAndPassword(
              email: _enteredEmail, password: _enteredPassword);

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('${userSignUp.user!.uid}.jpg');

          await storageRef.putFile(_selectedImage!);
          final imageUrl = await storageRef.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userSignUp.user!.uid)
              .set({
            'Username': _enteredUsername,
            'email': _enteredEmail,
            'Password': _enteredPassword,
            'Image_url': imageUrl,
            'Phone Number': _enteredPhoneNumber,
          });
        }
      } on FirebaseAuthException catch (error) {
        if (error.code == 'email-already-in-use') {
          //...
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.all(18.0),
            elevation: 9.0,
            content: Text(error.message ?? 'Authentication failed.'),
          ),
        );
      }
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                icon: Icon(Icons.email),
                                labelText: 'Email Address',
                              ),
                              autocorrect: false,
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredEmail = newValue!;
                              },
                            ),
                            if (!_isLogin)
                              TextFormField(
                                decoration: const InputDecoration(
                                    icon: Icon(Icons.person),
                                    labelText: 'Username'),
                                enableSuggestions: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.trim().length < 4) {
                                    return 'Please enter a valid username. (at least 4 characters)';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredUsername = newValue!;
                                },
                              ),
                            if (!_isLogin)
                              TextFormField(
                                decoration: const InputDecoration(
                                    icon: Icon(Icons.phone),
                                    labelText: 'Phone'),
                                enableSuggestions: false,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.trim().length < 11) {
                                    return 'Please enter a valid Phone Number. ';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredPhoneNumber = newValue!;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                icon: Icon(Icons.password),
                                labelText: 'Password',
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password Must be Atleast 6 Characters Long.';
                                }
                                if (!value.contains(RegExp(r'[A-Z]'))) {
                                  return 'Password Must have an upperCase letter';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredPassword = newValue!;
                              },
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            if (_isAuthenticating == true)
                              const CircularProgressIndicator(),
                            if (_isAuthenticating == false)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                onPressed: _submitCredentials,
                                child: Text(_isLogin ? 'Login' : 'Sign up'),
                              ),
                            if (_isAuthenticating == false)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create a New Account'
                                    : 'I already have an account'),
                              ),
                          ],
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
