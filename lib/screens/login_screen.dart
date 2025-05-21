import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;

  void login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Vui lòng nhập đầy đủ thông tin!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.login(
        emailController.text,
        passwordController.text,
      );

      setState(() => isLoading = false);

      if (response['success'] == true) {
        String token = response['data']['token'];
        await saveLoginState(token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 Đăng nhập thành công!')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${response['error']}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚫 Lỗi kết nối! Hãy thử lại sau.')),
      );
    }
  }

  Future<void> saveLoginState(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('authToken', token);
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
                Image.asset(
                  "assets/anhbia.png",
                  height: 250.h,
                  key: Key('logoImage'), // Thêm Key vào logo
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 100.sp, color: Colors.grey);
                  },
                ),
                SizedBox(height: 20.h),
                Text(
                  "Chào mừng bạn quay lại!",
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  key: Key('welcomeText'), // Thêm Key vào văn bản chào mừng
                ),
                SizedBox(height: 20.h),
                TextField(
                  key: Key('emailField'),  // Thêm Key vào trường email
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    labelText: "Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
                  ),
                ),
                SizedBox(height: 10.h),
                TextField(
                  key: Key('passwordField'),  // Thêm Key vào trường mật khẩu
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    labelText: "Mật khẩu",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
                  ),
                ),
                SizedBox(height: 20.h),
                isLoading
                    ? CircularProgressIndicator(key: Key('loadingIndicator'))  // Thêm Key vào CircularProgressIndicator
                    : ElevatedButton(
                        key: Key('loginButton'),  // Thêm Key vào nút đăng nhập
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                          padding: EdgeInsets.symmetric(horizontal: 100.w, vertical: 15.h),
                        ),
                        child: Text(
                          "Đăng nhập",
                          style: TextStyle(fontSize: 18.sp, color: Colors.white),
                        ),
                      ),
                SizedBox(height: 10.h),
                TextButton(
                  key: Key('registerButton'),  // Thêm Key vào nút đăng ký
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text(
                    "Chưa có tài khoản? Đăng ký ngay!",
                    style: TextStyle(color: Colors.orange, fontSize: 14.sp),
                  ),
                ),
                  //////// nút xem sản phẩm đoá
                TextButton(
                  key: Key('goToHomeButton'), // Key để test UI
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  child: Text(
                    "🛒 Xem sản phẩm (Không cần đăng nhập)",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 14.sp),
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
