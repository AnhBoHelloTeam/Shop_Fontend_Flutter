import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shop_frontend/screens/TKBank/WalletModel.dart';
import 'dart:convert';
import 'package:shop_frontend/screens/TKBank/WalletService.dart';
import 'package:flutter/services.dart'; // For Clipboard

class UserWalletView extends StatefulWidget {
  final Map<String, dynamic> user;
  final WalletService walletService;

  const UserWalletView({super.key, required this.user, required this.walletService});

  @override
  _UserWalletViewState createState() => _UserWalletViewState();
}

class _UserWalletViewState extends State<UserWalletView> {
  double balance = 0.0;
  List<Transaction> transactions = [];
  List<NotificationModel> notifications = [];
  List<PaymentMethod> paymentMethods = [];
  PaymentMethod? selectedPaymentMethod;
  String? transactionCode;
  bool isLoading = true;
  final TextEditingController depositController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.walletService.onNotification((data) {
      if (mounted) {
        setState(() {
          notifications.insert(0, NotificationModel.fromJson(data));
        });
        _showFlushbar('Thông báo: ${data['message']}', Colors.blue);
      }
    });
  }

  @override
  void dispose() {
    depositController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final walletData = await widget.walletService.getWallet();
      final transactionData = await widget.walletService.getTransactions();
      final notificationData = await widget.walletService.getNotifications();
      final paymentMethodsData = await widget.walletService.getPaymentMethods();
      if (mounted) {
        setState(() {
          balance = walletData['balance']?.toDouble() ?? 0.0;
          transactions = transactionData.map((e) => Transaction.fromJson(e)).toList();
          notifications = notificationData.map((e) => NotificationModel.fromJson(e)).toList();
          paymentMethods = paymentMethodsData.map((e) => PaymentMethod.fromJson(e)).toList();
          if (paymentMethods.isNotEmpty) {
            selectedPaymentMethod = paymentMethods[0];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _showFlushbar('Lỗi tải dữ liệu: $e', Colors.red);
      }
    }
  }

  Future<void> _generateTransactionCode(double amount) async {
    if (selectedPaymentMethod == null) {
      _showFlushbar('Chưa chọn phương thức thanh toán', Colors.red);
      return;
    }
    if (amount <= 0) {
      _showFlushbar('Vui lòng nhập số tiền hợp lệ', Colors.red);
      return;
    }

    try {
      final code = await widget.walletService.generateTransactionCode(
        widget.user['_id'],
        amount,
        selectedPaymentMethod!.id,
      );
      if (mounted) {
        setState(() {
          transactionCode = code;
        });
      }
    } catch (e) {
      _showFlushbar('Lỗi tạo mã QR: $e', Colors.red);
    }
  }

  Future<void> _depositMoney(double amount) async {
    if (amount <= 0 || transactionCode == null || selectedPaymentMethod == null) {
      _showFlushbar('Vui lòng nhập số tiền hợp lệ và tạo mã giao dịch', Colors.red);
      return;
    }

    try {
      await widget.walletService.depositMoney(amount, transactionCode!, selectedPaymentMethod!.id);
      _showFlushbar('Yêu cầu nạp tiền đã được gửi', Colors.green);
      if (mounted) {
        setState(() {
          transactionCode = null;
          depositController.clear();
        });
      }
      await _loadData();
    } catch (e) {
      _showFlushbar('Lỗi nạp tiền: $e', Colors.red);
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await widget.walletService.markNotificationAsRead(notificationId);
      if (mounted) {
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            notifications[index].isRead = true;
          }
        });
      }
    } catch (e) {
      _showFlushbar('Lỗi đánh dấu thông báo: $e', Colors.red);
    }
  }

  void _showFlushbar(String message, Color backgroundColor) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundGradient: LinearGradient(
        colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
      ),
      borderRadius: BorderRadius.circular(10.0.r),
      margin: EdgeInsets.all(8.0.w),
      padding: EdgeInsets.all(10.0.w),
    ).show(context);
  }

  void _copyTransactionCode() {
    if (transactionCode != null) {
      Clipboard.setData(ClipboardData(text: transactionCode!));
      _showFlushbar('Đã sao chép mã giao dịch', Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController withdrawController = TextEditingController();
    final TextEditingController bankController = TextEditingController();

    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                    child: Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông tin người dùng',
                            style: GoogleFonts.poppins(
                              fontSize: 18.0.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8.0.h),
                          Text(
                            'Tên: ${widget.user['name'] ?? 'Chưa cập nhật'}',
                            style: GoogleFonts.poppins(fontSize: 16.0.sp),
                          ),
                          Text(
                            'Email: ${widget.user['email'] ?? 'Chưa cập nhật'}',
                            style: GoogleFonts.poppins(fontSize: 16.0.sp),
                          ),
                          Text(
                            'Hạng thành viên: ${widget.user['membershipTier'] ?? 'Member'}',
                            style: GoogleFonts.poppins(fontSize: 16.0.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0.h),
                FadeIn(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.0.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.blue,
                                  size: 24.0.sp,
                                ),
                                SizedBox(width: 8.0.w),
                                Text(
                                  'Ví điện tử',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18.0.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0.h),
                            Text(
                              'Số dư: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(balance)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16.0.h),
                            Text(
                              'Nạp tiền để mua sắm',
                              style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.grey),
                            ),
                            SizedBox(height: 8.0.h),
                            paymentMethods.isEmpty
                                ? Text(
                                    'Chưa có phương thức thanh toán nào',
                                    style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.red),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<PaymentMethod>(
                                        value: selectedPaymentMethod,
                                        items: paymentMethods.map((method) {
                                          return DropdownMenuItem<PaymentMethod>(
                                            value: method,
                                            child: Text(
                                              '${method.name} (${method.type == 'bank' ? 'Ngân hàng' : 'Ví điện tử'})',
                                              style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedPaymentMethod = value;
                                            transactionCode = null; // Reset transaction code
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Phương thức thanh toán',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                          prefixIcon: Icon(Icons.payment, size: 20.0.sp),
                                        ),
                                      ),
                                      if (selectedPaymentMethod != null) ...[
                                        SizedBox(height: 12.0.h),
                                        Text(
                                          'Chi tiết phương thức thanh toán:',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.0.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4.0.h),
                                        Text(
                                          'Tên: ${selectedPaymentMethod!.name}',
                                          style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                        ),
                                        Text(
                                          'Loại: ${selectedPaymentMethod!.type == 'bank' ? 'Ngân hàng' : 'Ví điện tử'}',
                                          style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                        ),
                                        Text(
                                          'Thông tin: ${selectedPaymentMethod!.details.isNotEmpty ? selectedPaymentMethod!.details : 'Không có thông tin'}',
                                          style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                        ),
                                        SizedBox(height: 12.0.h),
                                        Text(
                                          'Mã QR thanh toán (cung cấp bởi Admin):',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.0.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        SizedBox(height: 8.0.h),
                                        Center(
                                          child: selectedPaymentMethod!.qrCodeUrl != null &&
                                                  selectedPaymentMethod!.qrCodeUrl!.isNotEmpty
                                              ? Image.network(
                                                  selectedPaymentMethod!.qrCodeUrl!,
                                                  width: 150.0.w,
                                                  height: 150.0.w,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => Text(
                                                    'Không thể tải mã QR thanh toán',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14.0.sp,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  'Không có mã QR cho phương thức này',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14.0.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ],
                                  ),
                            SizedBox(height: 12.0.h),
                            TextField(
                              controller: depositController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Số tiền nạp (VNĐ)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                prefixIcon: Icon(Icons.attach_money, size: 20.0.sp),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14.0.sp),
                            ),
                            SizedBox(height: 12.0.h),
                            if (transactionCode != null) ...[
                              Text(
                                'Mã QR giao dịch (dùng để xác nhận nạp tiền):',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.0.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 8.0.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Mã giao dịch: $transactionCode',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.0.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, size: 20.0.sp),
                                    onPressed: _copyTransactionCode,
                                    tooltip: 'Sao chép mã giao dịch',
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0.h),
                              Center(
                                child: QrImageView(
                                  data: jsonEncode({
                                    'transactionCode': transactionCode,
                                    'amount': double.tryParse(depositController.text) ?? 0,
                                    'userId': widget.user['_id'],
                                    'paymentMethodId': selectedPaymentMethod!.id,
                                  }),
                                  version: QrVersions.auto,
                                  size: 150.0.w,
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.all(8.0.w),
                                ),
                              ),
                              SizedBox(height: 12.0.h),
                            ],
                            ZoomIn(
                              child: ElevatedButton(
                                onPressed: paymentMethods.isEmpty || depositController.text.isEmpty
                                    ? null
                                    : () async {
                                        final amount = double.tryParse(depositController.text) ?? 0;
                                        if (transactionCode == null) {
                                          await _generateTransactionCode(amount);
                                        } else {
                                          await _depositMoney(amount);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 10.0.h, horizontal: 16.0.w),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                ),
                                child: Text(
                                  transactionCode == null ? 'Tạo mã QR' : 'Nạp tiền',
                                  style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.0.h),
                            Text(
                              'Rút tiền về ngân hàng',
                              style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.grey),
                            ),
                            SizedBox(height: 8.0.h),
                            TextField(
                              controller: withdrawController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Số tiền rút (VNĐ)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                prefixIcon: Icon(Icons.money_off, size: 20.0.sp),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14.0.sp),
                            ),
                            SizedBox(height: 8.0.h),
                            TextField(
                              controller: bankController,
                              decoration: InputDecoration(
                                labelText: 'Thông tin ngân hàng',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                prefixIcon: Icon(Icons.account_balance, size: 20.0.sp),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14.0.sp),
                            ),
                            SizedBox(height: 8.0.h),
                            ZoomIn(
                              child: ElevatedButton(
                                onPressed: () => _showFlushbar('Chức năng rút tiền chưa được hỗ trợ', Colors.red),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: EdgeInsets.symmetric(vertical: 10.0.h, horizontal: 16.0.w),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                ),
                                child: Text(
                                  'Rút tiền',
                                  style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0.h),
                Text(
                  'Thông báo',
                  style: GoogleFonts.poppins(
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.0.h),
                FadeInUp(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                    child: Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: notifications.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có thông báo',
                                style: GoogleFonts.poppins(fontSize: 16.0.sp),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return ListTile(
                                  leading: Icon(
                                    Icons.notifications,
                                    color: notification.isRead ? Colors.grey : Colors.blue,
                                    size: 20.0.sp,
                                  ),
                                  title: Text(
                                    notification.message,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.0.sp,
                                      color: notification.isRead ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    notification.createdAt != null
                                        ? DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt!.toLocal())
                                        : 'Không rõ',
                                    style: GoogleFonts.poppins(fontSize: 12.0.sp, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    if (!notification.isRead) {
                                      _markNotificationAsRead(notification.id);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0.h),
                Text(
                  'Lịch sử giao dịch',
                  style: GoogleFonts.poppins(
                    fontSize: 18.0.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.0.h),
                FadeInUp(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0.r)),
                    child: Padding(
                      padding: EdgeInsets.all(16.0.w),
                      child: transactions.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có giao dịch nào',
                                style: GoogleFonts.poppins(fontSize: 16.0.sp),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = transactions[index];
                                return ListTile(
                                  leading: Icon(
                                    transaction.type == 'deposit' ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: transaction.type == 'deposit' ? Colors.green : Colors.red,
                                    size: 20.0.sp,
                                  ),
                                  title: Text(
                                    '${transaction.type == 'deposit' ? 'Nạp tiền' : 'Rút tiền'}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(transaction.amount)}',
                                    style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                  ),
                                  subtitle: Text(
                                    transaction.createdAt != null
                                        ? DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt!.toLocal())
                                        : 'Không rõ',
                                    style: GoogleFonts.poppins(fontSize: 12.0.sp, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}