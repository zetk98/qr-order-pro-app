import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  String id;
  String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return CategoryModel(
      id: snap.id,
      name: data['name'] ?? "Không tên", // Tránh lỗi Bad State
    );
  }
}