import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:intl/intl.dart';
import 'package:shop_frontend/screens/TKBank/WalletModel.dart';
import 'package:shop_frontend/screens/TKBank/WalletService.dart';
import 'package:image_picker/image_picker.dart';

class AdminWalletView extends StatefulWidget {
  final Map<String, dynamic> user;
  final WalletService walletService;

  const AdminWalletView({super.key, required this.user, required this.walletService});

  @override
  _AdminWalletViewState createState() => _AdminWalletViewState();
}

class _AdminWalletViewState extends State<AdminWalletView> {
  List<DepositRequest> depositRequests = [];
  List<Wallet> wallets = [];
  List<NotificationModel> notifications = [];
  List<PaymentMethod> paymentMethods = [];
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _paymentMethodNameController = TextEditingController();
  final TextEditingController _paymentMethodDetailsController = TextEditingController();
  final TextEditingController _adminDepositAmountController = TextEditingController();
  String? _selectedUserId;
  String? _selectedPaymentMethodType;
  Map<String, dynamic>? _verifiedTransaction;
  XFile? _selectedQRImage;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.walletService.onNotification((data) {
      if (mounted) {
        setState(() {
          notifications.insert(0, NotificationModel.fromJson(data));
        });
        _showFlushbar(data['message'], Colors.blue);
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final depositData = await widget.walletService.getPendingDeposits();
      final walletData = await widget.walletService.getAllWallets();
      final notificationData = await widget.walletService.getNotifications();
      final paymentMethodsData = await widget.walletService.getPaymentMethods();
      final usersData = await widget.walletService.getAllUsers();
      if (mounted) {
        setState(() {
          depositRequests = depositData.map((e) => DepositRequest.fromJson(e)).toList();
          wallets = walletData.map((e) => Wallet.fromJson(e)).toList();
          notifications = notificationData.map((e) => NotificationModel.fromJson(e)).toList();
          paymentMethods = paymentMethodsData.map((e) => PaymentMethod.fromJson(e)).toList();
          users = usersData.cast<Map<String, dynamic>>();
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

  Future<void> _verifyTransaction() async {
    if (_qrCodeController.text.isEmpty) {
      _showFlushbar('Vui lòng nhập mã QR hoặc mã giao dịch', Colors.red);
      return;
    }

    try {
      final transactionData = await widget.walletService.verifyTransaction(_qrCodeController.text);
      if (mounted) {
        setState(() {
          _verifiedTransaction = transactionData;
        });
      }
    } catch (e) {
      _showFlushbar('Lỗi xác minh giao dịch: $e', Colors.red);
    }
  }

  Future<void> _confirmDeposit() async {
    if (_verifiedTransaction == null) {
      _showFlushbar('Vui lòng xác minh giao dịch trước', Colors.red);
      return;
    }

    try {
      await widget.walletService.adminDeposit(
        _verifiedTransaction!['userId'],
        _verifiedTransaction!['amount'].toDouble(),
        _verifiedTransaction!['transactionCode'],
        _verifiedTransaction!['paymentMethodId'],
      );
      _showFlushbar(
        'Nạp tiền thành công cho ${_verifiedTransaction!['userName']}',
        Colors.green,
      );
      if (mounted) {
        setState(() {
          _qrCodeController.clear();
          _verifiedTransaction = null;
        });
      }
      await _loadData();
    } catch (e) {
      _showFlushbar('Lỗi nạp tiền: $e', Colors.red);
    }
  }

  Future<void> _addPaymentMethod() async {
    if (_paymentMethodNameController.text.isEmpty ||
        _paymentMethodDetailsController.text.isEmpty ||
        _selectedPaymentMethodType == null) {
      _showFlushbar('Vui lòng điền đầy đủ thông tin', Colors.red);
      return;
    }

    try {
      await widget.walletService.addPaymentMethod(
        _paymentMethodNameController.text,
        _selectedPaymentMethodType!,
        _paymentMethodDetailsController.text,
        null,
      );
      _showFlushbar('Thêm phương thức thanh toán thành công', Colors.green);
      if (mounted) {
        setState(() {
          _paymentMethodNameController.clear();
          _paymentMethodDetailsController.clear();
          _selectedPaymentMethodType = null;
        });
      }
      await _loadData();
    } catch (e) {
      _showFlushbar('Lỗi thêm phương thức: $e', Colors.red);
    }
  }

  Future<void> _addPaymentMethodWithQR() async {
    if (_paymentMethodNameController.text.isEmpty ||
        _paymentMethodDetailsController.text.isEmpty ||
        _selectedPaymentMethodType == null ||
        _selectedQRImage == null) {
      _showFlushbar('Vui lòng điền đầy đủ thông tin và chọn ảnh QR', Colors.red);
      return;
    }

    try {
      await widget.walletService.addPaymentMethodWithQR(
        _paymentMethodNameController.text,
        _selectedPaymentMethodType!,
        _paymentMethodDetailsController.text,
        _selectedQRImage!,
      );
      _showFlushbar('Thêm phương thức thanh toán với QR thành công', Colors.green);
      if (mounted) {
        setState(() {
          _paymentMethodNameController.clear();
          _paymentMethodDetailsController.clear();
          _selectedPaymentMethodType = null;
          _selectedQRImage = null;
        });
      }
      await _loadData();
    } catch (e) {
      _showFlushbar('Lỗi thêm phương thức với QR: $e', Colors.red);
    }
  }

  Future<void> _pickQRImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedQRImage = pickedFile;
      });
    }
  }

  Future<void> _adminDepositMoney() async {
    if (_selectedUserId == null || _adminDepositAmountController.text.isEmpty) {
      _showFlushbar('Vui lòng chọn người dùng và nhập số tiền', Colors.red);
      return;
    }

    try {
      final amount = double.tryParse(_adminDepositAmountController.text) ?? 0.0;
      if (amount <= 0) {
        _showFlushbar('Số tiền không hợp lệ', Colors.red);
        return;
      }
      final paymentMethodId = paymentMethods.isNotEmpty ? paymentMethods[0].id : '';
      if (paymentMethodId.isEmpty) {
        _showFlushbar('Chưa có phương thức thanh toán', Colors.red);
        return;
      }
      final transactionCode = await widget.walletService.generateTransactionCode(
        _selectedUserId!,
        amount,
        paymentMethodId,
      );
      await widget.walletService.adminDeposit(
        _selectedUserId!,
        amount,
        transactionCode,
        paymentMethodId,
      );
      _showFlushbar('Nạp tiền thành công cho user', Colors.green);
      if (mounted) {
        setState(() {
          _adminDepositAmountController.clear();
          _selectedUserId = null;
        });
      }
      await _loadData();
    } catch (e) {
      _showFlushbar('Lỗi nạp tiền: $e', Colors.red);
    }
  }

  Future<void> _approveDeposit(String requestId) async {
    try {
      await widget.walletService.approveDeposit(requestId);
      _showFlushbar('Duyệt yêu cầu nạp tiền thành công', Colors.green);
      await _loadData();
    } catch (e) {
      _showFlushbar('Lỗi duyệt yêu cầu: $e', Colors.red);
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

  @override
  Widget build(BuildContext context) {
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
                            'Thông tin quản trị viên',
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
                                  Icons.account_balance,
                                  color: Colors.blue,
                                  size: 24.0.sp,
                                ),
                                SizedBox(width: 8.0.w),
                                Text(
                                  'Tổng quan ví',
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
                              'Tổng số dư tất cả ví: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(wallets.fold<double>(0, (sum, w) => sum + (w.balance ?? 0)))}',
                              style: GoogleFonts.poppins(
                                fontSize: 16.0.sp,
                                fontWeight: FontWeight.bold,
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
                  'Thêm phương thức thanh toán',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _paymentMethodNameController,
                            decoration: InputDecoration(
                              labelText: 'Tên phương thức (VD: Vietcombank, MoMo)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                              prefixIcon: Icon(Icons.label, size: 20.0.sp),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14.0.sp),
                          ),
                          SizedBox(height: 8.0.h),
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethodType,
                            items: ['bank', 'ewallet'].map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type == 'bank' ? 'Ngân hàng' : 'Ví điện tử',
                                  style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethodType = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Loại phương thức',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                            ),
                          ),
                          SizedBox(height: 8.0.h),
                          TextField(
                            controller: _paymentMethodDetailsController,
                            decoration: InputDecoration(
                              labelText: 'Chi tiết (VD: Số tài khoản, ID ví)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                              prefixIcon: Icon(Icons.details, size: 20.0.sp),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14.0.sp),
                          ),
                          SizedBox(height: 8.0.h),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _pickQRImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    padding: EdgeInsets.symmetric(vertical: 10.0.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                  ),
                                  child: Text(
                                    _selectedQRImage == null ? 'Chọn ảnh QR' : 'Đã chọn ảnh',
                                    style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.0.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _addPaymentMethodWithQR,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 10.0.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                  ),
                                  child: Text(
                                    'Thêm với QR',
                                    style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0.h),
                          ZoomIn(
                            child: ElevatedButton(
                              onPressed: _addPaymentMethod,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 10.0.h, horizontal: 16.0.w),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                              ),
                              child: Text(
                                'Thêm phương thức',
                                style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0.h),
                Text(
                  'Nạp tiền cho người dùng',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedUserId,
                            items: users.map((user) {
                              return DropdownMenuItem<String>(
                                value: user['_id'],
                                child: Text(
                                  '${user['name']} (${user['email']})',
                                  style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUserId = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Chọn người dùng',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                              prefixIcon: Icon(Icons.person, size: 20.0.sp),
                            ),
                          ),
                          SizedBox(height: 8.0.h),
                          TextField(
                            controller: _adminDepositAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Số tiền nạp (VNĐ)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0.r)),
                              prefixIcon: Icon(Icons.attach_money, size: 20.0.sp),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14.0.sp),
                          ),
                          SizedBox(height: 8.0.h),
                          ZoomIn(
                            child: ElevatedButton(
                              onPressed: _adminDepositMoney,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 10.0.h, horizontal: 16.0.w),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                              ),
                              child: Text(
                                'Nạp tiền',
                                style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
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
                                        ? DateFormat('dd/MM/yyyy HH:mm')
                                            .format(notification.createdAt!.toLocal())
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
                  'Yêu cầu nạp tiền',
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
                      child: depositRequests.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có yêu cầu nạp tiền',
                                style: GoogleFonts.poppins(fontSize: 16.0.sp),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: depositRequests.length,
                              itemBuilder: (context, index) {
                                final request = depositRequests[index];
                                return ListTile(
                                  title: Text(
                                    'Người dùng: ${request.userName ?? 'Unknown'}',
                                    style: GoogleFonts.poppins(fontSize: 14.0.sp),
                                  ),
                                  subtitle: Text(
                                    'Số tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(request.amount)}\nMã giao dịch: ${request.transactionCode}',
                                    style: GoogleFonts.poppins(fontSize: 12.0.sp, color: Colors.grey),
                                  ),
                                  trailing: ZoomIn(
                                    child: ElevatedButton(
                                      onPressed: () => _approveDeposit(request.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(horizontal: 12.0.w, vertical: 8.0.h),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0.r)),
                                      ),
                                      child: Text(
                                        'Duyệt',
                                        style: GoogleFonts.poppins(fontSize: 12.0.sp, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0.h),
                Text(
                  'Danh sách ví người dùng',
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
                      child: wallets.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có dữ liệu ví người dùng',
                                style: GoogleFonts.poppins(fontSize: 16.0.sp),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: wallets.length,
                              itemBuilder: (context, index) {
                                final wallet = wallets[index];
                                return ListTile(
                                  leading: Icon(Icons.person, size: 24.0.sp, color: Colors.blue),
                                  title: Text(
                                    wallet.userName ?? 'Unknown',
                                    style: GoogleFonts.poppins(fontSize: 16.0.sp, fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    'Email: ${wallet.userEmail ?? 'Unknown'}\nSố dư: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(wallet.balance ?? 0)}',
                                    style: GoogleFonts.poppins(fontSize: 14.0.sp, color: Colors.grey),
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