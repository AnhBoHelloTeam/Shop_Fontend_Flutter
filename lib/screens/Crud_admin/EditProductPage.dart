import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  EditProductPage({required this.productId});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    if (authToken.isEmpty) {
      setState(() {
        _errorMessage = "Bạn cần đăng nhập để chỉnh sửa sản phẩm.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/${widget.productId}'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final product = json.decode(response.body);
        setState(() {
          _nameController.text = product['name'];
          _priceController.text = product['price'].toString();
          _descriptionController.text = product['description'];
          _categoryController.text = product['category'];
          _stockController.text = product['stock'].toString();
          _imageController.text = product['image'];
        });
      } else {
        setState(() {
          _errorMessage = "Không thể lấy thông tin sản phẩm.";
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Lỗi kết nối đến server.";
      });
    }
  }

  Future<void> _editProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    if (authToken.isEmpty) {
      setState(() {
        _errorMessage = "Bạn cần đăng nhập để chỉnh sửa sản phẩm.";
      });
      return;
    }

    final product = {
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'image': _imageController.text,
    };

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.put(
        Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/${widget.productId}'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(product),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = "Không thể chỉnh sửa sản phẩm.";
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Lỗi kết nối đến server.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("✏️ Chỉnh sửa sản phẩm"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_imageController.text.isNotEmpty)
                      Container(
                        height: 180,
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_imageController.text),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Tên sản phẩm"),
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: "Giá sản phẩm"),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập giá' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: "Mô tả sản phẩm"),
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
                    ),
                    TextFormField(
                      controller: _categoryController,
                      decoration: InputDecoration(labelText: "Thể loại"),
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập thể loại' : null,
                    ),
                    TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(labelText: "Số lượng tồn kho"),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập số lượng' : null,
                    ),
                    TextFormField(
                      controller: _imageController,
                      decoration: InputDecoration(labelText: "URL ảnh"),
                      validator: (value) =>
                          value!.isEmpty ? 'Vui lòng nhập URL ảnh' : null,
                      onChanged: (_) {
                        setState(() {}); // Cập nhật preview nếu URL thay đổi
                      },
                    ),
                    SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.save),
                        label: Text("Cập nhật sản phẩm"),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _editProduct();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
