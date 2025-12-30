class Product {
  final String id;
  final String name;
  final int price;
  final String image;
  final String ingredients;
  final String cateID;   // ID danh mục để lọc
  final bool isSelling; // Trạng thái còn món/hết món

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.ingredients,
    required this.cateID,
    this.isSelling = true, // Mặc định là đang bán
  });

  // Chuyển từ Firestore Document sang Object Product
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toInt(),
      image: data['image'] ?? '',
      ingredients: data['ingredients'] ?? '',
      cateID: data['cateID'] ?? '',
      isSelling: data['isSelling'] ?? true,
    );
  }

  // Chuyển từ Object sang Map để lưu/cập nhật Firestore
  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'image': image,
    'ingredients': ingredients,
    'cateID': cateID,
    'isSelling': isSelling,
  };
}