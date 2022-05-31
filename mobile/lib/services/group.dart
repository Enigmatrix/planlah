import 'package:get/get.dart';
import 'package:mobile/model/group.dart';
import 'package:mobile/services/base_connect.dart';

class GroupService extends BaseConnect {
  Future<Response<GroupSummaryInfo>> getGroup() async => await get<GroupSummaryInfo>('/groups/all');
}