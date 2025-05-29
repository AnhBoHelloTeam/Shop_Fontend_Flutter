import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:image_picker/image_picker.dart';

class WalletService {
  static const String _baseUrl = 'https://shop-backend-nodejs.onrender.com';
  late IO.Socket _socket;
  String? _authToken;
  Function(Map<String, dynamic>)? _notificationCallback;

  WalletService() {
    _initSocket();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
  }

  void _initSocket() {
    _socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      if (kDebugMode) debugPrint('📡 Socket connected');
    });

    _socket.on('notification', (data) {
      if (kDebugMode) debugPrint('📢 Notification received: $data');
      _notificationCallback?.call(data);
    });

    _socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('📡 Socket disconnected');
    });
  }

  void joinRoom(String userId, bool isAdmin) {
    _socket.emit('join', userId);
    if (isAdmin) {
      _socket.emit('join', 'admin');
    }
  }

  void onNotification(Function(Map<String, dynamic>) callback) {
    _notificationCallback = callback;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/users/me'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await prefs.setString('user_info', response.body);
        joinRoom(userData['_id'], userData['role'] == 'admin');
        return userData;
      } else {
        throw Exception('Failed to fetch user info: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> getWallet() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/wallet/wallet'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch wallet: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getTransactions() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/wallet/transactions'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch transactions: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getNotifications() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/notifications'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getPendingDeposits() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/wallet/deposit/pending'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch pending deposits: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getAllWallets() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/wallet/wallets'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch wallets: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<void> depositMoney(double amount, String transactionCode, String paymentMethodId) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/api/wallet/deposit'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'amount': amount,
              'transactionCode': transactionCode,
              'paymentMethodId': paymentMethodId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to deposit: $error');
      }
    } finally {
      client.close();
    }
  }

  Future<void> approveDeposit(String requestId) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/api/wallet/deposit/approve/$requestId'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to approve deposit: $error');
      }
    } finally {
      client.close();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .put(
            Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getPaymentMethods() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/wallet/payment-methods'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch payment methods: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<void> addPaymentMethod(String name, String type, String details, String? qrCodeUrl) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/api/wallet/payment-methods'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': name,
              'type': type,
              'details': details,
              'qrCodeUrl': qrCodeUrl,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to add payment method: $error');
      }
    } finally {
      client.close();
    }
  }

  Future<void> addPaymentMethodWithQR(
    String name,
    String type,
    String details,
    XFile qrImage,
  ) async {
    if (_authToken == null) throw Exception('No auth token found');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/wallet/payment-methods/add-qr'),
    );

    request.headers['Authorization'] = 'Bearer $_authToken';

    request.fields['name'] = name;
    request.fields['type'] = type;
    request.fields['details'] = details;

    request.files.add(
      await http.MultipartFile.fromPath(
        'qrCode',
        qrImage.path,
        filename: qrImage.name,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      final error = jsonDecode(responseBody)['error'] ?? 'Unknown error';
      throw Exception('Failed to add payment method with QR: $error');
    }
  }

  Future<String> generateTransactionCode(String userId, double amount, String paymentMethodId) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/api/wallet/transaction-code'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'amount': amount,
              'paymentMethodId': paymentMethodId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['transactionCode'];
      } else {
        throw Exception('Failed to generate transaction code: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> verifyTransaction(String transactionCode) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/api/wallet/verify-transaction'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'transactionCode': transactionCode}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to verify transaction: $error');
      }
    } finally {
      client.close();
    }
  }

  Future<void> adminDeposit(String userId, double amount, String transactionCode, String paymentMethodId) async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$_baseUrl/api/wallet/admin/deposit'),
            headers: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'userId': userId,
              'amount': amount,
              'transactionCode': transactionCode,
              'paymentMethodId': paymentMethodId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to deposit for user: $error');
      }
    } finally {
      client.close();
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    if (_authToken == null) throw Exception('No auth token found');

    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/api/users'),
            headers: {'Authorization': 'Bearer $_authToken'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch users: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  void dispose() {
    _socket.dispose();
  }
}