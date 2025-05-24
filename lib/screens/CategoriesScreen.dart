import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> categories = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // Kiểm tra cache
      final cachedCategories = prefs.getString('categories_list');
      if (cachedCategories != null) {
        if (mounted) {
          setState(() {
            categories = List<String>.from(jsonDecode(cachedCategories));
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded categories from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/products/categories"),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('categories_list', response.body);
            if (mounted) {
              setState(() {
                categories = List<String>.from(data);
                isLoading = false;
                errorMessage = '';
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch categories: ${response.statusCode}');
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = 'Không thể lấy danh sách danh mục';
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching categories after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = 'Lỗi kết nối đến server';
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching categories: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi kết nối đến server';
        });
      }
    }
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                child: Container(width: 150.w, height: 18.h, color: Colors.white),
              ),
            );
          },
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
              colors: [Colors.orange, Colors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            "🗂 Danh mục sản phẩm",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? _buildSkeletonLoader()
            : errorMessage.isNotEmpty
                ? Center(
                    child: FadeInUp(
                      child: Text(
                        errorMessage,
                        style: GoogleFonts.poppins(color: Colors.red, fontSize: 16.sp),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isTablet = constraints.maxWidth >= 600;
                      return RefreshIndicator(
                        onRefresh: _loadCategories,
                        color: Colors.orange,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.w : 16.w, vertical: 12.h),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 100),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12.r),
                                  onTap: () {
                                    Navigator.pushNamed(context, '/home', arguments: categories[index]);
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            categories[index],
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 20.sp : 18.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, color: Colors.orange, size: 20.sp),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}