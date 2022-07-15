
import '../dto/user.dart';
import 'location.dart';

class GroupSummaryInfo {
  int id;
  String name;
  String description;

  GroupSummaryInfo(
      {required this.id, required this.name, required this.description});
}

class GroupInfo {
  UserSummaryDto owner;
  List<UserSummaryDto> members;
  // TODO: To add actual itinerary and current location legitly
  LocationInfo currentLocation;

  GroupInfo({
      required this.owner,
      required this.members,
      required this.currentLocation});

  bool isInOuting() {
    // To do this legitly in the future
    return false;
  }

}
