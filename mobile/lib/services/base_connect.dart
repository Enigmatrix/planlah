import 'package:get/get.dart';
import 'package:mobile/services/auth.dart';


class BaseConnect extends GetConnect {
  late AuthService auth;

  // this will be initialized upon first authenticated route
  static String? token;

  Decoder<T?> decoderFor<T>(T Function(Map<String, dynamic>) from) {
    return (data) {
      if (checkAuthenticationError(data)) return null;
      var map = Map<String, dynamic>.from(data);
      return from(map);
    };
  }

  Decoder<List<T>?> decoderForList<T>(T Function(Map<String, dynamic>) from) {
    return (data) {
      if (checkAuthenticationError(data)) return null;
      var list = List.from(data);
      return list.map((x) => from(x)).toList();
    };
  }

  bool checkAuthenticationError(dynamic data) {
    try {
      var map = Map<String, dynamic>.from(data);
      if (map.containsKey("code") && map["code"] == 401) { // auth error
        return true;
      }
    } on TypeError catch (_) {}

    return false;
  }

  @override
  void onInit() {
    auth = Get.find<AuthService>();

    // TODO make this configurable
    httpClient.baseUrl = "http://localhost:8080/api";

    httpClient.addRequestModifier<dynamic>((request) async {
      if (token == null) return request;
      var headers = {'Authorization': "Bearer $token"};
      request.headers.addAll(headers);
      return request;
    });

    httpClient.addAuthenticator<dynamic>((request) async {
      Get.log('unauthenticated error given, rectifying ...');
      final firebaseToken = await auth.user.value?.getIdToken();
      if (firebaseToken == null) return request;

      final response = await post('/auth/verify', { "token": firebaseToken });
      if (response.body["code"] != 200) return request;

      token = response.body['token'];
      var headers = {'Authorization': "Bearer $token"};
      request.headers.addAll(headers);
      Get.log('unauthenticated error fixed');
      return request;
    });

    // retry token verification 3 times
    httpClient.maxAuthRetries = 3;
  }

}