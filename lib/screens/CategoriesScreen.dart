import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/products/categories"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<String>.from(data);
          isLoading = false;
        });
      } else {
        print("❌ Lỗi lấy danh mục: ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi API danh mục: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh mục sản phẩm"),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 12,
                      vertical: 12,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/home',
                              arguments: categories[index],
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    categories[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                       fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 20),
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
