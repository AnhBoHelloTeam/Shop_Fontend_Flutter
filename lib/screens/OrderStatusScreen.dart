import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderStatusScreen extends StatefulWidget {
  final String authToken;

  const OrderStatusScreen({Key? key, required this.authToken}) : super(key: key);

  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  String selectedStatus = 'all';
  List<dynamic> orders = [];
  bool isLoading = true;
  String? errorMessage;

  final List<Map<String, String>> statusTabs = [
    {'label': 'Tất cả', 'value': 'all'},
    {'label': 'Chờ thanh toán', 'value': 'pending'},
    {'label': 'Vận chuyển', 'value': 'confirmed'},
    {'label': 'Chờ giao', 'value': 'shipped'},
    {'label': 'Hoàn thành', 'value': 'delivered'},
    {'label': 'Đã hủy', 'value': 'cancelled'},
    {'label': 'Trả hàng/Hoàn tiền', 'value': 'returned'},
  ];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/status/$selectedStatus"),
        headers: {"Authorization": "Bearer ${widget.authToken}"},
      );

      print("📡 Response đơn hàng trạng thái $selectedStatus: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // Kiểm tra nếu data là List, gán vào orders
          if (data is List) {
            orders = data;
          } else {
            // Nếu data là Map (ví dụ: { message: "No orders found" }), gán orders rỗng
            orders = [];
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trạng thái đơn hàng"),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statusTabs.length,
              itemBuilder: (context, index) {
                final tab = statusTabs[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Text(tab['label']!),
                    selected: selectedStatus == tab['value'],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedStatus = tab['value']!;
                        });
                        fetchOrders();
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
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
                        ? Center(child: Text("Chưa có đơn hàng nào", style: TextStyle(fontSize: 16, color: Colors.grey)))
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
                                      if (order['discount'] != null && order['discount']['code'] != null)
                                        Text(
                                          "Mã giảm giá: ${order['discount']['code']} (-${order['discount']['amount']} VNĐ)",
                                        ),
                                      SizedBox(height: 8),
                                      Text("Trạng thái: ${order['status']}"),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}