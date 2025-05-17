import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ Thêm dòng này
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shop_frontend/screens/buycard/CartScreen.dart';
import 'package:shop_frontend/screens/CategoriesScreen.dart';
import 'package:shop_frontend/screens/OrderHistory_screen.dart';
import 'package:shop_frontend/screens/buycard/checkout_screen.dart';
import 'package:shop_frontend/screens/home_screen.dart';
import 'package:shop_frontend/screens/login_screen.dart';
import 'package:shop_frontend/screens/buycard/product_detail_screen.dart';
import 'package:shop_frontend/screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();

  runApp(
    ScreenUtilInit(
      designSize: Size(390, 844), // 👈 kích thước thiết kế gốc
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/product_detail': (context) => ProductDetailScreen(),
        '/cart': (context) => CartScreen(),
        '/order-history': (context) => OrderHistoryPage(),
        '/checkout': (context) => CheckoutPage(),
        '/categories': (context) => CategoriesScreen(),
      },
    );
  }
}

// Hàm kiểm tra trạng thái đăng nhập
Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}
