import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class ReturnPolicyScreen extends StatelessWidget {
  const ReturnPolicyScreen({super.key});

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
            '📜 Chính sách trả hàng',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FadeIn(
              child: Text(
                'Chính sách trả hàng và hoàn tiền',
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            FadeIn(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Chúng tôi cam kết mang đến trải nghiệm mua sắm tốt nhất cho bạn. Dưới đây là chính sách trả hàng và hoàn tiền của chúng tôi:',
                style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 16.h),
            FadeIn(
              delay: const Duration(milliseconds: 200),
              child: _buildSectionTitle('1. Điều kiện trả hàng'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 300),
              child: _buildBulletPoint('Sản phẩm chưa sử dụng, còn nguyên bao bì và tem nhãn.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 400),
              child: _buildBulletPoint('Thời gian trả hàng trong vòng 7 ngày kể từ ngày nhận hàng.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 500),
              child: _buildBulletPoint('Sản phẩm bị lỗi do nhà sản xuất hoặc giao sai mẫu mã.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 600),
              child: _buildBulletPoint('Có biên lai hoặc hóa đơn mua hàng.'),
            ),
            SizedBox(height: 16.h),
            FadeIn(
              delay: const Duration(milliseconds: 700),
              child: _buildSectionTitle('2. Quy trình trả hàng'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 800),
              child: _buildBulletPoint('Liên hệ bộ phận hỗ trợ qua email support@shop.com hoặc hotline 0123 456 789.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 900),
              child: _buildBulletPoint('Gửi sản phẩm về địa chỉ kho: 123 Đường ABC, Quận 1, TP.HCM.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: _buildBulletPoint('Chờ xác nhận từ đội ngũ kiểm tra (3-5 ngày làm việc).'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 1100),
              child: _buildBulletPoint('Hoàn tiền qua phương thức thanh toán ban đầu trong 7 ngày sau khi xác nhận.'),
            ),
            SizedBox(height: 16.h),
            FadeIn(
              delay: const Duration(milliseconds: 1200),
              child: _buildSectionTitle('3. Các trường hợp không được trả hàng'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 1300),
              child: _buildBulletPoint('Sản phẩm đã sử dụng, hư hỏng do lỗi của khách hàng.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 1400),
              child: _buildBulletPoint('Sản phẩm không còn trong thời hạn 7 ngày trả hàng.'),
            ),
            FadeIn(
              delay: const Duration(milliseconds: 1500),
              child: _buildBulletPoint('Sản phẩm thuộc danh mục không được trả (ví dụ: đồ lót, thực phẩm).'),
            ),
            SizedBox(height: 16.h),
            FadeIn(
              delay: const Duration(milliseconds: 1600),
              child: Text(
                'Nếu bạn có thắc mắc, vui lòng liên hệ chúng tôi để được hỗ trợ!',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: GoogleFonts.poppins(fontSize: 16.sp)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}