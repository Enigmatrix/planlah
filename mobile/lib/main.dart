import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/home.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:mobile/groups/pages/groups_page.dart';
import 'package:mobile/services/auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Get.put(AuthService());


  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return GetMaterialApp(
        title: 'planlah',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // home: auth.user.value == null ? const SignInPage() : const HomePage(),
        home: const HomePage(),
        getPages: [
          GetPage(name: '/signIn', page: () => const SignInPage()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/groups', page: () => const GroupsPage()),
        ]
    );
  }
}
