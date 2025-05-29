import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shop_frontend/screens/TKBank/AdminWalletView.dart';
import 'package:shop_frontend/screens/TKBank/UserWalletView.dart';
import 'package:shop_frontend/screens/TKBank/WalletService.dart';


class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  Map<String, dynamic> user = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userData = await _walletService.getUserInfo();
      if (mounted) {
        setState(() {
          user = userData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi kết nối đến server: $e';
          isLoading = false;
        });
      }
      if (kDebugMode) debugPrint('🔥 Error loading user info: $e');
    }
  }

  bool _isAdmin() {
    return user['role'] == 'admin';
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
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            _isAdmin() ? '💳 Quản lý ví' : '💳 Ví điện tử',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 24.sp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : errorMessage.isNotEmpty
              ? Center(
                  child: FadeInUp(
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: _isAdmin()
                      ? AdminWalletView(user: user, walletService: _walletService)
                      : UserWalletView(user: user, walletService: _walletService),
                ),
    );
  }
}