import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import 'detail_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ListScreen extends StatefulWidget {
  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String? _sortBy = '최신순';
  List<Map<String, dynamic>> _items = [];
  String _searchQuery = '';
  Location _location = Location();
  static LatLng _initialPosition =
      LatLng(37.24087302228478, 127.07974744744283);
  LatLng _currentLocation = _initialPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadLocationList();
  }

  Future<void> _getCurrentLocation() async {
    LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
    });
  }

  void _sortItems() {
    if (_sortBy == '거리순' && _currentLocation != null) {
      _items.sort((a, b) {
        double distanceA = _calculateDistance(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          a['latitude'] ?? 0.0,
          a['longitude'] ?? 0.0,
        );
        double distanceB = _calculateDistance(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          b['latitude'] ?? 0.0,
          b['longitude'] ?? 0.0,
        );

        return distanceA.compareTo(distanceB);
      });
    } else if (_sortBy == '최신순') {
      _items.sort((a, b) {
        return b['registrationTime'].compareTo(a['registrationTime']);
      });
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<void> _loadLocationList() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;

    final url = 'http://localhost:3000/list?ID=$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List locations = json.decode(response.body);
      setState(() {
        _items = locations.map<Map<String, dynamic>>((location) {
          return {
            'title': location['Title'] ?? '',
            'subtitle': location['Address'] ?? '',
            'image': 'http://localhost:3000/${location['ImagePath']}',
            'latitude': double.tryParse(location['Latitude'].toString()) ?? 0.0,
            'longitude':
                double.tryParse(location['Longitude'].toString()) ?? 0.0,
            'memo': location['Memo'] ?? '',
            'registrationTime': location['RegistrationTime'] != null
                ? DateTime.parse(location['RegistrationTime'])
                : DateTime.now(),
          };
        }).toList();
        _sortItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '목록',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C6EE5),
          ),
        ),
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(0xFF4C6EE5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: DropdownButton<String>(
                        value: _sortBy,
                        onChanged: (String? newValue) {
                          setState(() {
                            _sortBy = newValue;
                            _sortItems();
                          });
                        },
                        items: <String>['거리순', '최신순']
                            .where((value) => value != _sortBy)
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList()
                          ..insert(
                            0,
                            DropdownMenuItem<String>(
                              value: _sortBy,
                              child: Text(_sortBy!),
                            ),
                          ),
                        style: TextStyle(
                          color: Color(0xFF4C6EE5),
                        ),
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: Colors.white,
                        itemHeight: 50,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xFF4C6EE5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.only(left: 8.0),
                              hintText: '주소를 입력하세요...',
                              hintStyle: TextStyle(
                                color: Color(0xFF4C6EE5),
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              color: Color(0xFF4C6EE5),
                            ),
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: Colors.blue,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  if (_searchQuery.isNotEmpty &&
                      !item['subtitle']!.contains(_searchQuery)) {
                    return SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            registrationTime: item['registrationTime'],
                            imagePath: item['image'],
                            placeName: item['title'],
                            address: item['subtitle'],
                            memo: item['memo'],
                            latitude: item['latitude'],
                            longitude: item['longitude'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 2),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color.fromARGB(217, 204, 209, 232),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item['image']!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/location_gray.png',
                                      width: 16,
                                      height: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item['subtitle']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('메모: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey)),
                                    Text(
                                      item['memo']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
