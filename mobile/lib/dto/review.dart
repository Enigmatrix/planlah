import 'package:mobile/dto/place.dart';
import 'package:mobile/dto/user.dart';

class CreateReviewDto {
  int placeId;
  String content;
  int rating;

  CreateReviewDto(this.placeId, this.content, this.rating);

  Map<String, dynamic> toJson() => {
    "placeId": placeId,
    "content": content,
    "rating": rating
  };
}

class ReviewDto {
  int id;
  UserSummaryDto user;
  PlaceDto placeDto;
  String content;
  int rating;

  ReviewDto(this.id, this.user, this.placeDto, this.content, this.rating);

  ReviewDto.fromJson(Map<String, dynamic> json):
    id = json["id"],
    user = UserSummaryDto.fromJson(json["user"]),
    placeDto = PlaceDto.fromJson(json["place"]),
    content = json["content"],
    rating = json["rating"];
}

class SearchForReviewsDto {
  int placeId;
  int page;

  SearchForReviewsDto(this.placeId, this.page);

  Map<String, dynamic> toJson() => {
    "page": page.toString(),
    "placeId": placeId
  };
}