import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:intl/intl.dart';

class DiscountManagementScreen extends StatefulWidget {
  const DiscountManagementScreen({super.key});

  @override
  _DiscountManagementScreenState createState() => _DiscountManagementScreenState();
}

class _DiscountManagementScreenState extends State<DiscountManagementScreen> {
  List<dynamic> discounts = [];
  bool isLoading = true;
  String errorMessage = '';

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _percentageController = TextEditingController();
  final _minOrderValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minDiscountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _fetchDiscounts();
  }

  Future<void> _fetchDiscounts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMessage = 'Vui lòng đăng nhập';
          });
          _showFlushbar('🔐 Vui lòng đăng nhập', Colors.red);
        }
        return;
      }

      // Kiểm tra cache
      final cachedDiscounts = prefs.getString('discounts_list');
      if (cachedDiscounts != null) {
        if (mounted) {
          setState(() {
            discounts = jsonDecode(cachedDiscounts);
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded discounts from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts"),
            headers: {"Authorization": "Bearer $authToken"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('discounts_list', response.body);
            if (mounted) {
              setState(() {
                discounts = data;
                isLoading = false;
                errorMessage = '';
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch discounts: ${response.statusCode}');
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = jsonDecode(response.body)['message'] ?? 'Không thể lấy danh sách mã giảm giá';
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching discounts after $maxRetries attempts: $e');
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
      if (kDebugMode) debugPrint('🔥 Error fetching discounts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi kết nối đến server';
        });
      }
    }
  }

  Future<void> _createDiscount() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.post(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts"),
            headers: {
              "Authorization": "Bearer $authToken",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "code": _codeController.text.trim(),
              "description": _descriptionController.text.trim(),
              "percentage": int.parse(_percentageController.text),
              "minOrderValue": int.parse(_minOrderValueController.text),
              "maxDiscount": int.parse(_maxDiscountController.text),
              "minDiscount": int.parse(_minDiscountController.text),
              "startDate": _selectedStartDate?.toIso8601String(),
              "endDate": _selectedEndDate?.toIso8601String(),
            }),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 201) {
            _showFlushbar('✅ Tạo mã giảm giá thành công', Colors.green);
            _fetchDiscounts();
            _clearForm();
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to create discount: ${response.statusCode}');
            _showFlushbar(
              jsonDecode(response.body)['message'] ?? 'Không thể tạo mã giảm giá',
              Colors.red,
            );
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error creating discount after $maxRetries attempts: $e');
            _showFlushbar('⚠️ Lỗi server', Colors.red);
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error creating discount: $e');
      _showFlushbar('⚠️ Lỗi server', Colors.red);
    }
  }

  Future<void> _deleteDiscount(String discountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.delete(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts/$discountId"),
            headers: {"Authorization": "Bearer $authToken"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            _showFlushbar('✅ Xóa mã giảm giá thành công', Colors.green);
            _fetchDiscounts();
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to delete discount: ${response.statusCode}');
            _showFlushbar(
              jsonDecode(response.body)['message'] ?? 'Không thể xóa mã giảm giá',
              Colors.red,
            );
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error deleting discount after $maxRetries attempts: $e');
            _showFlushbar('⚠️ Lỗi server', Colors.red);
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error deleting discount: $e');
      _showFlushbar('⚠️ Lỗi server', Colors.red);
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

  void _clearForm() {
    _codeController.clear();
    _descriptionController.clear();
    _percentageController.clear();
    _minOrderValueController.clear();
    _maxDiscountController.clear();
    _minDiscountController.clear();
    _startDateController.clear();
    _endDateController.clear();
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _selectedEndDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isDate = false}) {
    return FadeInUp(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          readOnly: isDate,
          onTap: isDate ? () => _selectDate(context, label.contains('bắt đầu')) : null,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
            errorStyle: GoogleFonts.poppins(fontSize: 12.sp),
            suffixIcon: isDate ? Icon(Icons.calendar_today, size: 20.sp) : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng ${isDate ? "chọn" : "nhập"} $label';
            }
            if (isNumber) {
              final num? number = num.tryParse(value);
              if (number == null || number <= 0) {
                return 'Giá trị phải là số dương';
              }
            }
            if (isDate) {
              try {
                DateTime.parse(value);
              } catch (e) {
                return 'Định dạng ngày không hợp lệ (YYYY-MM-DD)';
              }
            }
            return null;
          },
          style: GoogleFonts.poppins(fontSize: 14.sp),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200.w, height: 20.h, color: Colors.white),
            SizedBox(height: 16.h),
            ...List.generate(
              6,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Container(width: double.infinity, height: 50.h, color: Colors.white),
              ),
            ),
            SizedBox(height: 24.h),
            Container(width: 200.w, height: 20.h, color: Colors.white),
            SizedBox(height: 16.h),
            ...List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Card(
                  child: ListTile(
                    title: Container(width: 100.w, height: 16.h, color: Colors.white),
                    subtitle: Container(width: 150.w, height: 14.h, color: Colors.white),
                  ),
                ),
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
              colors: [Colors.orange, Colors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            "🎟 Quản lý mã giảm giá",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: isLoading
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
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInUp(
                        child: Text(
                          'Tạo mã giảm giá mới',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField('Mã giảm giá', _codeController),
                            _buildTextField('Mô tả', _descriptionController),
                            _buildTextField('Phần trăm giảm', _percentageController, isNumber: true),
                            _buildTextField('Giá trị đơn hàng tối thiểu', _minOrderValueController, isNumber: true),
                            _buildTextField('Giảm giá tối đa', _maxDiscountController, isNumber: true),
                            _buildTextField('Giảm giá tối thiểu', _minDiscountController, isNumber: true),
                            _buildTextField('Ngày bắt đầu', _startDateController, isDate: true),
                            _buildTextField('Ngày kết thúc', _endDateController, isDate: true),
                            SizedBox(height: 16.h),
                            FadeInUp(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _createDiscount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(vertical: 14.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange, Colors.amber],
                                      ),
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14.h),
                                    child: Text(
                                      'Tạo mã',
                                      style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      FadeInUp(
                        child: Text(
                          'Danh sách mã giảm giá',
                          style: GoogleFonts.poppins(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      discounts.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có mã giảm giá nào',
                                style: GoogleFonts.poppins(fontSize: 16.sp),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: discounts.length,
                              itemBuilder: (context, index) {
                                final discount = discounts[index];
                                return FadeInUp(
                                  delay: Duration(milliseconds: index * 100),
                                  child: Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    elevation: 2,
                                    child: ListTile(
                                      title: Text(
                                        discount['code'] ?? 'N/A',
                                        style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Giảm: ${discount['percentage']}%',
                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                          ),
                                          Text(
                                            'Đơn tối thiểu: ${discount['minOrderValue']} đ',
                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                          ),
                                          Text(
                                            'Hiệu lực: ${discount['startDate']?.substring(0, 10) ?? 'N/A'} - ${discount['endDate']?.substring(0, 10) ?? 'N/A'}',
                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                                        onPressed: () => _deleteDiscount(discount['_id']),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
    );
  }
}