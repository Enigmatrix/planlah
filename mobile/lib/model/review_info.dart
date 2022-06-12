import 'package:mobile/model/user.dart';

import 'location.dart';

class ReviewInfo {
  final UserInfo user;
  final String content;
  final LocationInfo location;

  const ReviewInfo({
    required this.user,
    required this.content,
    required this.location
  });
}