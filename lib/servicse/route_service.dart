import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SearchResult {
  final String name;
  final LatLng point;

  const SearchResult({required this.name, required this.point});
}

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RouteService {
  static const _userAgent = 'google_maps_flutter_demo/1.0';

  Future<SearchResult> searchPlace(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'accept-language': 'ar,en',
    });

    final response = await http.get(
      uri,
      headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('فشل البحث عن المكان');
    }

    final results = jsonDecode(response.body) as List;
    if (results.isEmpty) {
      throw Exception('لم يتم العثور على المكان');
    }

    final item = results.first as Map<String, dynamic>;
    return SearchResult(
      name: item['display_name'] as String,
      point: LatLng(
        double.parse(item['lat'] as String),
        double.parse(item['lon'] as String),
      ),
    );
  }

  Future<RouteResult> getDrivingRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode != 200) {
      throw Exception('فشل الحصول على الطريق');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw Exception('لا يوجد طريق بين الموقعين');
    }

    final route = (data['routes'] as List).first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    return RouteResult(
      points: coordinates
          .map(
            (coordinate) => LatLng(
              (coordinate[1] as num).toDouble(),
              (coordinate[0] as num).toDouble(),
            ),
          )
          .toList(),
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
    );
  }
}
