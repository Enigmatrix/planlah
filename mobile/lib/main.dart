import 'package:flutter/material.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/services/auth.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [ChangeNotifierProvider(create: (ctx) => AuthService())],
        child: MaterialApp(
            title: 'planlah',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: const SignInPage()));
  }
}
