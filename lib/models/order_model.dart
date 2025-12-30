import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String customerName;
  final String tableNum;
  final List<Map<String, dynamic>> items;
  final int totalPrice;
  final String status; // pending, processing, completed, cancelled
  final DateTime createdAt;

  OrderModel({
    this.id,
    required this.customerName,
    required this.tableNum,
    required this.items,
    required this.totalPrice,
    this.status = 'pending',
    required this.createdAt,
  });

  // Chuyển từ Object sang Map để gửi lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'tableNum': tableNum,
      'items': items,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(), // Sử dụng thời gian server
    };
  }
}