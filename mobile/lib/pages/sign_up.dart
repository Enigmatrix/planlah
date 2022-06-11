import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Image.asset(
              "assets/undraw_Mobile_login_re_9ntv.png",
            ),
            const Text(
              "Welcome to PlanLah!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Colors.black
              ),
            ),
            const Text(
              "Create an account, it's free",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
            const UserForm(),
          ],
        ),
      )
    );
  }
}

class UserForm extends StatefulWidget {
  const UserForm({Key? key}) : super(key: key);

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          const CustomForm(labelText: "name"),
          const CustomForm(labelText: "username"),
          ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Form is valid
                }
              },
              child: const Text(
                "Next"
              )
          )
        ],
      ),
    );
  }
}

class CustomForm extends StatelessWidget {

  final String labelText;

  const CustomForm({
    Key? key,
    required this.labelText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        style: const TextStyle(
          color: Colors.black,
        ),
        decoration: InputDecoration(
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.blue
            )
          ),
          labelText: labelText,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter your $labelText";
          }
          return null;
        },
      ),
    );
  }
}



