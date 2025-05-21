import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/screens/Crud_admin/AddProductPage.dart';
import 'package:shop_frontend/screens/Crud_admin/ProductListPage.dart';
import 'package:shop_frontend/screens/Listuser/UserListPage.dart';
import 'package:shop_frontend/screens/OrderStatusScreen.dart';
import 'package:shop_frontend/screens/admin_order_management_screen.dart';
import 'package:shop_frontend/screens/discount_management_screen.dart';

import 'package:shop_frontend/services/token_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic> user = {};
  bool isLoading = true;
  String errorMessage = "";
  String? authToken;
  late IO.Socket socket;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    initSocket();
  }

  void initSocket() {
    socket = IO.io('https://shop-backend-nodejs.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Connected to socket');
      socket.emit('join', user['role'] == 'admin' ? 'admin' : TokenUtils.getUserIdFromToken(authToken ?? ''));
    });

    socket.on('notification', (data) {
      setState(() {
        notifications.add(data);
      });
    });

    socket.onDisconnect((_) => print('Disconnected from socket'));
  }

  Future<void> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken') ?? '';

    if (authToken!.isEmpty) {
      setState(() {
        errorMessage = "Bạn cần đăng nhập để xem thông tin tài khoản";
        isLoading = false;
      });
      return;
    }

    final userId = TokenUtils.getUserIdFromToken(authToken!);

    if (userId == null) {
      setState(() {
        errorMessage = "Lỗi khi lấy userId từ token";
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/users/$userId"),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          user = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Không thể lấy thông tin người dùng";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Lỗi kết nối đến server";
        isLoading = false;
      });
    }
  }

  bool isAdmin() {
    return user['role'] == 'admin';
  }

  void _navigateToUserList() {
    isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => UserListPage()))
        : _showAccessDenied();
  }

  void _navigateToAddProduct() {
    isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductPage()))
        : _showAccessDenied();
  }

  void _navigateToProductList() {
    isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListPage()))
        : _showAccessDenied();
  }

  void _navigateToOrderManagement() {
    isAdmin()
        ? Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminOrderManagementScreen(authToken: authToken!),
            ),
          )
        : _showAccessDenied();
  }

  void _navigateToDiscountManagement() {
    isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => DiscountManagementScreen()))
        : _showAccessDenied();
  }

  void _navigateToOrderStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(authToken: authToken!),
      ),
    );
  }

  void _navigateToReturnPolicy() {
    Navigator.pushNamed(context, '/return-policy');
  }

  void _showAccessDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bạn không có quyền truy cập"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tài khoản", style: TextStyle(fontSize: 20.sp)),
        backgroundColor: Colors.orange,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Thông báo"),
                      content: notifications.isEmpty
                          ? Text("Chưa có thông báo")
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return ListTile(
                                  title: Text(notification['message']),
                                  subtitle: Text(notification['createdAt']),
                                  trailing: Icon(
                                    notification['isRead']
                                        ? Icons.check_circle
                                        : Icons.circle,
                                    color: notification['isRead'] ? Colors.green : Colors.red,
                                  ),
                                  onTap: () async {
                                    if (!notification['isRead']) {
                                      try {
                                        await http.put(
                                          Uri.parse(
                                              "https://shop-backend-nodejs.onrender.com/api/notifications/${notification['_id']}/read"),
                                          headers: {
                                            "Authorization": "Bearer $authToken",
                                          },
                                        );
                                        setState(() {
                                          notification['isRead'] = true;
                                        });
                                      } catch (e) {
                                        print("Lỗi khi đánh dấu thông báo: $e");
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Đóng"),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (notifications.any((n) => !n['isRead']))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      "${notifications.where((n) => !n['isRead']).length}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(fontSize: 16.sp)))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user['avatar'] != null)
                        Center(
                          child: CircleAvatar(
                            radius: 50.r,
                            backgroundImage: NetworkImage(user['avatar']),
                          ),
                        ),
                      SizedBox(height: 20.h),
                      _buildInfoRow("Tên", user['name']),
                      _buildInfoRow("Email", user['email']),
                      _buildInfoRow("Số điện thoại", user['phone']),
                      _buildInfoRow("Địa chỉ", user['address']),
                      _buildInfoRow("Vai trò", user['role']),
                      _buildInfoRow("Ngày tạo", _formatDate(user['createdAt'])),
                      SizedBox(height: 30.h),
                      _buildButton("Trạng thái đơn hàng", _navigateToOrderStatus),
                      _buildButton("Chính sách trả hàng", _navigateToReturnPolicy),
                      if (isAdmin()) ...[
                        _buildAdminButton("Thêm sản phẩm", _navigateToAddProduct, key: Key('addProductButton')),
                        _buildAdminButton("Quản lý sản phẩm", _navigateToProductList, key: Key('productListButton')),
                        _buildAdminButton("Quản lý người dùng", _navigateToUserList),
                        _buildAdminButton("Quản lý đơn hàng", _navigateToOrderManagement, key: Key('orderManagementButton')),
                        _buildAdminButton("Quản lý mã giảm giá", _navigateToDiscountManagement, key: Key('discountManagementButton')),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title:", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(
              value ?? "Chưa cập nhật",
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Không xác định";
    DateTime date = DateTime.parse(isoDate);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(title, style: TextStyle(fontSize: 16.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(String title, VoidCallback onPressed, {Key? key}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: key,
          onPressed: onPressed,
          child: Text(title, style: TextStyle(fontSize: 16.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}