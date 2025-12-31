import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart'; // Import model mới

class MenuScreen extends StatefulWidget {
  final String name, table;
  const MenuScreen({super.key, required this.name, required this.table});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, Map<String, dynamic>> cart = {};
  String selectedCateID = "Tất cả";
  final Color coffeePrimary = const Color(0xFF6F4E37);

  // --- HÀM GỬI ĐƠN SỬ DỤNG MODEL ---
  Future<void> _submitOrder() async {
    if (cart.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      int total = cart.values.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int));
      
      // Tạo đối tượng Order từ Model
      OrderModel newOrder = OrderModel(
        customerName: widget.name,
        tableNum: widget.table,
        items: cart.values.toList(),
        totalPrice: total,
        createdAt: DateTime.now(),
      );

      // Gửi lên Firestore
      await FirebaseFirestore.instance.collection('orders').add(newOrder.toMap());

      if (mounted) Navigator.pop(context); // Đóng loading

      setState(() => cart.clear());

      if (mounted) {
        Navigator.pop(context); // Đóng BottomSheet
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Lỗi Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Đơn hàng đã được gửi đến nhà bếp!", textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  // --- CÁC HÀM UI GIỮ NGUYÊN NHƯ TRƯỚC ---
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
  }

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
                                child: Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.coffee)),
                              ),
                              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${item['price']}đ x ${item['qty']} ${item['note'] != "" ? '\nNote: ${item['note']}' : ''}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    if (cart[key]!['qty'] > 1) cart[key]!['qty']--;
                                    else cart.remove(key);
                                  });
                                  setSheetState(() {});
                                  if (cart.isEmpty) Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tổng cộng:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("$totalđ", style: TextStyle(fontSize: 22, color: coffeePrimary, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: coffeePrimary, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: cart.isEmpty ? null : _submitOrder,
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
    int totalQty = cart.values.fold(0, (sum, item) => sum + (item['qty'] as int));
    int totalAmount = cart.values.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Bàn ${widget.table} - ${widget.name}", style: const TextStyle(color: Colors.white)),
        backgroundColor: coffeePrimary,
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
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
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
              bottom: 20, left: 15, right: 15,
              child: GestureDetector(
                onTap: _showCartDetails,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: coffeePrimary, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                  child: Row(
                    children: [
                      Badge(label: Text("$totalQty")),
                      const SizedBox(width: 15),
                      const Expanded(child: Text("Xem giỏ hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Text("$totalAmountđ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      height: 60, color: Colors.white,
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

  Widget _buildProductCard(Product p) {
    bool isAvailable = p.isSelling;
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: isAvailable ? () => _showNoteDialog(p) : null,
        child: ColorFiltered(
          colorFilter: isAvailable 
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Image.network(p.image, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.coffee, size: 50)))),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          p.ingredients, 
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text("${p.price}đ", style: TextStyle(color: coffeePrimary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
              if (!isAvailable)
                Positioned.fill(child: Container(color: Colors.black12, child: Center(child: Container(padding: const EdgeInsets.all(5), color: Colors.black87, child: const Text("HẾT MÓN", style: TextStyle(color: Colors.white, fontSize: 10)))))),
              Positioned(bottom: 5, right: 5, child: CircleAvatar(radius: 14, backgroundColor: isAvailable ? coffeePrimary : Colors.grey, child: const Icon(Icons.add, color: Colors.white, size: 18))),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(Product p) {
    TextEditingController nc = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Ghi chú: ${p.name}"),
      content: TextField(controller: nc, decoration: const InputDecoration(hintText: "Ít đường, không đá...")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: coffeePrimary), onPressed: () { addToCart(p, nc.text); Navigator.pop(ctx); }, child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.white))),
      ],
    ));
  }
}