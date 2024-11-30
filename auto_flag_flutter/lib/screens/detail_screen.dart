import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../provider/bottom_navigation_provider.dart';
import 'list_screen.dart';

class DetailScreen extends StatefulWidget {
  final DateTime registrationTime;
  final String imagePath;
  final String placeName;
  final String address;
  final String memo;
  final double latitude;
  final double longitude;

  DetailScreen({
    required this.registrationTime,
    required this.imagePath,
    required this.placeName,
    required this.address,
    required this.memo,
    required this.latitude,
    required this.longitude,
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isEditing = false;
  late TextEditingController placeNameController;
  late TextEditingController addressController;
  late TextEditingController memoController;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    placeNameController = TextEditingController(text: widget.placeName);
    addressController = TextEditingController(text: widget.address);
    memoController = TextEditingController(text: widget.memo);
  }

  Future<void> _updatePlace() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 ID를 찾을 수 없습니다.')),
        );
        return;
      }
      final registrationTime = widget.registrationTime.toIso8601String();
      final url = 'http://localhost:3000/update/$userId/$registrationTime';

      final body = json.encode({
        'title': placeNameController.text,
        'address': addressController.text,
        'memo': memoController.text,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정되었습니다.')),
        );
        context.read<BottomNavigationProvider>().setCurrentIndex(0);
        setState(() {
          context.read<BottomNavigationProvider>().setCurrentIndex(0);
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  Future<void> _deletePlace() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 ID를 찾을 수 없습니다.')),
        );
        return;
      }
      final registrationTime = widget.registrationTime.toIso8601String();
      final url = 'http://localhost:3000/delete/$userId/$registrationTime';

      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제되었습니다.')),
        );
        context.read<BottomNavigationProvider>().setCurrentIndex(0);
        setState(() {
          context.read<BottomNavigationProvider>().setCurrentIndex(0);
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? '장소 수정' : '장소 상세',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.imagePath,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildSectionTitle('장소 이름'),
            _buildTextField(placeNameController),
            SizedBox(height: 16),
            _buildSectionTitle('주소'),
            _buildTextField(addressController),
            SizedBox(height: 16),
            _buildSectionTitle('지도'),
            _buildMap(),
            SizedBox(height: 16),
            _buildSectionTitle('메모'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: memoController,
                enabled: isEditing,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isEditing
                        ? _updatePlace
                        : () => setState(() => isEditing = true),
                    child: Text(isEditing ? '저장하기' : '수정하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4C6EE5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                    ),
                  ),
                  SizedBox(width: 10),
                  if (isEditing)
                    ElevatedButton(
                      onPressed: _deletePlace,
                      child: Text('삭제하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TextField(
          controller: controller,
          enabled: isEditing,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('location_marker'),
                  position: LatLng(widget.latitude, widget.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              },
              minMaxZoomPreference: MinMaxZoomPreference(10, 18),
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
      ),
    );
  }
}
