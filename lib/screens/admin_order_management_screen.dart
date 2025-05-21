import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_frontend/screens/OrderStatusScreen.dart';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class AdminOrderManagementScreen extends StatefulWidget {
  final String authToken;

  const AdminOrderManagementScreen({Key? key, required this.authToken}) : super(key: key);

  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? errorMessage;
  late IO.Socket socket;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
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
      socket.emit('join', 'admin'); // Admin join room
    });

    socket.on('notification', (data) {
      setState(() {
        notifications.add(data);
      });
    });

    socket.onDisconnect((_) => print('Disconnected from socket'));
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders"),
        headers: {"Authorization": "Bearer ${widget.authToken}"},
      );

      print("📡 Response danh sách đơn hàng: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orders = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Lỗi khi lấy danh sách đơn hàng: ${response.statusCode}";
        });
      }
    } catch (e) {
      print("Lỗi khi lấy danh sách đơn hàng: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Lỗi kết nối đến server: $e";
      });
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/$orderId/status"),
        headers: {
          "Authorization": "Bearer ${widget.authToken}",
          "Content-Type": "application/json",
        },
        body: json.encode({"status": status}),
      );

      print("📡 Response cập nhật trạng thái: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cập nhật trạng thái thành công")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi cập nhật trạng thái: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Lỗi khi cập nhật trạng thái: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối đến server: $e")),
      );
    }
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
        title: Text("Quản lý đơn hàng"),
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
                                            "Authorization": "Bearer ${widget.authToken}",
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
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderStatusScreen(authToken: widget.authToken),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchOrders,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(errorMessage!, style: TextStyle(color: Colors.red)),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchOrders,
                          child: Text("Thử lại"),
                        ),
                      ],
                    ),
                  )
                : orders.isEmpty
                    ? Center(child: Text("Chưa có đơn hàng nào"))
                    : ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Đơn hàng #${order['_id']}",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text("Khách hàng: ${order['user']['name']}"),
                                  Text("Email: ${order['user']['email']}"),
                                  SizedBox(height: 8),
                                  Text("Sản phẩm:"),
                                  ...order['items'].map<Widget>((item) {
                                    return Text(
                                      "- ${item['product']['name']} (x${item['quantity']})",
                                    );
                                  }).toList(),
                                  SizedBox(height: 8),
                                  Text("Tổng tiền: ${order['totalPrice']} VNĐ"),
                                  if (order['discount']['code'] != null)
                                    Text(
                                      "Mã giảm giá: ${order['discount']['code']} (-${order['discount']['amount']} VNĐ)",
                                    ),
                                  SizedBox(height: 8),
                                  Text("Trạng thái: ${order['status']}"),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (order['status'] == 'pending')
                                        ElevatedButton(
                                          onPressed: () => updateOrderStatus(order['_id'], 'confirmed'),
                                          child: Text("Xác nhận"),
                                        ),
                                      SizedBox(width: 8),
                                      if (order['status'] == 'confirmed')
                                        ElevatedButton(
                                          onPressed: () => updateOrderStatus(order['_id'], 'shipped'),
                                          child: Text("Giao hàng"),
                                        ),
                                      SizedBox(width: 8),
                                      if (order['status'] != 'cancelled' && order['status'] != 'delivered')
                                        ElevatedButton(
                                          onPressed: () => updateOrderStatus(order['_id'], 'cancelled'),
                                          child: Text("Hủy"),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}