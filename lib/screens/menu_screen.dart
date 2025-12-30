import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class MenuScreen extends StatefulWidget {
  final String name, table;
  const MenuScreen({super.key, required this.name, required this.table});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Quản lý giỏ hàng: { "id_ghi-chu": { dữ liệu món } }
  Map<String, Map<String, dynamic>> cart = {};
  String selectedCateID = "Tất cả";
  final Color coffeePrimary = const Color(0xFF6F4E37);

  // --- LOGIC GIỎ HÀNG ---
  void addToCart(Product p, String note) {
    String key = "${p.id}_${note.trim()}";
    setState(() {
      if (cart.containsKey(key)) {
        cart[key]!['qty']++;
      } else {
        cart[key] = {
          'id': p.id,
          'name': p.name,
          'price': p.price,
          'qty': 1,
          'note': note.trim(),
          'image': p.image
        };
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Đã thêm ${p.name}"), duration: const Duration(seconds: 1)),
    );
  }

  // --- GIAO DIỆN CHI TIẾT GIỎ HÀNG ---
  void _showCartDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          int total = cart.values.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int));

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 15),
                const Text("Chi tiết đơn hàng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: cart.isEmpty
                      ? const Center(child: Text("Giỏ hàng đang trống"))
                      : ListView.builder(
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            String key = cart.keys.elementAt(index);
                            var item = cart[key]!;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['image'], 
                                  width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 50, height: 50, color: Colors.brown[50],
                                    child: Center(child: Icon(Icons.coffee, color: coffeePrimary, size: 24)),
                                  ),
                                ),
                              ),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${item['price']}đ ${item['note'] != "" ? '\nNote: ${item['note']}' : ''}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        if (cart[key]!['qty'] > 1) {
                                          cart[key]!['qty']--;
                                        } else {
                                          cart.remove(key);
                                        }
                                      });
                                      setSheetState(() {});
                                      if (cart.isEmpty) Navigator.pop(context);
                                    },
                                  ),
                                  Text("${item['qty']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () {
                                      setState(() => cart[key]!['qty']++);
                                      setSheetState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng cộng:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("$totalđ", style: TextStyle(fontSize: 22, color: coffeePrimary, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coffeePrimary,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: cart.isEmpty ? null : () {
                    // Logic gửi đơn lên Firebase sẽ viết ở đây
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Đơn hàng đã được gửi!")));
                  },
                  child: const Text("GỬI ĐƠN NGAY", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = cart.values.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int));
    int totalQty = cart.values.fold(0, (sum, item) => sum + (item['qty'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Bàn ${widget.table} - ${widget.name}", style: const TextStyle(color: Colors.white)),
        backgroundColor: coffeePrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildCategoryHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: selectedCateID == "Tất cả"
                      ? FirebaseFirestore.instance.collection('products').snapshots()
                      : FirebaseFirestore.instance.collection('products').where('cateID', isEqualTo: selectedCateID).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var products = snapshot.data!.docs.map((d) => Product.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList();
                    
                    if (products.isEmpty) return const Center(child: Text("Mục này chưa có món"));

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) => _buildProductCard(products[index]),
                    );
                  },
                ),
              ),
            ],
          ),
          if (cart.isNotEmpty)
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.25 : 15,
              right: MediaQuery.of(context).size.width > 600 ? MediaQuery.of(context).size.width * 0.25 : 15,
              child: InkWell(
                onTap: _showCartDetails,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: coffeePrimary,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Badge(
                        label: Text("$totalQty", style: const TextStyle(color: Colors.white)),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(child: Text("Xem giỏ hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Text("$totalAmountđ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Icon(Icons.arrow_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      height: 60,
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          var categories = snapshot.data!.docs;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              String name = (index == 0) ? "Tất cả" : categories[index - 1]['namecate'];
              String id = (index == 0) ? "Tất cả" : categories[index - 1].id;
              bool isSelected = selectedCateID == id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: coffeePrimary,
                  onSelected: (_) => setState(() => selectedCateID = id),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- HÀM TẠO THẺ SẢN PHẨM CHỈNH CHU NHẤT ---
  Widget _buildProductCard(Product p) {
    bool isAvailable = p.isSelling;

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: isAvailable ? () => _showNoteDialog(p) : null,
        child: ColorFiltered(
          // Bôi xám toàn bộ mọi thành phần trong Card nếu hết món
          colorFilter: isAvailable 
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.brown[50],
                      child: Image.network(
                        p.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.coffee, color: coffeePrimary.withOpacity(0.3), size: 50),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
                          maxLines: 1, overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 4),
                        Text("${p.price}đ", 
                          style: TextStyle(color: coffeePrimary, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  )
                ],
              ),
              // Lớp phủ tối khi hết món
              if (!isAvailable)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "HẾT MÓN",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              // Nút thêm món
              Positioned(
                bottom: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isAvailable ? coffeePrimary : Colors.grey[400],
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(Product p) {
    TextEditingController nc = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Ghi chú cho: ${p.name}"),
      content: TextField(controller: nc, decoration: const InputDecoration(hintText: "Ít đường, không đá...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: coffeePrimary),
          onPressed: () { addToCart(p, nc.text); Navigator.pop(ctx); }, 
          child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white))
        ),
      ],
    ));
  }
}