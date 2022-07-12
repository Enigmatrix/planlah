import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/dto/group_invite.dart';
import 'package:mobile/services/base_connect.dart';

class GroupService extends BaseConnect {
  Future<Response<List<GroupSummaryDto>?>> getGroup() async => await get('/groups/all',
      decoder: decoderForList(GroupSummaryDto.fromJson));

  Future<Response<List<GroupInviteDto>?>> getGroupInvites(num groupId) async => await get('/groups/invites', query: { "groupId": groupId },
      decoder: decoderForList(GroupInviteDto.fromJson));

  Future<Response<GroupInviteDto?>> createGroupInvite(CreateGroupInviteDto dto) async => await post('/groups/invites/create', dto.toJson(),
      decoder: decoderFor(GroupInviteDto.fromJson));

  Future<Response<void>> invalidateGroupInvite(num inviteId) async => await put('/groups/invites/invalidate', { 'inviteId': inviteId });

  Future<Response<GroupSummaryDto?>> joinByInvite(String inviteId) async => await get('/groups/join/$inviteId', decoder: decoderFor(GroupSummaryDto.fromJson));
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