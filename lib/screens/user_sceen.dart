import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shop_frontend/screens/TKBank/WalletScreen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:intl/intl.dart';
import 'package:shop_frontend/screens/Crud_admin/AddProductPage.dart';
import 'package:shop_frontend/screens/Crud_admin/ProductListPage.dart';
import 'package:shop_frontend/screens/Listuser/UserListPage.dart';
import 'package:shop_frontend/screens/OrderHistory_screen.dart';
import 'package:shop_frontend/screens/OrderStatusScreen.dart';
import 'package:shop_frontend/screens/admin_order_management_screen.dart';
import 'package:shop_frontend/screens/discount_management_screen.dart';
import 'package:shop_frontend/services/token_utils.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic> user = {};
  int deliveredOrders = 0;
  double totalSpent = 0.0;
  bool isLoading = true;
  String errorMessage = "";
  String? authToken;
  late IO.Socket socket;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _initSocket();
    _fetchNotifications();
  }

  void _initSocket() {
    socket = IO.io('https://shop-backend-nodejs.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      if (kDebugMode) debugPrint('📡 Connected to socket');
      socket.emit('join', user['role'] == 'admin' ? 'admin' : TokenUtils.getUserIdFromToken(authToken ?? ''));
    });

    socket.on('notification', (data) {
      if (mounted) {
        setState(() {
          notifications.insert(0, data);
        });
      }
    });

    socket.on('connect_error', (_) {
      if (kDebugMode) debugPrint('🔥 Socket connection error');
    });

    socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('📡 Disconnected from socket');
    });
  }

  Future<void> _fetchNotifications() async {
    if (!mounted || authToken == null || authToken!.isEmpty) return;

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .get(
              Uri.parse("https://shop-backend-nodejs.onrender.com/api/notifications"),
              headers: {'Authorization': 'Bearer $authToken'},
            )
            .timeout(const Duration(seconds: timeoutSeconds));

        if (kDebugMode) debugPrint('📡 Fetch notifications response: ${response.statusCode}, attempt ${attempt + 1}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              notifications = data;
            });
          }
          client.close();
          return;
        } else {
          attempt++;
          if (attempt >= maxRetries && mounted) {
            _showFlushbar('Lỗi khi lấy thông báo', Colors.red);
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error fetching notifications (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt >= maxRetries && mounted) {
          _showFlushbar('Lỗi kết nối khi lấy thông báo', Colors.red);
        }
      } finally {
        client.close();
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _getUserInfo() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken') ?? '';

    if (authToken!.isEmpty) {
      if (mounted) {
        setState(() {
          errorMessage = "Bạn cần đăng nhập để xem thông tin tài khoản";
          isLoading = false;
        });
        _showFlushbar(errorMessage, Colors.red);
      }
      return;
    }

    // Load cached data
    final cachedUser = prefs.getString('user_info');
    final cachedOrders = prefs.getString('order_history');
    if (cachedUser != null && cachedOrders != null) {
      try {
        final userData = jsonDecode(cachedUser);
        final ordersData = jsonDecode(cachedOrders);
        if (mounted) {
          setState(() {
            user = userData;
            deliveredOrders = ordersData.where((o) => o['status'] == 'delivered').length;
            totalSpent = ordersData
                .where((o) => o['status'] == 'delivered')
                .fold(0.0, (sum, o) => sum + (o['totalPrice']?.toDouble() ?? 0.0));
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded user info and ${ordersData.length} orders from cache');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error decoding cached data: $e');
      }
    }

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        // Sync membership
        final syncResponse = await client
            .post(
              Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/sync-membership"),
              headers: {'Authorization': 'Bearer $authToken'},
            )
            .timeout(const Duration(seconds: timeoutSeconds));

        if (kDebugMode) debugPrint('📡 Sync membership response: ${syncResponse.statusCode}, attempt ${attempt + 1}');
        if (syncResponse.statusCode != 200) {
          if (kDebugMode) debugPrint('⚠️ Sync membership failed: ${syncResponse.statusCode}');
        }

        // Get user info
        final userResponse = await client
            .get(
              Uri.parse("https://shop-backend-nodejs.onrender.com/api/users/me"),
              headers: {'Authorization': 'Bearer $authToken'},
            )
            .timeout(const Duration(seconds: timeoutSeconds));

        if (kDebugMode) debugPrint('📡 User info response: ${userResponse.statusCode}, attempt ${attempt + 1}');

        if (userResponse.statusCode != 200) {
          if (mounted) {
            setState(() {
              errorMessage = "Không thể lấy thông tin người dùng";
              isLoading = false;
            });
            _showFlushbar(errorMessage, Colors.red);
          }
          client.close();
          return;
        }

        // Get order history
        final ordersResponse = await client
            .get(
              Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/history"),
              headers: {'Authorization': 'Bearer $authToken'},
            )
            .timeout(const Duration(seconds: timeoutSeconds));

        if (kDebugMode) debugPrint('📡 Order history response: ${ordersResponse.statusCode}, attempt ${attempt + 1}');

        await prefs.setString('user_info', userResponse.body);
        await prefs.setString('order_history', ordersResponse.body);

        if (mounted) {
          setState(() {
            user = jsonDecode(userResponse.body);
            if (ordersResponse.statusCode == 200) {
              final orders = jsonDecode(ordersResponse.body);
              deliveredOrders = orders.where((o) => o['status'] == 'delivered').length;
              totalSpent = orders
                  .where((o) => o['status'] == 'delivered')
                  .fold(0.0, (sum, o) => sum + (o['totalPrice']?.toDouble() ?? 0.0));
            } else {
              errorMessage = "Không thể lấy lịch sử đơn hàng";
              _showFlushbar(errorMessage, Colors.red);
            }
            isLoading = false;
          });
        }
        client.close();
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error fetching user info (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt >= maxRetries) {
          if (mounted) {
            setState(() {
              errorMessage = "Lỗi kết nối đến server";
              isLoading = false;
            });
            _showFlushbar(errorMessage, Colors.red);
          }
          client.close();
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  bool _isAdmin() {
    return user['role'] == 'admin';
  }

  void _navigateToUserList() {
    _isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListPage()))
        : _showAccessDenied();
  }

  void _navigateToAddProduct() {
    _isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductPage()))
        : _showAccessDenied();
  }

  void _navigateToProductList() {
    _isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListPage()))
        : _showAccessDenied();
  }

  void _navigateToOrderManagement() {
    if (_isAdmin()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminOrderManagementScreen(authToken: authToken!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderHistoryScreen(
            onDeliveryConfirmed: _getUserInfo,
          ),
        ),
      );
    }
  }

  void _navigateToOrderStatusScreen() {
    if (authToken == null || authToken!.isEmpty) {
      _showFlushbar("Bạn cần đăng nhập để xem trạng thái đơn hàng", Colors.red);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(authToken: authToken!),
      ),
    );
  }

  void _navigateToDiscountManagement() {
    _isAdmin()
        ? Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscountManagementScreen()))
        : _showAccessDenied();
  }

  void _navigateToOrderStatus() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(
          onDeliveryConfirmed: _getUserInfo,
        ),
      ),
    );
  }

  void _navigateToReturnPolicy() {
    Navigator.pushNamed(context, '/return-policy');
  }

  void _navigateToWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  void _showAccessDenied() {
    _showFlushbar("Bạn không có quyền truy cập", Colors.red);
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

  Widget _buildMembershipConditionsTable() {
    const conditions = [
      {'tier': 'Member', 'orders': 0, 'spent': 0.0, 'discount': 0},
      {'tier': 'Silver', 'orders': 10, 'spent': 80000.0, 'discount': 5},
      {'tier': 'Gold', 'orders': 20, 'spent': 160000.0, 'discount': 10},
      {'tier': 'Diamond', 'orders': 30, 'spent': 240000.0, 'discount': 15},
    ];

    return FadeIn(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điều kiện nâng cấp thứ hạng',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 10.w,
                  headingRowHeight: 30.h,
                  dataRowHeight: 28.h,
                  columns: [
                    DataColumn(
                      label: Text(
                        'Cấp bậc',
                        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Đơn hoàn thành',
                        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tổng chi tiêu',
                        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Giảm giá',
                        style: GoogleFonts.poppins(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: conditions.map((condition) {
                    return DataRow(cells: [
                      DataCell(Text(condition['tier'] as String, style: GoogleFonts.poppins(fontSize: 13.sp))),
                      DataCell(Text('${condition['orders']}', style: GoogleFonts.poppins(fontSize: 13.sp))),
                      DataCell(Text('${(condition['spent'] as double).toStringAsFixed(0)} đ', style: GoogleFonts.poppins(fontSize: 13.sp))),
                      DataCell(Text('${condition['discount']} %', style: GoogleFonts.poppins(fontSize: 13.sp))),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipCard() {
    final tier = user['membershipTier'] ?? 'Member';
    final tierStyles = {
      'Member': {'color': Colors.grey, 'icon': Icons.person},
      'Silver': {'color': Colors.blueGrey, 'icon': Icons.star_border},
      'Gold': {'color': Colors.amber, 'icon': Icons.star},
      'Diamond': {'color': Colors.blue, 'icon': Icons.diamond},
    };

    final style = tierStyles[tier]!;
    const conditions = {
      'Member': {'orders': 10, 'spent': 80000.0, 'name': 'Silver'},
      'Silver': {'orders': 20, 'spent': 160000.0, 'name': 'Gold'},
      'Gold': {'orders': 30, 'spent': 240000.0, 'name': 'Diamond'},
      'Diamond': null,
    };

    final nextTier = conditions[tier];
    final isEligibleForNextTier = nextTier != null &&
        deliveredOrders >= (nextTier['orders'] as int) &&
        totalSpent >= (nextTier['spent'] as double);

    return FadeIn(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade100, Colors.amber.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      style['icon'] as IconData,
                      color: style['color'] as Color,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Thứ hạng: $tier',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: style['color'] as Color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Đơn hoàn thành: $deliveredOrders',
                  style: GoogleFonts.poppins(fontSize: 14.sp),
                ),
                Text(
                  'Tổng chi tiêu: ${totalSpent.toStringAsFixed(0)} đ',
                  style: GoogleFonts.poppins(fontSize: 14.sp),
                ),
                if (nextTier != null && !isEligibleForNextTier) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Cần thêm ${(nextTier['orders'] as int) - deliveredOrders} đơn và '
                    '${((nextTier['spent'] as double) - totalSpent).toStringAsFixed(0)} đ để lên ${nextTier['name']}',
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.green),
                  ),
                ],
                if (isEligibleForNextTier) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Đủ điều kiện lên ${nextTier['name']}! Vui lòng làm mới.',
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.green),
                  ),
                ],
                SizedBox(height: 8.h),
                ZoomIn(
                  child: ElevatedButton(
                    onPressed: _getUserInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text(
                      'Làm mới',
                      style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            '👤 Tài khoản',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_balance_wallet, size: 24.sp),
            onPressed: _navigateToWallet,
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, size: 24.sp),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thông báo',
                            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, size: 20.sp),
                            onPressed: _fetchNotifications,
                          ),
                        ],
                      ),
                      content: notifications.isEmpty
                          ? Text(
                              'Chưa có thông báo',
                              style: GoogleFonts.poppins(fontSize: 14.sp),
                            )
                          : SizedBox(
                              width: double.maxFinite,
                              height: 400.h,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = notifications[index];
                                  final isRead = notification['isRead'] ?? false;
                                  return FadeIn(
                                    delay: Duration(milliseconds: index * 100),
                                    child: ListTile(
                                      leading: Icon(
                                        isRead ? Icons.check_circle : Icons.notifications_active,
                                        color: isRead ? Colors.green : Colors.red,
                                        size: 20.sp,
                                      ),
                                      title: Text(
                                        notification['message'] ?? 'Không rõ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.sp,
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        notification['createdAt'] != null
                                            ? DateFormat('dd/MM/yyyy HH:mm')
                                                .format(DateTime.parse(notification['createdAt']).toLocal())
                                            : 'Không rõ',
                                        style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey),
                                      ),
                                      onTap: () async {
                                        if (!isRead) {
                                          const maxRetries = 3;
                                          int attempt = 0;
                                          const timeoutSeconds = 5;
                                          while (attempt < maxRetries) {
                                            final client = http.Client();
                                            try {
                                              final response = await client
                                                  .put(
                                                    Uri.parse(
                                                        "https://shop-backend-nodejs.onrender.com/api/notifications/${notification['_id']}/read"),
                                                    headers: {"Authorization": "Bearer $authToken"},
                                                  )
                                                  .timeout(const Duration(seconds: timeoutSeconds));
                                              if (kDebugMode) {
                                                debugPrint(
                                                    '📡 Mark notification response: ${response.statusCode}, attempt ${attempt + 1}');
                                              }
                                              if (response.statusCode == 200 && mounted) {
                                                setState(() {
                                                  notification['isRead'] = true;
                                                });
                                                if (kDebugMode) {
                                                  debugPrint('📡 Notification marked as read: ${notification['_id']}');
                                                }
                                              } else {
                                                attempt++;
                                                if (attempt >= maxRetries && mounted) {
                                                  _showFlushbar('Lỗi khi đánh dấu thông báo', Colors.red);
                                                }
                                              }
                                              client.close();
                                              break;
                                            } catch (e) {
                                              if (kDebugMode) {
                                                debugPrint('🔥 Error marking notification (attempt ${attempt + 1}): $e');
                                              }
                                              attempt++;
                                              if (attempt >= maxRetries && mounted) {
                                                _showFlushbar('Lỗi kết nối khi đánh dấu thông báo', Colors.red);
                                              }
                                              client.close();
                                            }
                                            await Future.delayed(const Duration(seconds: 2));
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Đóng',
                            style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (notifications.any((n) => !n['isRead']))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.h,
                    ),
                    child: Text(
                      "${notifications.where((n) => !n['isRead']).length}",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getUserInfo();
          await _fetchNotifications();
        },
        color: Colors.orange,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user['avatar'] != null)
                          Center(
                            child: FadeInDown(
                              child: CircleAvatar(
                                radius: 50.r,
                                backgroundImage: NetworkImage(user['avatar']),
                                backgroundColor: Colors.grey[200],
                                onBackgroundImageError: (_, __) => Icon(Icons.error, size: 30.sp),
                              ),
                            ),
                          ),
                        SizedBox(height: 20.h),
                        _buildMembershipConditionsTable(),
                        SizedBox(height: 10.h),
                        _buildMembershipCard(),
                        SizedBox(height: 20.h),
                        FadeInUp(
                          child: _buildInfoRow("Tên", user['name']),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildInfoRow("Email", user['email']),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildInfoRow("Số điện thoại", user['phone']),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: _buildInfoRow("Địa chỉ", user['address']),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: _buildInfoRow("Vai trò", user['role']),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 500),
                          child: _buildInfoRow("Ngày tạo", _formatDate(user['createdAt'])),
                        ),
                        SizedBox(height: 30.h),
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          child: _buildButton("Quản lý đơn hàng", _navigateToOrderManagement, key: const Key('orderManagementButton')),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 650),
                          child: _buildButton("Trạng thái đơn hàng", _navigateToOrderStatusScreen, key: const Key('orderStatusButton')),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: _buildButton("Lịch sử đơn hàng", _navigateToOrderStatus, key: const Key('orderHistoryButton')),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 800),
                          child: _buildButton("Chính sách trả hàng", _navigateToReturnPolicy, key: const Key('returnPolicyButton')),
                        ),
                        if (_isAdmin()) ...[
                          FadeInUp(
                            delay: const Duration(milliseconds: 900),
                            child: _buildAdminButton("Thêm sản phẩm", _navigateToAddProduct, key: const Key('addProductButton')),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 1000),
                            child: _buildAdminButton("Quản lý sản phẩm", _navigateToProductList, key: const Key('productListButton')),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 1100),
                            child: _buildAdminButton("Quản lý người dùng", _navigateToUserList, key: const Key('userListButton')),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 1200),
                            child: _buildAdminButton("Quản lý mã giảm giá", _navigateToDiscountManagement, key: const Key('discountManagementButton')),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$title:",
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value ?? "Chưa cập nhật",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return "Không xác định";
    final date = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Widget _buildButton(String title, VoidCallback onPressed, {Key? key}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: key,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 4,
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(String title, VoidCallback onPressed, {Key? key}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          key: key,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 4,
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}