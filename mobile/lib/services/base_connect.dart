import 'package:get/get.dart';
import 'package:mobile/services/auth.dart';
import 'package:mobile/services/session.dart';


class BaseConnect extends GetConnect {
  late AuthService auth;
  late GetHttpClient unauthClient;

  // this will be initialized upon first authenticated route
  static String? token;

  Decoder<T?> decoderFor<T>(T Function(Map<String, dynamic>) from) {
    return (data) {
      if (checkAuthenticationError(data)) return null;
      if (checkBadRequest(data)) return null;

      if (data == null) {
        return null;
      } else {
        var map = Map<String, dynamic>.from(data);
        print(map);
        return from(map);
      }
    };
  }

  Decoder<List<T>?> decoderForList<T>(T Function(Map<String, dynamic>) from) {
    return (data) {
      if (checkAuthenticationError(data)) return null;
      if (checkBadRequest(data)) return null;
      var list = List.from(data);
      return list.map((x) => from(x)).toList();
    };
  }

  Decoder<List<String>?> decoderForListString() {
    return (data) {
      if (checkAuthenticationError(data)) return null;
      if (checkBadRequest(data)) return null;
      var list = List.from(data);
      return list.map((x) => x as String).toList();
    };
  }

  bool checkBadRequest(dynamic data) {
    try {
      var map = Map<String, dynamic>.from(data);
      if (map.containsKey("kind")) { // auth error
        return true;
      }
    } on TypeError catch (_) {}

    return false;
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

  static const String server = "localhost:8080/api";

  @override
  void onInit() {
    auth = Get.find<AuthService>();
    unauthClient = GetHttpClient();

    httpClient.baseUrl = "http://$server";

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

      final response = await unauthClient.post('${httpClient.baseUrl}/auth/verify', body: { "token": firebaseToken });
      if (response.body["code"] != 200) return request;

      token = response.body['token'];
      var headers = {'Authorization': "Bearer $token"};
      request.headers.addAll(headers);
      Get.log('unauthenticated error fixed');


      // This is where the user token can exist, so we can init
      // websockets with it.
      final session = Get.find<SessionService>();
      session.initConnection();

      return request;
    });

    // retry token verification 3 times
    httpClient.maxAuthRetries = 3;
    httpClient.timeout = const Duration(seconds: 30);
  }

}