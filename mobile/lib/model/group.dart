import 'package:mobile/model/user.dart';

import 'location.dart';

class GroupInfo {
   UserInfo owner;
   List<UserInfo> members;
   // TODO: To add actual itinerary and current location legitly
   LocationInfo currentLocation;

  GroupInfo({
    required this.owner,
    required this.members,
    required this.currentLocation
  });


}