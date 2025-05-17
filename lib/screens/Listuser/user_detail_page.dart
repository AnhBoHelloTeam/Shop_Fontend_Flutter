import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;

  UserDetailPage({required this.userId});

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/users/${widget.userId}"),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          user = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "❌ Không thể lấy thông tin người dùng";
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
      appBar: AppBar(
        title: Text("Thông tin người dùng"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SafeArea(
        child: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : errorMessage.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(errorMessage, style: TextStyle(fontSize: 18, color: Colors.red)),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          bool isTablet = constraints.maxWidth > 600;

                          return Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: (user?['avatar'] ?? "").isNotEmpty
                                      ? NetworkImage(user!['avatar'])
                                      : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                  radius: isTablet ? 80 : 60,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  user?['name'] ?? 'Không có tên',
                                  style: TextStyle(fontSize: isTablet ? 26 : 22, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  user?['email'] ?? 'Không có email',
                                  style: TextStyle(fontSize: isTablet ? 20 : 18, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 25),
                                _buildInfoRow("📞 Số điện thoại", user?['phone']),
                                _buildInfoRow("📍 Địa chỉ", user?['address']),
                                _buildInfoRow("📅 Ngày tạo", user?['createdAt']),
                                _buildInfoRow("🔄 Cập nhật", user?['updatedAt']),
                                SizedBox(height: 20),
                                Text(
                                  "👑 Vai trò: ${user?['role'] ?? 'Không xác định'}",
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
          SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: "$label: ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: value ?? "Không có dữ liệu",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
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
