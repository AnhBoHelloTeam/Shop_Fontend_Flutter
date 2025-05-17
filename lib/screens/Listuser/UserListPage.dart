import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/screens/Listuser/user_detail_page.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/users"),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "❌ Không thể lấy danh sách người dùng";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "❌ Lỗi kết nối đến server";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Danh sách người dùng"), backgroundColor: Colors.deepOrange),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = constraints.maxWidth >= 600;
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 16, vertical: 12),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final avatarUrl = user['avatar'] ?? '';
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailPage(userId: user['_id']),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['name'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            user['email'],
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.deepOrange, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
