class Product {
  final String id;
  final String name;
  final int price;
  final String image;
  final String ingredients; // Thêm dòng này

  Product({
    required this.id, 
    required this.name, 
    required this.price, 
    required this.image,
    required this.ingredients // Thêm dòng này
  });

  Map<String, dynamic> toMap() => {
    'name': name, 
    'price': price, 
    'image': image,
    'ingredients': ingredients // Thêm dòng này
  };
}