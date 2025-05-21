import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReturnPolicyScreen extends StatelessWidget {
  const ReturnPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chính sách trả hàng', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
            Text(
              'Chính sách trả hàng và hoàn tiền',
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Text(
              'Chúng tôi cam kết mang đến trải nghiệm mua sắm tốt nhất cho bạn. Dưới đây là chính sách trả hàng và hoàn tiền của chúng tôi:',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            _buildSectionTitle('1. Điều kiện trả hàng'),
            _buildBulletPoint('Sản phẩm chưa sử dụng, còn nguyên bao bì và tem nhãn.'),
            _buildBulletPoint('Thời gian trả hàng trong vòng 7 ngày kể từ ngày nhận hàng.'),
            _buildBulletPoint('Sản phẩm bị lỗi do nhà sản xuất hoặc giao sai mẫu mã.'),
            _buildBulletPoint('Có biên lai hoặc hóa đơn mua hàng.'),
            SizedBox(height: 16.h),
            _buildSectionTitle('2. Quy trình trả hàng'),
            _buildBulletPoint('Liên hệ bộ phận hỗ trợ qua email support@shop.com hoặc hotline 0123 456 789.'),
            _buildBulletPoint('Gửi sản phẩm về địa chỉ kho: 123 Đường ABC, Quận 1, TP.HCM.'),
            _buildBulletPoint('Chờ xác nhận từ đội ngũ kiểm tra (3-5 ngày làm việc).'),
            _buildBulletPoint('Hoàn tiền qua phương thức thanh toán ban đầu trong 7 ngày sau khi xác nhận.'),
            SizedBox(height: 16.h),
            _buildSectionTitle('3. Các trường hợp không được trả hàng'),
            _buildBulletPoint('Sản phẩm đã sử dụng, hư hỏng do lỗi của khách hàng.'),
            _buildBulletPoint('Sản phẩm không còn trong thời hạn 7 ngày trả hàng.'),
            _buildBulletPoint('Sản phẩm thuộc danh mục không được trả (ví dụ: đồ lót, thực phẩm).'),
            SizedBox(height: 16.h),
            Text(
              'Nếu bạn có thắc mắc, vui lòng liên hệ chúng tôi để được hỗ trợ!',
              style: TextStyle(fontSize: 16.sp, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, top: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16.sp)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16.sp))),
        ],
      ),
    );
  }
}