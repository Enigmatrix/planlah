import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile/pages/groups_page.dart';
import 'package:mobile/model/group.dart';
import 'package:mobile/model/location.dart';
import 'package:mobile/model/user.dart';
import 'package:mobile/pages/profile.dart';
import 'package:mobile/pages/settings.dart';
import 'package:mobile/pages/social_feed.dart';
import 'package:mobile/pages/social_post.dart';
import 'package:mobile/services/auth.dart';

class HomePage extends StatefulWidget {

  UserInfo userInfo;
  HomePage({
    Key? key,
    required this.userInfo,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePage> {
  int _selectedIndex = 0;

  // Hard code for now
  static GroupInfo groupInfo1 = GroupInfo(
      owner: UserInfo(
        id: 1,
        name: "Bruno Mars",
        username: "Bruno",
        imageUrl: "https://www.biography.com/.image/c_fill%2Ccs_srgb%2Cfl_progressive%2Ch_400%2Cq_auto:good%2Cw_620/MTg4NTc2ODg1MjEzNTA1MTQw/gettyimages-134315104.jpg"
      ),
      members: <UserInfo>[
        UserInfo(
            id: 2,
            name: "Sasha Obama",
            username: "Sasha",
            imageUrl: "https://media.allure.com/photos/5aeb12dfbf1d634fcf6f718e/1:1/w_3455,h_3455,c_limit/SWNS_SASHA_OBAMA_14.jpg"
        )
      ],
      currentLocation: LocationInfo(
        name: "Pyongyang City",
        imageUrl: "https://cms.qz.com/wp-content/uploads/2018/05/north-korea-leader-kim-jong-un-in-pyongyang-e1527666918109.jpg?quality=75&strip=all&w=1600&h=900&crop=1"
      )
  );

  static GroupInfo groupInfo2 = GroupInfo(
      owner: UserInfo(
          id: 3,
          name: "Taylor Swift",
          username: "Taylor",
          imageUrl: "https://assets.teenvogue.com/photos/626abe370979f2c5ace0ab29/16:9/w_2560%2Cc_limit/GettyImages-1352932505.jpg"
      ),
      members: <UserInfo>[
        UserInfo(
            id: 4,
            name: "Amber Heard",
            username: "Amber",
            imageUrl: "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fstatic.onecms.io%2Fwp-content%2Fuploads%2Fsites%2F6%2F2022%2F05%2F16%2FAmber-Heard.jpg"
        ),
        UserInfo(
            id: 5,
            name: "Bob the builder",
            username: "Bob the builder",
            imageUrl: "https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fstatic.onecms.io%2Fwp-content%2Fuploads%2Fsites%2F6%2F2022%2F05%2F16%2FAmber-Heard.jpg"
        ),
      ],
      currentLocation: LocationInfo(
          name: "NYU",
          imageUrl: "https://engineering.nyu.edu/sites/default/files/styles/content_header_default_1x/public/2018-09/campus-convocation-2018-sign.jpg?h=69f2b9d0&itok=u8diKT3n"
      )
  );

  var currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  Widget getPage(int index) {
    switch (index) {
      case 0:
        return SocialFeedPage(groups: [groupInfo1, groupInfo2]);
      case 1:
        return GroupsPage();
      case 2:
        print("Is widget null? " + (widget == null).toString());
        return ProfilePage(userInfo: widget.userInfo);
      default:
        return SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: getPage(_selectedIndex)
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: "Feed"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups),
              label: "Groups"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile"
          ),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.settings),
          //     label: "Settings"
          // ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber,
        onTap: _onItemTapped,
      ),
    );
  }
}





