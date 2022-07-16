import 'package:get/get.dart';
import 'package:mobile/dto/review.dart';
import 'package:mobile/services/base_connect.dart';

class ReviewService extends BaseConnect {

  Future<Response<void>> createReview(String content, int placeId, int rating) async {
    CreateReviewDto dto = CreateReviewDto(placeId, content, rating);
    return await post(
        "/reviews/create",
        dto.toJson()
    );
  }

  Future<Response<List<ReviewDto>?>> getReviews(int placeId, int page) async {
    SearchForReviewsDto dto = SearchForReviewsDto(placeId, page);
    return await get(
      "/reviews/get",
      query: dto.toJson(),
      decoder: decoderForList(ReviewDto.fromJson)
    );
  }

}