import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<LatLng?> getLatLngFromAddress(String address) async {
  final apiKey = dotenv.env['GOOGLE_API_KEY'];
  if (apiKey == null) {
    print('Google API Key is missing');
    return null;
  }

  final url =
      'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['results'].isNotEmpty) {
      final latitude = data['results'][0]['geometry']['location']['lat'];
      final longitude = data['results'][0]['geometry']['location']['lng'];
      return LatLng(latitude, longitude);
    } else {
      print('주소를 찾을 수 없습니다');
      return null;
    }
  } else {
    print('API 요청 실패');
    return null;
  }
}
