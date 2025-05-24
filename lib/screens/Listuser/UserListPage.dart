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
import 'package:shop_frontend/screens/Listuser/user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage = "Vui lòng đăng nhập để xem danh sách.";
            isLoading = false;
          });
        }
        _showFlushbar('🔐 Vui lòng đăng nhập', Colors.red);
        return;
      }

      // Kiểm tra cache
      final cachedUsers = prefs.getString('users_list');
      if (cachedUsers != null) {
        if (mounted) {
          setState(() {
            users = jsonDecode(cachedUsers);
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded users from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/users"),
            headers: {'Authorization': 'Bearer $authToken'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('users_list', response.body);
            if (mounted) {
              setState(() {
                users = data;
                isLoading = false;
                errorMessage = "";
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch users: ${response.statusCode}');
            if (mounted) {
              setState(() {
                errorMessage = "Không thể lấy danh sách người dùng.";
                isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching users after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                errorMessage = "Lỗi kết nối đến server.";
                isLoading = false;
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching users: $e');
      if (mounted) {
        setState(() {
          errorMessage = "Lỗi kết nối đến server.";
          isLoading = false;
        });
      }
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
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 30.r, backgroundColor: Colors.white),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100.w, height: 16.h, color: Colors.white),
                          SizedBox(height: 4.h),
                          Container(width: 80.w, height: 14.h, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
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
            "👥 Danh sách người dùng",
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
                        onRefresh: _fetchUsers,
                        color: Colors.orange,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.w : 16.w, vertical: 12.h),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final avatarUrl = user['avatar'] ?? '';
                            return FadeInUp(
                              delay: Duration(milliseconds: index * 100),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                margin: EdgeInsets.symmetric(vertical: 8.h),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12.r),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailPage(userId: user['_id']),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(16.w),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 30.r,
                                          child: ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: avatarUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor: Colors.grey[100]!,
                                                child: Container(color: Colors.white),
                                              ),
                                              errorWidget: (context, url, error) => Image.asset(
                                                'assets/images/default_avatar.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user['name'] ?? 'Không có tên',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 20.sp : 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                user['email'] ?? 'Không có email',
                                                style: GoogleFonts.poppins(
                                                  fontSize: isTablet ? 18.sp : 16.sp,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
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