import 'package:flutter/material.dart';
import 'package:mobile/pages/home.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:mobile/services/auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var auth = AuthService();
    return MultiProvider(
        providers: [ChangeNotifierProvider(create: (ctx) => auth)],
        child: MaterialApp(
            title: 'planlah',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: auth.currentUser() == null ? const SignInPage() : const HomePage(),
            routes: {
              "signIn": (ctx) => const SignInPage(),
              "home": (ctx) => const HomePage(),
            }
        )
    );
  }
}
