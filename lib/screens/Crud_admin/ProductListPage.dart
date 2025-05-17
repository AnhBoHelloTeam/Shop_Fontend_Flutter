import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_frontend/screens/Crud_admin/EditProductPage.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> products = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('https://shop-backend-nodejs.onrender.com/api/products'));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Không thể tải danh sách sản phẩm.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi kết nối tới server.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📦 Danh sách sản phẩm"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _fetchProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: product['image'] != null && product['image'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          title: Text(
                            product['name'] ?? "Không có tên",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Giá: ${product['price']} VND",
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          trailing: Icon(Icons.edit, color: Colors.teal),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProductPage(productId: product['_id']),
                              ),
                            );
                            if (result == true) {
                              _fetchProducts();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
