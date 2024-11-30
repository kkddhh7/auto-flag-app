import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_friend_screen.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import 'friend_profile_page.dart';
import '../models/friend.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Friend> followings = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowings();
  }

  Future<void> _fetchFollowings() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 후 다시 시도해주세요.')),
      );
      return;
    }

    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/friends/$userId/followings'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          followings = data.map((e) => Friend.fromJson(e)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('팔로잉 목록을 가져오지 못했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 가져오는 중에 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '친구 목록',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4C6EE5),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendScreen()),
              );
            },
          ),
        ],
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: followings.isEmpty
          ? Center(child: Text('팔로잉 목록이 없습니다.'))
          : ListView.builder(
              itemCount: followings.length,
              itemBuilder: (context, index) {
                final following = followings[index];
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            AssetImage('assets/icons/user-icon.png'), // 아이콘 추가
                        radius: 24,
                      ),
                      title: Text(
                        following.id,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        following.introduction,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FriendProfilePage(friend: following),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                      height: 0,
                      indent: 72,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
