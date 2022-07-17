import 'package:get/get.dart';
import 'package:mobile/dto/place.dart';
import 'package:mobile/services/base_connect.dart';

class PlaceService extends BaseConnect {
  Future<Response<List<PlaceDto>?>> search(String query, int page) async => await get('/places/search',
      query: {
        "page": page.toString(),
        "query": query,
      },
      decoder: decoderForList(PlaceDto.fromJson));

  Future<Response<List<PlaceDto>?>> recommend(Point from, PlaceType type) async => await get('/places/recommend',
      query: {
        "latitude": from.latitude,
        "longitude": from.longitude,
        "placeType": type
      },
      decoder: decoderForList(PlaceDto.fromJson));
}