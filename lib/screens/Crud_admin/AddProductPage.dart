import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageController = TextEditingController();

  String _errorMessage = "";
  bool _isLoading = false;

  // Gắn các Key để test
  final nameKey = Key('productNameField');
  final priceKey = Key('productPriceField');
  final descKey = Key('productDescField');
  final categoryKey = Key('productCategoryField');
  final stockKey = Key('productStockField');
  final imageKey = Key('productImageField');
  final addButtonKey = Key('addProductButton');

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final int? price = int.tryParse(_priceController.text);
    final int? stock = int.tryParse(_stockController.text);

    final product = {
      'name': _nameController.text,
      'price': price,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'stock': stock,
      'image': _imageController.text,
    };

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final response = await http.post(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/products"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(product),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Sản phẩm đã được thêm thành công!")),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = "❌ Không thể thêm sản phẩm. Vui lòng thử lại!";
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "❌ Lỗi kết nối đến server!";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    Function(String)? onChanged,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập $label';
          }
          if (isNumber) {
            final num? number = num.tryParse(value);
            if (number == null || (label == "Giá sản phẩm" && number <= 0)) {
              return 'Giá trị không hợp lệ';
            }
          }
          return null;
        },
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🆕 Thêm sản phẩm"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
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
                    _buildTextField("Tên sản phẩm", _nameController, fieldKey: nameKey),
                    _buildTextField("Giá sản phẩm", _priceController, isNumber: true, fieldKey: priceKey),
                    _buildTextField("Mô tả", _descriptionController, fieldKey: descKey),
                    _buildTextField("Danh mục", _categoryController, fieldKey: categoryKey),
                    _buildTextField("Số lượng", _stockController, isNumber: true, fieldKey: stockKey),
                    _buildTextField("Link ảnh", _imageController, onChanged: (_) {
                      setState(() {});
                    }, fieldKey: imageKey),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      key: addButtonKey,
                      onPressed: _addProduct,
                      icon: Icon(Icons.add),
                      label: Text("Thêm sản phẩm"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
