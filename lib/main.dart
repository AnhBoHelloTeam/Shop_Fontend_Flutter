import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/screens/OrderStatusScreen.dart';
import 'package:shop_frontend/screens/ReturnPolicyScreen.dart';
import 'package:shop_frontend/screens/buycard/CartScreen.dart';
import 'package:shop_frontend/screens/CategoriesScreen.dart';
import 'package:shop_frontend/screens/OrderHistory_screen.dart';
import 'package:shop_frontend/screens/buycard/checkout_screen.dart';
import 'package:shop_frontend/screens/home_screen.dart';
import 'package:shop_frontend/screens/login_screen.dart';
import 'package:shop_frontend/screens/buycard/product_detail_screen.dart';
import 'package:shop_frontend/screens/register_screen.dart';
import 'package:shop_frontend/screens/admin_order_management_screen.dart';
import 'package:shop_frontend/screens/discount_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  final String authToken = await getAuthToken();

  runApp(
    ScreenUtilInit(
      designSize: Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MyApp(isLoggedIn: isLoggedIn, authToken: authToken),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String authToken;

  const MyApp({Key? key, required this.isLoggedIn, required this.authToken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn && authToken.isNotEmpty ? '/home' : '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => HomeScreen());
          case '/product_detail':
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(),
              settings: settings, // Truyền settings để giữ arguments
            );
          case '/cart':
            return MaterialPageRoute(builder: (_) => CartScreen());
          case '/order-history':
            return MaterialPageRoute(builder: (_) => OrderHistoryScreen());
          case '/checkout':
            return MaterialPageRoute(builder: (_) => CheckoutPage());
          case '/categories':
            return MaterialPageRoute(builder: (_) => CategoriesScreen());
          case '/admin-orders':
            return _buildAuthRoute((token) => AdminOrderManagementScreen(authToken: token), settings);
          case '/discounts':
            return _buildAuthRoute((token) => DiscountManagementScreen(), settings);
          case '/order-status':
            return _buildAuthRoute((token) => OrderStatusScreen(authToken: token), settings);
          case '/return-policy':
            return MaterialPageRoute(builder: (_) => ReturnPolicyScreen());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('Route không tồn tại: ${settings.name}')),
              ),
            );
        }
      },
    );
  }

  Route<dynamic> _buildAuthRoute(Widget Function(String) builder, RouteSettings settings) {
    if (authToken.isEmpty) {
      return MaterialPageRoute(builder: (_) => LoginScreen());
    }
    return MaterialPageRoute(builder: (_) => builder(authToken));
  }
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

Future<String> getAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('authToken') ?? '';
}