import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/screens/CategoriesScreen.dart';
import 'package:shop_frontend/screens/HotBuyProducts.dart';
import 'package:shop_frontend/screens/OrderHistory_screen.dart';
import 'package:shop_frontend/screens/user_sceen.dart';
import '../services/product_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> products = [];
  List<String> categories = [];
  int _currentIndex = 0;
  bool isLoading = true;
  final ProductService productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String? authToken;

  String selectedCategory = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          selectedCategory = args;
          loadProducts();
        });
      }
    });

    loadCategories();
    loadProducts();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    print('🔍 HomeScreen authToken: "$token"');
    setState(() {
      authToken = token;
    });
  }

  Future<void> loadCategories() async {
    try {
      final response = await http.get(Uri.parse("https://shop-backend-nodejs.onrender.com/api/products/categories"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = List<String>.from(data)..insert(0, '');
        });
      }
    } catch (e) {
      print("Lỗi khi lấy danh mục: $e");
    }
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await productService.fetchProducts(
        category: selectedCategory,
        name: searchQuery,
      );
      setState(() {
        products = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Lỗi khi tải sản phẩm: $e");
    }
  }

  Future<void> addToCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng đăng nhập để mua hàng."),
          action: SnackBarAction(
            label: "Đăng nhập",
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse("https://shop-backend-nodejs.onrender.com/api/cart/add"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({"productId": productId, "quantity": 1}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã thêm sản phẩm vào giỏ hàng")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể thêm vào giỏ hàng. Vui lòng thử lại.")),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Đăng xuất"),
        content: Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              await prefs.remove('authToken');
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: TextField(
          key: Key('searchTextField'),
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Tìm kiếm sản phẩm...",
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              loadProducts();
            });
          },
        ),
        actions: [
          IconButton(
            key: Key('cartIconButton'),
            icon: Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 0
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        value: selectedCategory.isEmpty ? null : selectedCategory,
                        hint: Text("Chọn danh mục"),
                        isExpanded: true,
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value ?? '';
                            loadProducts();
                          });
                        },
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat.isEmpty ? "Tất cả" : cat),
                          );
                        }).toList(),
                      ),
                    ),
                    HotBuyProducts(),
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              int columns = constraints.maxWidth < 600
                                  ? 2
                                  : constraints.maxWidth < 900
                                      ? 3
                                      : 4;
                              return GridView.builder(
                                padding: EdgeInsets.all(10),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.7,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return Card(
                                    key: Key('productCard_$index'),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                              image: DecorationImage(
                                                image: product['image'] != null && product['image'].isNotEmpty
                                                    ? NetworkImage(product['image'])
                                                    : AssetImage('assets/placeholder.png') as ImageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'] ?? 'Không có tên',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 5),
                                              Text("Giá: ${product['price'] ?? 'N/A'} đ",
                                                  style: TextStyle(color: Colors.red)),
                                              SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  TextButton(
                                                    key: Key('detailButton_$index'),
                                                    onPressed: () => Navigator.pushNamed(context, '/product_detail',
                                                        arguments: product),
                                                    child: Text("Chi tiết", style: TextStyle(color: Colors.blue)),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => addToCart(product['_id']),
                                                    icon: Icon(Icons.shopping_cart, color: Colors.orange),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ],
                ),
              )
            : _currentIndex == 1
                ? CategoriesScreen()
                : _currentIndex == 2
                    ? OrderHistoryScreen()
                    : AccountPage(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AccountPage()));
          } else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesScreen()));
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Danh mục"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Lịch sử"),
          BottomNavigationBarItem(
            key: Key('accountIconButton'),
            icon: Icon(Icons.person),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}