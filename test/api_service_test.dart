import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  group('ApiService.unwrapEnvelope', () {
    test('returns data from the backend envelope', () {
      final unwrapped = ApiService.unwrapEnvelope({
        'success': true,
        'message': 'Opération réussie',
        'data': {'accessToken': 'token'},
        'timestamp': '2026-10-26T00:00:00.000Z',
      });
      expect(unwrapped, {'accessToken': 'token'});
    });

    test('returns list payloads untouched', () {
      final unwrapped = ApiService.unwrapEnvelope({
        'success': true,
        'data': [1, 2],
      });
      expect(unwrapped, [1, 2]);
    });

    test('leaves non-enveloped values as is', () {
      expect(ApiService.unwrapEnvelope({'accessToken': 'token'}), {'accessToken': 'token'});
      expect(ApiService.unwrapEnvelope([1]), [1]);
    });
  });

  group('AuthProvider.normalizePhone', () {
    test('adds the Guinea prefix to local numbers', () {
      expect(AuthProvider.normalizePhone('620 00 00 00'), '+224620000000');
    });

    test('keeps or converts international numbers', () {
      expect(AuthProvider.normalizePhone('+224620000000'), '+224620000000');
      expect(AuthProvider.normalizePhone('00224620000000'), '+224620000000');
      expect(AuthProvider.normalizePhone('224620000000'), '+224620000000');
    });
  });
}
