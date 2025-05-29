import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Widget màn hình yêu cầu trả hàng
class ReturnRequestScreen extends StatefulWidget {
  final String orderId;
  final List<Map<String, dynamic>> items;

  const ReturnRequestScreen({
    super.key,
    required this.orderId,
    required this.items,
  });

  @override
  _ReturnRequestScreenState createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends State<ReturnRequestScreen> {
  final TextEditingController _reasonController = TextEditingController();
  XFile? _selectedImage;
  bool _isSubmitting = false;

  // Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        final fileSize = await File(pickedFile.path).length();
        if (fileSize > 5 * 1024 * 1024) {
          _showFlushbar('Ảnh quá lớn, chọn ảnh dưới 5MB', Colors.red);
          return;
        }
        setState(() {
          _selectedImage = pickedFile;
        });
        if (kDebugMode) debugPrint('📸 Đã chọn ảnh: ${pickedFile.path}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi chọn ảnh: $e');
      _showFlushbar('Không thể chọn ảnh, thử lại', Colors.red);
    }
  }

  // Hiển thị thông báo
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

  // Gửi yêu cầu trả hàng
  Future<void> _submitReturnRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      _showFlushbar('Vui lòng nhập lý do trả hàng', Colors.red);
      return;
    }
    if (_reasonController.text.length > 500) {
      _showFlushbar('Lý do quá dài, tối đa 500 ký tự', Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        _showFlushbar('Vui lòng đăng nhập lại', Colors.red);
        return;
      }

      final uri = Uri.parse('https://shop-backend-nodejs.onrender.com/api/orders/return');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $authToken'
        ..fields['orderId'] = widget.orderId
        ..fields['reason'] = _reasonController.text;

      if (_selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (mounted) {
          _showFlushbar('✅ Yêu cầu trả hàng đã được gửi', Colors.green);
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showFlushbar(jsonResponse['error'] ?? 'Không thể gửi yêu cầu', Colors.red);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi gửi yêu cầu trả hàng: $e');
      if (mounted) {
        _showFlushbar('Lỗi server, vui lòng thử lại', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
              colors: [Colors.red, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            '📦 Yêu cầu trả hàng',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInUp(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng #${widget.orderId.substring(0, 8)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Sản phẩm:',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.items.isNotEmpty)
                        ...widget.items.map((item) {
                          final product = item['product'] is Map ? item['product'] : {};
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                product['image'] ?? 'https://via.placeholder.com/50',
                                width: 50.w,
                                height: 50.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.error,
                                  size: 30.sp,
                                ),
                              ),
                            ),
                            title: Text(
                              product['name'] ?? 'Không rõ',
                              style: GoogleFonts.poppins(fontSize: 14.sp),
                            ),
                            subtitle: Text(
                              'Số lượng: ${item['quantity'] ?? 0}',
                              style: GoogleFonts.poppins(fontSize: 13.sp),
                            ),
                          );
                        }).toList()
                      else
                        Text(
                          'Không có sản phẩm',
                          style: GoogleFonts.poppins(fontSize: 14.sp),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Lý do trả hàng',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: TextField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Nhập lý do trả hàng (tối đa 500 ký tự)',
                  labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  errorText: _reasonController.text.isNotEmpty && _reasonController.text.length > 500
                      ? 'Lý do quá dài'
                      : null,
                ),
                style: GoogleFonts.poppins(fontSize: 14.sp),
                maxLines: 4,
                maxLength: 500,
                onChanged: (value) {
                  if (mounted) setState(() {});
                },
              ),
            ),
            SizedBox(height: 16.h),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Tải ảnh minh chứng (tùy chọn, tối đa 5MB)',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: GestureDetector(
                onTap: _isSubmitting ? null : _pickImage,
                child: Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey[100],
                  ),
                  child: _selectedImage == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40.sp, color: Colors.grey[600]),
                              Text(
                                'Chọn ảnh từ thư viện',
                                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            height: 120.h,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReturnRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.sp,
                          ),
                        )
                      : Text(
                          'Gửi yêu cầu trả hàng',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}