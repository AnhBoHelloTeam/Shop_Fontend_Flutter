import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DiscountManagementScreen extends StatefulWidget {
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
    fetchDiscounts();
  }

  Future<void> fetchDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Vui lòng đăng nhập';
        });
        return;
      }

      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        setState(() {
          discounts = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['message'] ?? 'Không thể lấy danh sách mã giảm giá';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Lỗi kết nối đến server: $error';
        isLoading = false;
      });
    }
  }

  Future<void> createDiscount() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final response = await http.post(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json"
        },
        body: json.encode({
          "code": _codeController.text.trim(),
          "description": _descriptionController.text.trim(),
          "percentage": int.parse(_percentageController.text),
          "minOrderValue": int.parse(_minOrderValueController.text),
          "maxDiscount": int.parse(_maxDiscountController.text),
          "minDiscount": int.parse(_minDiscountController.text),
          "startDate": _selectedStartDate?.toIso8601String(),
          "endDate": _selectedEndDate?.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Tạo mã giảm giá thành công'), backgroundColor: Colors.green),
        );
        fetchDiscounts();
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json.decode(response.body)['message'] ?? 'Không thể tạo mã giảm giá'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi server: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> deleteDiscount(String discountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final response = await http.delete(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts/$discountId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Xóa mã giảm giá thành công'), backgroundColor: Colors.green),
        );
        fetchDiscounts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json.decode(response.body)['message'] ?? 'Không thể xóa mã giảm giá'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi server: $error'), backgroundColor: Colors.red),
      );
    }
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: isDate,
        onTap: isDate ? () => _selectDate(context, label.contains('bắt đầu')) : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: isDate ? Icon(Icons.calendar_today) : null,
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
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý mã giảm giá', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(fontSize: 16.sp)))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tạo mã giảm giá mới',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: createDiscount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                ),
                                child: Text('Tạo mã', style: TextStyle(fontSize: 16.sp)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Danh sách mã giảm giá',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      discounts.isEmpty
                          ? Center(child: Text('Chưa có mã giảm giá nào', style: TextStyle(fontSize: 16.sp)))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: discounts.length,
                              itemBuilder: (context, index) {
                                final discount = discounts[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  child: ListTile(
                                    title: Text(discount['code'], style: TextStyle(fontSize: 16.sp)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Giảm: ${discount['percentage']}%', style: TextStyle(fontSize: 14.sp)),
                                        Text(
                                          'Đơn tối thiểu: ${discount['minOrderValue']} đ',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                        Text(
                                          'Hiệu lực: ${DateTime.parse(discount['startDate']).toLocal().toString().substring(0, 10)} - ${DateTime.parse(discount['endDate']).toLocal().toString().substring(0, 10)}',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                                      onPressed: () => deleteDiscount(discount['_id']),
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