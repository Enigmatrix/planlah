
import '../dto/user.dart';
import 'location.dart';

class ReviewInfo {
  final UserSummaryDto user;
  final String content;
  final LocationInfo location;

  const ReviewInfo({
    required this.user,
    required this.content,
    required this.location
  });
}