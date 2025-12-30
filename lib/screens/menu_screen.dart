import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuScreen extends StatefulWidget {
  final String name, table;
  const MenuScreen({super.key, required this.name, required this.table});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, Map<String, dynamic>> cart = {};
  
  final Color coffeeDark = const Color(0xFF4E342E); 
  final Color coffeePrimary = const Color(0xFF6F4E37); 
  final Color coffeeLight = const Color(0xFFD7CCC8); 

  void addToCart(String id, String name, int price, String note) {
    String key = "${id}_${note.trim()}";
    setState(() {
      if (cart.containsKey(key)) {
        cart[key]!['qty']++;
      } else {
        cart[key] = {'id': id, 'name': name, 'price': price, 'qty': 1, 'note': note.trim()};
      }
    });
  }

  void removeFromCart(String key) {
    setState(() {
      if (cart[key]!['qty'] > 1) {
        cart[key]!['qty']--;
      } else {
        cart.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalAmount = cart.values.fold(0, (sum, item) => sum + (item['price'] as int) * (item['qty'] as int));

    return Scaffold(
      backgroundColor: Colors.brown[50], 
      appBar: AppBar(
        title: Text("Bàn ${widget.table} - Chào ${widget.name}", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)), 
        backgroundColor: coffeePrimary,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: coffeePrimary));
                
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 0.68, // Chỉnh lại tỉ lệ để đủ chỗ cho nguyên liệu
                    crossAxisSpacing: 12, 
                    mainAxisSpacing: 12
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var d = snapshot.data!.docs[index];
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Image.network(
                                d['image'],
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(color: coffeeLight, child: Icon(Icons.coffee, color: coffeePrimary)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['name'], 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: coffeeDark),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                
                                // --- DÒNG NGUYÊN LIỆU ĐÃ QUAY TRỞ LẠI ---
                                const SizedBox(height: 2),
                                Text(
                                  d['ingredients'] ?? "", 
                                  style: TextStyle(fontSize: 11, color: Colors.brown[300], fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("${d['price']}đ", 
                                      style: TextStyle(color: coffeePrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                                    GestureDetector(
                                      onTap: () {
                                        TextEditingController nc = TextEditingController();
                                        showDialog(context: context, builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          title: const Text("Ghi chú món ăn"),
                                          content: TextField(controller: nc, decoration: const InputDecoration(hintText: "Ít đá, không đường...")),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: coffeePrimary),
                                              onPressed: () {
                                                addToCart(d.id, d['name'], d['price'], nc.text);
                                                Navigator.pop(ctx);
                                              }, 
                                              child: const Text("THÊM", style: TextStyle(color: Colors.white))
                                            )
                                          ],
                                        ));
                                      },
                                      child: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: coffeePrimary,
                                        child: const Icon(Icons.add, size: 18, color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // --- GIỎ HÀNG ---
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...cart.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value['name'], style: TextStyle(fontWeight: FontWeight.bold, color: coffeeDark)),
                              if (e.value['note'].isNotEmpty)
                                Text(e.value['note'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => removeFromCart(e.key)),
                            Text("${e.value['qty']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(icon: Icon(Icons.add_circle_outline, color: coffeePrimary), onPressed: () => addToCart(e.value['id'], e.value['name'], e.value['price'], e.value['note'])),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                  const Divider(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: coffeePrimary, 
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () async {
                      List itemsList = cart.values.map((e) => "${e['name']} x${e['qty']} ${e['note'].isNotEmpty ? '(' + e['note'] + ')' : ''}").toList();
                      await FirebaseFirestore.instance.collection('orders').add({
                        'customer': widget.name,
                        'table': widget.table,
                        'items': itemsList,
                        'total': totalAmount,
                        'status': 'Mới',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      setState(() => cart.clear());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("☕ Đã gửi đơn hàng!")));
                    },
                    child: Text("ĐẶT MÓN - $totalAmountđ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}