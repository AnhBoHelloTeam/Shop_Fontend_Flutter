import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:email_validator/email_validator.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
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

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => avatarImage = File(pickedFile.path));
    }
  }

  void register() async {
  print('✅ Bắt đầu register()');

  final form = _formKey.currentState!;
  if (!form.validate()) {
    print('⚠️ Form không hợp lệ, đang lấy lỗi đầu tiên...');
    String? firstError = _getFirstValidationError();
    if (firstError != null) {
      print('❌ Lỗi đầu tiên: $firstError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❗$firstError'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
    }
    return;
  }

  print('✅ Form hợp lệ, bắt đầu đăng ký...');
  setState(() => isLoading = true);

  final String name = nameController.text.trim();
  final String email = emailController.text.trim();
  final String password = passwordController.text.trim();
  final String phone = phoneController.text.trim();
  final String address = addressController.text.trim();
  final String avatarPath = avatarImage?.path ??
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTGEZghB-stFaphAohNqDAhEaXOWQJ9XvHKJw&s";

  print('📤 Gửi thông tin đăng ký:');
  print('👤 name: $name');
  print('📧 email: $email');
  print('🔒 password: $password');
  print('📞 phone: $phone');
  print('🏠 address: $address');
  print('🖼️ avatarPath: $avatarPath');
  print('🧑‍💼 role: $selectedRole');

  final response = await authService.register(
    name: name,
    email: email,
    password: password,
    phone: phone,
    address: address,
    avatar: avatarPath,
    role: selectedRole,
  );

  print('📥 Phản hồi từ authService: $response');

  setState(() => isLoading = false);

  if (response.containsKey('error')) {
    String errorMessage = response['error'];
    print('❌ Lỗi từ server: $errorMessage');

    if (errorMessage.contains('Email đã tồn tại')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Email đã tồn tại. Vui lòng chọn email khác.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(20),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          margin: EdgeInsets.all(20),
        ),
      );
    }

    return;
  }

  print('✅ Đăng ký thành công!');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('✅ Đăng ký thành công!')),
  );
  Navigator.pop(context);
}

  String? _getFirstValidationError() {
    // Kiểm tra nếu tất cả trường trống
    if (nameController.text.trim().isEmpty &&
        emailController.text.trim().isEmpty &&
        passwordController.text.trim().isEmpty &&
        confirmPasswordController.text.trim().isEmpty &&
        addressController.text.trim().isEmpty &&
        phoneController.text.trim().isEmpty) {
      return "Vui lòng điền đầy đủ thông tin";
    }
    // Kiểm tra tất cả các trường có trống hay không
    if (nameController.text.trim().isEmpty) return "Vui lòng nhập họ tên";
    if (emailController.text.trim().isEmpty) return "Vui lòng nhập email";
    if (emailController.text.contains(' ')) return "Email không được chứa khoảng trống";
    if (!EmailValidator.validate(emailController.text.trim())) return "Email không hợp lệ";
    if (passwordController.text.trim().isEmpty) return "Vui lòng nhập mật khẩu";
    if (passwordController.text.trim().length < 6) return "Mật khẩu ít nhất 6 ký tự";
    if (confirmPasswordController.text.trim().isEmpty) return "Vui lòng xác nhận mật khẩu";
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) return "Mật khẩu không khớp";
    if (passwordController.text.contains(' ')) return "Mật khẩu không được chứa khoảng trống";
    if (addressController.text.trim().isEmpty) return "Vui lòng nhập địa chỉ";
    if (phoneController.text.trim().isEmpty) return "Vui lòng nhập số điện thoại";
    if (phoneController.text.trim().isNotEmpty &&
        !RegExp(r'^[0-9]{9,12}$').hasMatch(phoneController.text.trim())) {
      return "Số điện thoại không hợp lệ";
    }

    return null;
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
                  GestureDetector(
                    key: Key('avatarPicker'),
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundImage: avatarImage != null ? FileImage(avatarImage!) : null,
                      child: avatarImage == null
                          ? Icon(Icons.camera_alt, size: 50.sp)
                          : null,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  buildTextField(nameController, "Họ tên", Icons.person, "Vui lòng nhập họ tên", key: Key('nameField')),
                  buildEmailField(),
                  buildPasswordField(passwordController, "Mật khẩu"),
                  buildPasswordField(confirmPasswordController, "Xác nhận mật khẩu", passwordController),
                  buildPhoneField(),
                  buildTextField(addressController, "Địa chỉ", Icons.location_on, "Vui lòng nhập địa chỉ", key: Key('addressField')),
                  SizedBox(height: 20.h),
                  isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          key: Key('registerButton'),
                          onPressed: register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                            padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 15.h),
                          ),
                          child: Text(
                            "Đăng ký",
                            style: TextStyle(fontSize: 18.sp, color: Colors.white),
                          ),
                        ),
                  SizedBox(height: 10.h),
                  TextButton(
                    key: Key('backToLoginButton'),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Đã có tài khoản? Đăng nhập ngay!",
                      style: TextStyle(color: Colors.orange, fontSize: 14.sp),
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

  Widget buildTextField(TextEditingController controller, String label, IconData icon, String errorMessage, {Key? key}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: key,
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
        ),
        validator: (value) => value!.trim().isEmpty ? errorMessage : null,
      ),
    );
  }

  Widget buildEmailField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: Key('emailField'),
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.email),
          labelText: "Email",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
        ),
        validator: (value) =>
            EmailValidator.validate(value!.trim()) ? null : "Email không hợp lệ",
      ),
    );
  }

  Widget buildPasswordField(TextEditingController controller, String label, [TextEditingController? confirm]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: label == "Mật khẩu"
            ? Key('passwordField')
            : Key('confirmPasswordField'),
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Vui lòng nhập mật khẩu";
          if (value.length < 6) return "Mật khẩu ít nhất 6 ký tự";
          if (confirm != null && value != confirm.text) return "Mật khẩu không khớp";
          return null;
        },
      ),
    );
  }

  Widget buildPhoneField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: TextFormField(
        key: Key('phoneField'),
        controller: phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.phone),
          labelText: "Số điện thoại (không bắt buộc)",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r)),
        ),
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