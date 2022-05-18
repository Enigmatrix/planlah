import 'package:flutter/material.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:mobile/services/auth.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var auth = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Stack(children: [
        ElevatedButton(onPressed: () async {
          await auth.signOutFromGoogle();
          if (mounted) await Navigator.pushReplacementNamed(context, "signIn");
        }, child: const Text("LOG OUT"))
      ])
    );
  }
}
