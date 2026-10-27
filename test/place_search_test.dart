import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/place_search_service.dart';

void main() {
  final offline = PlaceSearchService(client: MockClient((_) async => throw Exception('hors ligne')));

  test('ignores accents and case', () {
    expect(PlaceSearchService.normalize('  Labé '), 'labe');
    expect(offline.searchLocal('labe').first.name, 'Labé');
    expect(offline.searchLocal('NZERE').first.name, 'Nzérékoré');
  });

  test('ranks names starting with the query first', () {
    final places = offline.searchLocal('ka');
    expect(places.first.name, anyOf('Kaloum', 'Kamsar', 'Kankan'));
    // Chaque suggestion correspond par son nom ou par sa région (ex. Kérouané, région de Kankan)
    expect(
      places.every((p) =>
          PlaceSearchService.normalize(p.name).contains('ka') ||
          PlaceSearchService.normalize(p.subtitle).startsWith('ka')),
      isTrue,
    );
  });

  test('falls back to local cities when offline', () async {
    final results = await offline.search('Kin');
    expect(results.map((p) => p.name), contains('Kindia'));
  });

  test('merges online places without duplicating local cities', () async {
    final service = PlaceSearchService(
      client: MockClient((_) async => http.Response(
            '{"features":['
            '{"geometry":{"coordinates":[-12.28,11.32]},"properties":{"name":"Labé","state":"Labé"}},'
            '{"geometry":{"coordinates":[-12.29,11.31]},"properties":{"name":"Marché central","city":"Labé"}}'
            ']}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );
    final names = (await service.search('Lab')).map((p) => p.name).toList();
    expect(names.where((n) => n == 'Labé'), hasLength(1));
    expect(names, contains('Marché central'));
  });
}
