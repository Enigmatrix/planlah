import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/dev_panel.dart';
import 'package:mobile/pages/home.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:mobile/groups/pages/groups_page.dart';
import 'package:mobile/pages/sign_up.dart';
import 'package:mobile/services/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/services/config.dart';
import 'package:mobile/services/dev_panel.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/services/message.dart';
import 'package:mobile/services/misc.dart';
import 'package:mobile/services/user.dart';
import 'package:mobile/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Get.put(AuthService());
  Get.put(GroupService());
  Get.put(UserService());
  Get.put(MessageService());
  Get.put(DevPanelService());
  Get.put(Config());
  Get.put(MiscService());

  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'planlah',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        // home: auth.user.value == null ? const SignInPage() : const HomePage(),
        home: const SignInPage(),
        // home: const HomePage(),
        home: const SignUpPage(),
        getPages: [
          GetPage(name: '/signIn', page: () => const SignInPage()),
          GetPage(name: '/signUp', page: () => const SignUpPage()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/groups', page: () => const GroupsPage()),
          GetPage(name: '/dev_panel', page: () => DevPanelPage()),
        ]
    );
  }
}
