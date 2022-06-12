import 'package:get/get.dart';
import 'package:mobile/services/base_connect.dart';

class MiscService extends BaseConnect {
  Future<Response<List<String>?>> getTowns() async => await get('/misc/towns',
      decoder: decoderForListString());

  Future<Response<List<String>?>> getGenders() async => await get('/misc/gender',
      decoder: decoderForListString());
}
