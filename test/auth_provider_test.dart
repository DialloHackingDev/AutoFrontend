import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

class _FakeApiService extends ApiService {
  @override
  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    if (url.contains('/auth/logout')) {
      return http.Response('{}', 200);
    }
    return http.Response('{"accessToken":"token","refreshToken":"refresh","user":{"id":"1","nom":"Test","telephone":"+224620000000","role":"PASSAGER"}}', 201);
  }

  @override
  Future<http.Response> get(String url) async {
    return http.Response('{"id":"1","nom":"Test","telephone":"+224620000000","role":"PASSAGER"}', 200);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logout clears the local session even when the backend call fails', () async {
    final provider = AuthProvider(apiService: _FakeApiService());
    await provider.login('+224620000000', 'password123');
    expect(provider.isAuthenticated, isTrue);

    await provider.logout();
    expect(provider.isAuthenticated, isFalse);
  });
}
