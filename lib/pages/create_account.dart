import 'dart:async';

import 'package:flutter/material.dart';
import 'package:testt/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formkey = GlobalKey<FormState>();
  late String username;

  submit() {
    final form = _formkey.currentState;
    if (form!.validate()) {
      form.save();
      final SnackBar snackBar = SnackBar(content: Text("Welcome $username!"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(
        context,
        titleText: "Set up your profile",
        isAppTitle: false,
        removeBackButton: true
      ),
      body: ListView(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Text(
                    "Create a username",
                    style: TextStyle(fontSize: 25.0),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formkey,
                    autovalidateMode: AutovalidateMode.always,
                    child: TextFormField(
                      validator: (val) {
                        if (val!.trim().length < 3 || val.isEmpty) {
                          return "Username too short";
                        } else if (val.trim().length > 12) {
                          return "Username too long";
                        } else {
                          return null;
                        }
                      },
                      onSaved: (val) => username = val!,
                      decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle: TextStyle(fontSize: 15.0),
                        border: OutlineInputBorder(),
                        hintText: "Must be at least 3 characters",
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50.0,
                    width: 350.0,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    child: Center(
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
