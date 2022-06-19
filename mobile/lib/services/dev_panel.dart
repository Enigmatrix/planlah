import 'package:get/get.dart';
import 'package:mobile/dto/group.dart';
import 'package:mobile/services/base_connect.dart';

class DevPanelService extends BaseConnect {
  Future<Response<void>> addToDefaultGroups() async => await post('/dev_panel/add_to_default_groups', null);
}