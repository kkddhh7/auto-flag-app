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

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  loc.Location _location = loc.Location();
  static const LatLng _initialPosition =
      LatLng(37.24087302228478, 127.07974744744283);
  LatLng _currentLocation = _initialPosition;
  Map<String, dynamic>? _selectedLocationInfo;
  String? _selectedMarkerId;

  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadLocationMarkers();
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

  Future<void> _loadLocationMarkers() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) return;

    final url = 'http://localhost:3000/list?ID=$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List locations = json.decode(response.body);
      locations.forEach((location) {
        final latitude = location['Latitude'];
        final longitude = location['Longitude'];

        if (latitude != null && longitude != null) {
          final LatLng position = LatLng(latitude, longitude);
          _addLocationMarker(
            position,
            location['Title'],
            location['Address'],
            location['Memo'],
            location['ImagePath'],
          );
        } else {
          print("Invalid location data: $location");
        }
      });
    } else {
      print("Failed to load locations");
    }
  }

  void _addLocationMarker(LatLng position, String title, String address,
      String memo, String imagePath) {
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
        _showLocationInfo(title, address, memo, imagePath);
      },
    );

    setState(() {
      _markers[title] = marker;
    });
  }

  void _moveCameraToLocation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _showLocationInfo(
      String title, String address, String memo, String imagePath) {
    setState(() {
      _selectedLocationInfo = {
        'title': title,
        'address': address,
        'memo': memo,
        'imagePath': 'http://localhost:3000/$imagePath',
      };
      _selectedMarkerId = title;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  width: 1,
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
            bottom: _selectedLocationInfo == null ? 100 : 260,
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
              bottom: 100,
              left: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(10),
                height: 150,
                width: MediaQuery.of(context).size.width * 0.95,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
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
                    Expanded(
                      child: Column(
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
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 5),
                          Text('주소:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _selectedLocationInfo!['address'],
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 5),
                          Text('메모:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _selectedLocationInfo!['memo'],
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}
