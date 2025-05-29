class Wallet {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final double? balance;

  Wallet({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id'] ?? '',
      userId: json['userId']['_id'] ?? json['userId'] ?? '',
      userName: json['userId']['name'],
      userEmail: json['userId']['email'],
      balance: json['balance']?.toDouble(),
    );
  }
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String status;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class DepositRequest {
  final String id;
  final String userId;
  final String? userName;
  final double amount;
  final String transactionCode;
  final String status;
  final String? paymentMethodId; // Thêm paymentMethodId
  final DateTime? createdAt;

  DepositRequest({
    required this.id,
    required this.userId,
    this.userName,
    required this.amount,
    required this.transactionCode,
    required this.status,
    this.paymentMethodId,
    this.createdAt,
  });

  factory DepositRequest.fromJson(Map<String, dynamic> json) {
    return DepositRequest(
      id: json['_id'] ?? '',
      userId: json['userId']['_id'] ?? json['userId'] ?? '',
      userName: json['userId']['name'],
      amount: json['amount']?.toDouble() ?? 0.0,
      transactionCode: json['transactionCode'] ?? '',
      status: json['status'] ?? '',
      paymentMethodId: json['paymentMethodId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class NotificationModel {
  final String id;
  final String message;
  bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String type; // 'bank' or 'ewallet'
  final String details; // e.g., bank account number or ewallet ID
  final String? qrCodeUrl; // URL to QR code image (optional)

  PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
    this.qrCodeUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      details: json['details'] ?? '',
      qrCodeUrl: json['qrCodeUrl'],
    );
  }
}