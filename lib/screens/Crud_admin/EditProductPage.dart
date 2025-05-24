import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:another_flushbar/flushbar.dart';

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({required this.productId, super.key});

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

  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = "Bạn cần đăng nhập để chỉnh sửa sản phẩm.";
            _isLoading = false;
          });
        }
        _showFlushbar('🔐 Vui lòng đăng nhập', Colors.red);
        return;
      }

      // Kiểm tra cache
      final cachedProduct = prefs.getString('product_${widget.productId}');
      if (cachedProduct != null) {
        final product = jsonDecode(cachedProduct);
        if (mounted) {
          setState(() {
            _nameController.text = product['name'];
            _priceController.text = product['price'].toString();
            _descriptionController.text = product['description'];
            _categoryController.text = product['category'];
            _stockController.text = product['stock'].toString();
            _imageController.text = product['image'];
            _isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded product from cache: product_${widget.productId}');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/${widget.productId}'),
            headers: {'Authorization': 'Bearer $authToken'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final product = jsonDecode(response.body);
            await prefs.setString('product_${widget.productId}', response.body);
            if (mounted) {
              setState(() {
                _nameController.text = product['name'];
                _priceController.text = product['price'].toString();
                _descriptionController.text = product['description'];
                _categoryController.text = product['category'];
                _stockController.text = product['stock'].toString();
                _imageController.text = product['image'];
                _isLoading = false;
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch product: ${response.statusCode}');
            if (mounted) {
              setState(() {
                _errorMessage = "Không thể lấy thông tin sản phẩm.";
                _isLoading = false;
              });
            }
            _showFlushbar('❌ Không thể lấy thông tin sản phẩm!', Colors.red);
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching product after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                _errorMessage = "Lỗi kết nối đến server.";
                _isLoading = false;
              });
            }
            _showFlushbar('⚠️ Lỗi server, vui lòng thử lại!', Colors.red);
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching product: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối đến server.";
          _isLoading = false;
        });
      }
      _showFlushbar('⚠️ Lỗi server, vui lòng thử lại!', Colors.red);
    }
  }

  Future<void> _editProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = {
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'image': _imageController.text,
    };

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = "Bạn cần đăng nhập để chỉnh sửa sản phẩm.";
            _isLoading = false;
          });
        }
        _showFlushbar('🔐 Vui lòng đăng nhập', Colors.red);
        return;
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.put(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/${widget.productId}'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(product),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            await prefs.setString('product_${widget.productId}', json.encode(product));
            _showFlushbar('✅ Sản phẩm đã được cập nhật thành công!', Colors.green);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.pop(context, true);
            }
            return;
          } else {
            if (mounted) {
              setState(() {
                _errorMessage = "Không thể chỉnh sửa sản phẩm.";
                _isLoading = false;
              });
            }
            _showFlushbar('❌ Không thể chỉnh sửa sản phẩm!', Colors.red);
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error editing product after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                _errorMessage = "Lỗi kết nối đến server.";
                _isLoading = false;
              });
            }
            _showFlushbar('⚠️ Lỗi server, vui lòng thử lại!', Colors.red);
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error editing product: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối đến server.";
          _isLoading = false;
        });
      }
      _showFlushbar('⚠️ Lỗi server, vui lòng thử lại!', Colors.red);
    }
  }

  void _showFlushbar(String message, Color backgroundColor) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundGradient: LinearGradient(
        colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
      ),
      borderRadius: BorderRadius.circular(10.r),
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
    ).show(context);
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return FadeInUp(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
            errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
          ),
          style: GoogleFonts.poppins(fontSize: 14.sp),
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
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Container(width: double.infinity, height: 180.h, color: Colors.white),
            SizedBox(height: 16.h),
            ...List.generate(
              5,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Container(width: double.infinity, height: 50.h, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            "✏️ Chỉnh sửa sản phẩm",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _errorMessage.isNotEmpty
              ? Center(
                  child: FadeInUp(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 16.sp),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_imageController.text.isNotEmpty)
                          FadeInUp(
                            child: Container(
                              height: 180.h,
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: CachedNetworkImage(
                                  imageUrl: _imageController.text,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                        _buildTextField("Tên sản phẩm", _nameController),
                        _buildTextField("Giá sản phẩm", _priceController, isNumber: true),
                        _buildTextField("Mô tả sản phẩm", _descriptionController),
                        _buildTextField("Thể loại", _categoryController),
                        _buildTextField("Số lượng tồn kho", _stockController, isNumber: true),
                        _buildTextField("URL ảnh", _imageController, onChanged: (value) {
                          if (mounted) setState(() {});
                        }),
                        if (_errorMessage.isNotEmpty)
                          FadeInUp(
                            child: Padding(
                              padding: EdgeInsets.all(8.w),
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.poppins(color: Colors.red, fontSize: 14.sp),
                              ),
                            ),
                          ),
                        SizedBox(height: 24.h),
                        ZoomIn(
                          child: ElevatedButton(
                            onPressed: _editProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              elevation: 0,
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal, Colors.tealAccent],
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.save, color: Colors.white),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Cập nhật sản phẩm",
                                    style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.white),
                                  ),
                                ],
                              ),
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