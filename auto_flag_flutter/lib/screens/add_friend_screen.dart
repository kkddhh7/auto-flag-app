import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class AddFriendScreen extends StatefulWidget {
  @override
  _AddFriendScreenState createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, String>? searchResult;

  Future<void> _searchFriend() async {
    final userId = _searchController.text;
    final response = await http
        .get(Uri.parse('http://localhost:3000/friends/$userId/search'));

    if (response.statusCode == 200) {
      setState(() {
        searchResult = Map<String, String>.from(json.decode(response.body));
      });
    } else {
      setState(() {
        searchResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자를 찾을 수 없습니다.')),
      );
    }
  }

  Future<void> _addFriend(String followeeId) async {
    final followerId = Provider.of<UserProvider>(context, listen: false).userId;
    final response = await http.post(
      Uri.parse('http://localhost:3000/friends/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'followerId': followerId,
        'followeeId': followeeId,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팔로우 성공!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('팔로우 실패: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '친구 추가',
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
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '친구 ID 검색',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchFriend,
                ),
              ),
            ),
            if (searchResult != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: BorderSide(color: Color(0xFF4C6EE5), width: 2),
                ),
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage('assets/icons/user-icon.png'),
                  ),
                  title: Text(searchResult!['id']!),
                  subtitle: Text(searchResult!['introduction']!),
                  trailing: ElevatedButton(
                    onPressed: () => _addFriend(searchResult!['id']!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF4C6EE5),
                      side: BorderSide.none,
                      elevation: 0,
                    ),
                    child: Text('팔로우'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
