import 'dart:ffi';

import 'package:get/get.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/services/base_connect.dart';

import '../dto/outing_step.dart';

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
  Future<Response> createOuting(CreateOutingDto dto) async {
    return await post(
        "/outing/create",
        dto.toJson(),
    );
  }

  /// Get the active Outing for a Group
  Future<Response<OutingDto?>> getActiveOuting(GetActiveOutingDto dto) async {
    return await get(
      "/outing/active",
      query: dto.toJson(),
      decoder: decoderFor(OutingDto.fromJson)
    );
  }

  /// Create an OutingStep
  Future<Response> createOutingStep(CreateOutingStepDto dto) async {
    return await post(
        "/outing/create_step",
        dto.toJson(),
    );
  }


}
