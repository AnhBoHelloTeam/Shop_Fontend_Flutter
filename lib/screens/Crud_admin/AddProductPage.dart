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

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

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
  final nameKey = const Key('productNameField');
  final priceKey = const Key('productPriceField');
  final descKey = const Key('productDescField');
  final categoryKey = const Key('productCategoryField');
  final stockKey = const Key('productStockField');
  final imageKey = const Key('productImageField');
  final addButtonKey = const Key('addProductButton');

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final product = {
      'name': _nameController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _categoryController.text,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'image': _imageController.text,
    };

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = "";
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = "Bạn cần đăng nhập để thêm sản phẩm.";
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
          final response = await http.post(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/products"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode(product),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 201) {
            _showFlushbar('✅ Sản phẩm đã được thêm thành công!', Colors.green);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.pop(context, true);
            }
            return;
          } else {
            if (mounted) {
              setState(() {
                _errorMessage = "❌ Không thể thêm sản phẩm.";
                _isLoading = false;
              });
            }
            _showFlushbar('❌ Không thể thêm sản phẩm!', Colors.red);
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error adding product after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                _errorMessage = "❌ Lỗi kết nối đến server!";
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
      if (kDebugMode) debugPrint('🔥 Error adding product: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "❌ Lỗi kết nối đến server!";
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
    Key? fieldKey,
  }) {
    return FadeInUp(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: TextFormField(
          key: fieldKey,
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
            "🆕 Thêm sản phẩm",
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
                    _buildTextField("Tên sản phẩm", _nameController, fieldKey: nameKey),
                    _buildTextField("Giá sản phẩm", _priceController, isNumber: true, fieldKey: priceKey),
                    _buildTextField("Mô tả", _descriptionController, fieldKey: descKey),
                    _buildTextField("Danh mục", _categoryController, fieldKey: categoryKey),
                    _buildTextField("Số lượng", _stockController, isNumber: true, fieldKey: stockKey),
                    _buildTextField("Link ảnh", _imageController, fieldKey: imageKey, onChanged: (value) {
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
                    SizedBox(height: 20.h),
                    ZoomIn(
                      child: ElevatedButton(
                        key: addButtonKey,
                        onPressed: _addProduct,
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
                              const Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 8.w),
                              Text(
                                "Thêm sản phẩm",
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