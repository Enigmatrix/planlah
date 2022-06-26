import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/services/base_connect.dart';

class GroupService extends BaseConnect {
  Future<Response<List<GroupSummaryDto>?>> getGroup() async => await get('/groups/all',
      decoder: decoderForList(GroupSummaryDto.fromJson));

  Future<Response<GroupSummaryDto?>> createGroup(CreateGroupDto dto) async {
    final formData = FormData(dto.toJson());
    return await post(
        "/groups/create",
        formData,
      decoder: decoderFor(GroupSummaryDto.fromJson)
    );
  }

  Future<Response<GroupSummaryDto?>> joinByInvite(String inviteId) async => await get('/groups/join/$inviteId', decoder: decoderFor(GroupSummaryDto.fromJson));
}