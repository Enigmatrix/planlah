import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/pages/dev_panel.dart';
import 'package:mobile/pages/home.dart';
import 'package:mobile/pages/sign_in.dart';
import 'package:mobile/pages/groups_page.dart';
import 'package:mobile/pages/sign_up.dart';
import 'package:mobile/services/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/services/group.dart';
import 'package:mobile/services/message.dart';
import 'package:mobile/services/misc.dart';
import 'package:mobile/services/outing.dart';
import 'package:mobile/services/user.dart';
import 'package:mobile/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Get.put(AuthService());
  Get.put(GroupService());
  Get.put(UserService());
  Get.put(MessageService());
  Get.put(MiscService());
  Get.put(OutingService());

  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late AuthService auth;
  late UserService userSvc;

  @override
  void initState() {
    super.initState();
    auth = Get.find();
    userSvc = Get.find();
  }

  Widget waitWidget() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    auth.user.value?.getIdToken().then((value) => {
      log(value)
    });
    Widget homeWidget;

    if (auth.user.value == null) {
      homeWidget = const SignInPage();
    } else {
      homeWidget = FutureBuilder(
          future: userSvc.getInfo(),
          builder: (BuildContext context,
              AsyncSnapshot<Response<UserInfo?>> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.hasError) {
                return const SignUpPage();
              } else {
                return const HomePage();
              }
            } else {
              return waitWidget();
            }
          });
    }

    return GetMaterialApp(
        title: 'planlah',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: homeWidget,
        // home: const SignInPage(),
        getPages: [
          GetPage(name: '/signIn', page: () => const SignInPage()),
          GetPage(name: '/signUp', page: () => const SignUpPage()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/groups', page: () => const GroupsPage()),
          GetPage(name: '/dev_panel', page: () => DevPanelPage()),
        ]);
  }
}
