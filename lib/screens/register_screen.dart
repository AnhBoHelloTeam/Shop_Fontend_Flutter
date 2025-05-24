import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  File? avatarImage;
  String selectedRole = "user";
  bool isLoading = false;

  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSavedForm();
  }

  Future<void> _loadSavedForm() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('last_email') ?? '';
    nameController.text = prefs.getString('last_name') ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        avatarImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      _showFlushbar('Vui lòng kiểm tra thông tin nhập', Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String phone = phoneController.text.trim();
    final String address = addressController.text.trim();
    final String avatarPath = avatarImage?.path ??
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTGEZghB-stFaphAohNqDAhEaXOWQJ9XvHKJw&s";

    while (attempt <= maxRetries) {
      try {
        final response = await authService
            .register(
              name: name,
              email: email,
              password: password,
              phone: phone,
              address: address,
              avatar: avatarPath,
              role: selectedRole,
            )
            .timeout(const Duration(seconds: timeoutSeconds));

        if (mounted) {
          setState(() => isLoading = false);
        }

        if (response.containsKey('error')) {
          final errorMessage = response['error'];
          if (kDebugMode) debugPrint('⚠️ Register failed: $errorMessage');
          _showFlushbar(
            errorMessage.contains('Email đã tồn tại')
                ? 'Email đã tồn tại. Vui lòng chọn email khác.'
                : errorMessage,
            Colors.red,
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_email', email);
        await prefs.setString('last_name', name);

        if (kDebugMode) debugPrint('📡 Register successful for $email');
        _showFlushbar('✅ Đăng ký thành công!', Colors.green);
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error registering (attempt ${attempt + 1}): $e');
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInDown(
                    child: GestureDetector(
                      key: const Key('avatarPicker'),
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50.r,
                        backgroundImage: avatarImage != null ? FileImage(avatarImage!) : null,
                        child: avatarImage == null
                            ? Icon(Icons.camera_alt, size: 50.sp, color: Colors.grey)
                            : null,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  FadeInUp(
                    child: _buildTextField(
                      nameController,
                      "Họ tên",
                      Icons.person,
                      key: const Key('nameField'),
                    ),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: _buildEmailField(),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildPasswordField(passwordController, "Mật khẩu"),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: _buildPasswordField(confirmPasswordController, "Xác nhận mật khẩu", passwordController),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _buildPhoneField(),
                  ),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: _buildTextField(
                      addressController,
                      "Địa chỉ",
                      Icons.location_on,
                      key: const Key('addressField'),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  isLoading
                      ? ZoomIn(
                          child: const CircularProgressIndicator(color: Colors.orange),
                        )
                      : FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: ElevatedButton(
                            key: const Key('registerButton'),
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                              padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 15.h),
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
                                "Đăng ký",
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
                    delay: const Duration(milliseconds: 700),
                    child: TextButton(
                      key: const Key('backToLoginButton'),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Đã có tài khoản? Đăng nhập ngay!",
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
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
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {Key? key}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: key,
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20.sp, color: Colors.orange),
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
          errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
        ),
        style: GoogleFonts.poppins(fontSize: 14.sp),
        validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _buildEmailField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: const Key('emailField'),
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.email, size: 20.sp, color: Colors.orange),
          labelText: "Email",
          labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
          errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
        ),
        style: GoogleFonts.poppins(fontSize: 14.sp),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Vui lòng nhập email";
          if (value.contains(' ')) return "Email không được chứa khoảng trống";
          return EmailValidator.validate(value.trim()) ? null : "Email không hợp lệ";
        },
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, [TextEditingController? confirm]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: label == "Mật khẩu" ? const Key('passwordField') : const Key('confirmPasswordField'),
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, size: 20.sp, color: Colors.orange),
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
          errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
        ),
        style: GoogleFonts.poppins(fontSize: 14.sp),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Vui lòng nhập $label";
          if (value.length < 6) return "Mật khẩu ít nhất 6 ký tự";
          if (value.contains(' ')) return "Mật khẩu không được chứa khoảng trống";
          if (confirm != null && value != confirm.text) return "Mật khẩu không khớp";
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: const Key('phoneField'),
        controller: phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.phone, size: 20.sp, color: Colors.orange),
          labelText: "Số điện thoại (không bắt buộc)",
          labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
          errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
        ),
        style: GoogleFonts.poppins(fontSize: 14.sp),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          return RegExp(r'^[0-9]{9,12}$').hasMatch(value.trim())
              ? null
              : "Số điện thoại không hợp lệ";
        },
      ),
    );
  }
}