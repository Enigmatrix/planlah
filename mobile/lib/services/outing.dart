import 'dart:ffi';

import 'package:get/get.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/services/base_connect.dart';

class OutingService extends BaseConnect {
  /// Get all Outings for a Group
  Future<Response<List<OutingDto>?>> getAllOutings(int groupId) async {
    return await get(
      "/outing/all",
      query: {
        "groupId": groupId.toString()
      },
      decoder: decoderForList(OutingDto.fromJson)
    );
  }

  /// Create a new Outing for a Group
  Future<Response<void>> create(CreateOutingDto dto) async => await post<void>("/outing/create", dto.toJson());

}
