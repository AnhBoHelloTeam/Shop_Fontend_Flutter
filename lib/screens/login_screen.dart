import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('last_email') ?? '';
    if (savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
    }
  }

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showFlushbar('Vui lòng nhập đầy đủ thông tin', Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    while (attempt <= maxRetries) {
      try {
        final response = await authService
            .login(emailController.text, passwordController.text)
            .timeout(const Duration(seconds: timeoutSeconds));

        if (mounted) {
          setState(() => isLoading = false);
        }

        if (response['success'] == true) {
          final token = response['data']['token'];
          await _saveLoginState(token, emailController.text);
          _showFlushbar('🎉 Đăng nhập thành công', Colors.green);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          if (kDebugMode) debugPrint('📡 Login successful for ${emailController.text}');
          return;
        } else {
          if (kDebugMode) debugPrint('⚠️ Login failed: ${response['error']}');
          _showFlushbar(response['error'] ?? 'Đăng nhập thất bại', Colors.red);
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error logging in (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt > maxRetries) {
          if (mounted) {
            setState(() => isLoading = false);
            _showFlushbar('Lỗi kết nối. Hãy thử lại.', Colors.red);
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> _saveLoginState(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('authToken', token);
    await prefs.setString('last_email', email);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeInDown(
                  child: Image.asset(
                    "assets/anhbia.png",
                    height: 250.h,
                    key: const Key('logoImage'),
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported,
                      size: 100.sp,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeIn(
                  child: Text(
                    "Chào mừng bạn quay lại!",
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    key: const Key('welcomeText'),
                  ),
                ),
                SizedBox(height: 20.h),
                FadeInUp(
                  child: TextField(
                    key: const Key('emailField'),
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, size: 20.sp, color: Colors.orange),
                      labelText: "Email",
                      labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
                      errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                  ),
                ),
                SizedBox(height: 10.h),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: TextField(
                    key: const Key('passwordField'),
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, size: 20.sp, color: Colors.orange),
                      labelText: "Mật khẩu",
                      labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
                      errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                  ),
                ),
                SizedBox(height: 20.h),
                isLoading
                    ? ZoomIn(
                        child: CircularProgressIndicator(
                          key: const Key('loadingIndicator'),
                          color: Colors.orange,
                        ),
                      )
                    : FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: ElevatedButton(
                          key: const Key('loginButton'),
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            padding: EdgeInsets.symmetric(horizontal: 100.w, vertical: 15.h),
                            elevation: 4,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange, Colors.amber],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(30)),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            child: Text(
                              "Đăng nhập",
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                SizedBox(height: 10.h),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: TextButton(
                    key: const Key('registerButton'),
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text(
                      "Chưa có tài khoản? Đăng ký ngay!",
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: TextButton(
                    key: const Key('goToHomeButton'),
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    child: Text(
                      "🛒 Xem sản phẩm (Không cần đăng nhập)",
                      style: GoogleFonts.poppins(
                        color: Colors.blueGrey,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}