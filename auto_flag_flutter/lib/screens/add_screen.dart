import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import '../provider/bottom_navigation_provider.dart';

class AddScreen extends StatefulWidget {
  @override
  _AddScreenState createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _address;
  double? _latitude;
  double? _longitude;
  GoogleMapController? _mapController;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      await _uploadImageAndGetDetails(_image!);
    }
  }

  @override
  void initState() {
    super.initState();
    _addressController.text = _address ?? '';
  }

  Future<void> _uploadImageAndGetDetails(File image) async {
    final uri = Uri.parse('http://localhost:3000/upload-image');

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final responseJson = json.decode(responseBody);

      setState(() {
        _address = responseJson['address'];
        _latitude = responseJson['latitude'];
        _longitude = responseJson['longitude'];
        _addressController.text = _address ?? '';

        if (_mapController != null && _latitude != null && _longitude != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(_latitude!, _longitude!)),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드 실패')),
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

    if (_image == null || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    final uri = Uri.parse('http://localhost:3000/register-place');
    var request = http.MultipartRequest('POST', uri)
      ..fields['id'] = userId
      ..fields['title'] = _titleController.text
      ..fields['address'] = _addressController.text
      ..fields['latitude'] = _latitude.toString()
      ..fields['longitude'] = _longitude.toString()
      ..fields['memo'] = _contentController.text
      ..fields['registration_time'] = DateTime.now().toUtc().toIso8601String()
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장소가 성공적으로 등록되었습니다!')),
      );

      context.read<BottomNavigationProvider>().setCurrentIndex(1);
    } else {
      final responseBody = await response.stream.bytesToString();
      print('서버 응답 오류: $responseBody');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '장소 등록',
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
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '사진',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_image == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Image.asset(
                            'assets/icons/add_pic_button.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                      ),
                    if (_image != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _image!,
                                  height: 300,
                                  width: 300,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 18,
                              top: 0,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: CircleAvatar(
                                  backgroundColor: Colors.red,
                                  radius: 15,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '장소 이름',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '주소',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '지도',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          height: 200,
                          child: _latitude != null && _longitude != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: GoogleMap(
                                      onMapCreated: (controller) {
                                        _mapController = controller;
                                      },
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(_latitude!, _longitude!),
                                        zoom: 14,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: MarkerId('location_marker'),
                                          position:
                                              LatLng(_latitude!, _longitude!),
                                          icon: BitmapDescriptor
                                              .defaultMarkerWithHue(
                                                  BitmapDescriptor.hueRed),
                                        ),
                                      },
                                      minMaxZoomPreference:
                                          MinMaxZoomPreference(10, 18),
                                      zoomGesturesEnabled: true,
                                      scrollGesturesEnabled: true,
                                      myLocationButtonEnabled: false),
                                )
                              : Center(child: Text("좌표가 없습니다.")),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '메모',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: _submitData,
                            child: Text('등록하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color(0xFF4C6EE5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
