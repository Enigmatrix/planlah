
import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/dto/group_invite.dart';
import 'package:mobile/dto/user.dart';
import 'package:mobile/services/base_connect.dart';

class GroupService extends BaseConnect {
  Future<Response<List<GroupSummaryDto>?>> getGroup() async => await get('/groups/all',
      decoder: decoderForList(GroupSummaryDto.fromJson));

  Future<Response<List<GroupInviteDto>?>> getGroupInvites(num groupId) async => await get('/groups/invites', query: { "groupId": groupId },
      decoder: decoderForList(GroupInviteDto.fromJson));

  Future<Response<GroupInviteDto?>> createGroupInvite(CreateGroupInviteDto dto) async => await post('/groups/invites/create', dto.toJson(),
      decoder: decoderFor(GroupInviteDto.fromJson));

  Future<Response<void>> invalidateGroupInvite(num inviteId) async => await put('/groups/invites/invalidate', { 'inviteId': inviteId });

  Future<Response<GroupSummaryDto?>> createGroup(CreateGroupDto dto) async {
    final formData = FormData(dto.toJson());
    return await post(
        "/groups/create",
        formData,
      decoder: decoderFor(GroupSummaryDto.fromJson)
    );
  }

  Future<Response<GroupInviteDto?>> getGroupInvite(CreateGroupInviteDto dto) async {
    return await post(
      "/groups/invites/create",
      dto.toJson(),
      decoder: decoderFor(GroupInviteDto.fromJson)
    );
  }

  Future<Response<GroupSummaryDto?>> joinByInvite(String inviteId) async => await get('/groups/join/$inviteId', decoder: decoderFor(GroupSummaryDto.fromJson));

  Future<Response<List<UserSummaryDto>?>> getAllGroupMembers(int groupId) async {
    RefGroupDto dto = RefGroupDto(groupId);
    return await get(
      "/groups/get_members",
      query: dto.toJson(),
      decoder: decoderForList(UserSummaryDto.fromJson)
    );
  }
  
  /// Creates a new DM group with a friend. If it already exists,
  /// the DM group is returned.
  Future<Response<GroupSummaryDto?>> createDM(int userId) async {
    UserRefDto dto = UserRefDto(userId);
    return await post(
      "/groups/create_dm",
      dto.toJson(),
      decoder: decoderFor(GroupSummaryDto.fromJson)
    );
  }

  Future<Response<List<UserSummaryDto>?>> getFriendsToJio(int groupId, int page) async {
    JioFriendsDto dto = JioFriendsDto(groupId, page);
    print("Page in getFriendsToJio $page");
    return await get(
      "/groups/get_friends_to_jio",
      query: dto.toJson(),
      decoder: decoderForList(UserSummaryDto.fromJson)
    );
  }

  Future<Response<void>> jio(int userId, int groupId) async {
    JioToGroupDto dto = JioToGroupDto(userId, groupId);
    return await post(
      "/groups/jio",
      dto.toJson(),
    );
  }
}