import 'package:mobile/model/user.dart';

import 'location.dart';

class GroupSummaryInfo {
  int id;
  String name;
  String description;

  GroupSummaryInfo(
      {required this.id, required this.name, required this.description});
}

class GroupInfo {
  UserInfo owner;
  List<UserInfo> members;
  // TODO: To add actual itinerary and current location legitly
  LocationInfo currentLocation;

  GroupInfo({
      required this.owner,
      required this.members,
      required this.currentLocation});
}
