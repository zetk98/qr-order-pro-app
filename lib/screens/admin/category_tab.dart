import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  final Color coffeePrimary = const Color(0xFF6F4E37);

  // Hàm cập nhật trạng thái isSelling của tất cả sản phẩm theo cateID
  Future<void> _syncProductsStatus(String cateID, bool status) async {
    final productsRef = FirebaseFirestore.instance.collection('products');
    final query = await productsRef.where('cateID', isEqualTo: cateID).get();
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isSelling': status});
    }
    await batch.commit();
  }

  void _showDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final data = doc?.data() as Map<String, dynamic>?;
    final controller = TextEditingController(text: data?['namecate'] ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? "Thêm danh mục" : "Sửa danh mục"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Tên loại")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: coffeePrimary),
            onPressed: () async {
              if (controller.text.isEmpty) return;
              if (doc == null) {
                await FirebaseFirestore.instance.collection('categories').add({
                  'namecate': controller.text,
                  'isVisible': true
                });
              } else {
                await doc.reference.update({'namecate': controller.text});
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("LƯU", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: coffeePrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showDialog(context),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final d = snapshot.data!.docs[index];
              final data = d.data() as Map<String, dynamic>;
              final bool isVisible = data['isVisible'] ?? true;

              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isVisible ? coffeePrimary.withOpacity(0.2) : Colors.grey),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: ListTile(
                  title: Text(data['namecate'], style: TextStyle(fontWeight: FontWeight.bold, color: isVisible ? Colors.black : Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isVisible,
                        activeColor: coffeePrimary,
                        onChanged: (val) async {
                          await d.reference.update({'isVisible': val});
                          await _syncProductsStatus(d.id, val); // Bật -> Bật hết món, Tắt -> Tắt hết món
                        },
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showDialog(context, doc: d)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => d.reference.delete()),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}