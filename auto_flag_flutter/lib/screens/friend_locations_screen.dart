import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/geocoding_service.dart';

class FriendLocationsPage extends StatefulWidget {
  final String friendId;

  FriendLocationsPage({required this.friendId});

  @override
  _FriendLocationsPageState createState() => _FriendLocationsPageState();
}

class _FriendLocationsPageState extends State<FriendLocationsPage> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  loc.Location _location = loc.Location();
  static const LatLng _initialPosition =
      LatLng(37.24087302228478, 127.07974744744283);
  LatLng _currentLocation = _initialPosition;
  Map<String, dynamic>? _selectedLocationInfo;
  String? _selectedMarkerId;

  double? selectedlatitude;
  double? selectedlongitude;

  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFriendLocations();
    _getCurrentLocation();
    _fetchFriendLocations();
  }

  void _getCurrentLocation() async {
    loc.LocationData locationData = await _location.getLocation();
    setState(() {
      _currentLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      _addCurrentLocationMarker();
      _moveCameraToLocation(_currentLocation);
    });
  }

  void _addCurrentLocationMarker() {
    final marker = Marker(
      markerId: MarkerId('currentLocation'),
      position: _currentLocation,
      infoWindow: InfoWindow(title: 'My Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    setState(() {
      _markers['currentLocation'] = marker;
    });
  }

  Future<void> _fetchFriendLocations() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/list?ID=${widget.friendId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        data.forEach((location) {
          final latitude = location['Latitude'];
          final longitude = location['Longitude'];

          if (latitude != null && longitude != null) {
            final position = LatLng(latitude, longitude);
            _addLocationMarker(
              position,
              location['Title'],
              location['Address'],
              location['Memo'],
              location['ImagePath'],
              latitude,
              longitude,
            );
          } else {
            print("Invalid location data: $location");
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구의 장소를 가져오지 못했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 가져오는 중에 오류가 발생했습니다: $e')),
      );
    }
  }

  void _addLocationMarker(LatLng position, String title, String address,
      String memo, String imagePath, double latitude, double longitude) {
    final marker = Marker(
      markerId: MarkerId(title),
      position: position,
      icon: _selectedMarkerId == title
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      onTap: () {
        setState(() {
          _selectedMarkerId = title;
        });
        _showLocationInfo(title, address, memo, imagePath, latitude, longitude);
      },
    );

    setState(() {
      _markers[title] = marker;
    });
  }

  void _moveCameraToLocation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _showLocationInfo(String title, String address, String memo,
      String imagePath, double latitude, double longitude) {
    setState(() {
      _selectedLocationInfo = {
        'title': title,
        'address': address,
        'memo': memo,
        'imagePath': 'http://localhost:3000/$imagePath',
        'latitude': latitude,
        'longitude': longitude,
      };
      _selectedMarkerId = title;
      selectedlatitude = latitude;
      selectedlongitude = longitude;
    });
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소를 입력하세요')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      List<geocoding.Location> locations =
          await geocoding.locationFromAddress('$query, South Korea');

      Navigator.pop(context);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final LatLng targetPosition =
            LatLng(location.latitude, location.longitude);

        setState(() {
          final marker = Marker(
            markerId: MarkerId('searchResult'),
            position: targetPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: query),
          );
          _markers['searchResult'] = marker;
        });

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: targetPosition,
              zoom: 15.0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 결과를 찾을 수 없습니다')),
        );
      }
    } catch (e) {

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주소 검색에 실패했습니다. 다시 시도해주세요')),
      );
    }
  }

  Future<void> _submitData() async {
    final userId = context.read<UserProvider>().userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 정보가 없습니다.')),
      );
      return;
    }

    if (_selectedLocationInfo!['imagePath'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 필드를 입력해주세요.')),
      );
      return;
    }

    if (selectedlatitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lat 필드를 입력해주세요.')),
      );
      return;
    }

    if (selectedlongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('long 필드를 입력해주세요.')),
      );
      return;
    }

    final uri = Uri.parse('http://localhost:3000/register-place');
    var request = http.MultipartRequest('POST', uri)
      ..fields['id'] = userId
      ..fields['title'] = _selectedLocationInfo!['title']
      ..fields['address'] = _selectedLocationInfo!['address']
      ..fields['latitude'] = selectedlatitude.toString()
      ..fields['longitude'] = selectedlongitude.toString()
      ..fields['memo'] = _selectedLocationInfo!['memo']
      ..fields['registration_time'] = DateTime.now().toUtc().toIso8601String();

    try {
      final imagePath = _selectedLocationInfo!['imagePath'];
      if (imagePath != null) {
        final relativeImagePath =
            imagePath.replaceAll('http://localhost:3000', '');
        final imageBytes = await http
            .readBytes(Uri.parse('http://localhost:3000$relativeImagePath'));
        request.files.add(http.MultipartFile.fromBytes('image', imageBytes,
            filename: relativeImagePath.split('/').last));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장소가 성공적으로 등록되었습니다!')),
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다.')),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '친구 장소',
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
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14,
            ),
            markers: Set<Marker>.from(_markers.values),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 5,
            left: 10,
            right: 10,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Color(0xFF4C6EE5),
                  width: 1, // 테두리 두께
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: '주소를 입력하세요...',
                          hintStyle: TextStyle(
                            color: Color(0xFF4C6EE5),
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: Color(0xFF4C6EE5),
                        ),
                        onSubmitted: (_) => _searchAddress(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Colors.blue,
                      ),
                      onPressed: _searchAddress,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: _selectedLocationInfo == null ? 30 : 220,
            right: 10,
            child: FloatingActionButton(
              onPressed: () => _moveCameraToLocation(_currentLocation),
              backgroundColor: Colors.white,
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
              ),
            ),
          ),
          if (_selectedLocationInfo != null)
            Positioned(
              bottom: 10,
              left: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(10),
                height: 200,
                width: MediaQuery.of(context).size.width * 0.95,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _selectedLocationInfo!['imagePath'],
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 5),
                            Text(
                              _selectedLocationInfo!['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF4C6EE5),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text('주소:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              _selectedLocationInfo!['address'],
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 5),
                            Text('메모:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              _selectedLocationInfo!['memo'],
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          _submitData();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Color(0xFF4C6EE5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '나의 장소에 추가',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
