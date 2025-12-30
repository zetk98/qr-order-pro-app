import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; // Để kiểm tra môi trường Web

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final ImagePicker _picker = ImagePicker();
  final String _imgBBKey = "14b359ef2df7fed69941536be9c78f7f";

  // Hàm upload sửa lại để tương thích cả Web và Mobile
  Future<String?> _uploadToImgBB(XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBBKey')
      );

      // QUAN TRỌNG: Trên Web phải dùng fromBytes thay vì fromPath
      if (kIsWeb) {
        var bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['data']['url'];
      }
    } catch (e) {
      debugPrint("Lỗi Up ảnh ImgBB: $e");
    }
    return null;
  }

  Future<void> _handleProduct(BuildContext context, {DocumentSnapshot? doc}) async {
    final n = TextEditingController(text: doc != null ? doc['name'] : "");
    final p = TextEditingController(text: doc != null ? doc['price'].toString() : "");
    final ing = TextEditingController(text: doc != null ? doc['ingredients'] : "");
    String imageUrl = doc != null ? doc['image'] : "";
    bool isUploading = false;

    // Sử dụng context của Dialog để tránh lỗi context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(doc == null ? "Thêm món mới" : "Sửa món ăn"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery, 
                      imageQuality: 60
                    );
                    if (image != null) {
                      setDialogState(() => isUploading = true);
                      String? uploadedUrl = await _uploadToImgBB(image);
                      setDialogState(() {
                        if (uploadedUrl != null) imageUrl = uploadedUrl;
                        isUploading = false;
                      });
                    }
                  },
                  child: Container(
                    height: 150, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200], 
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: isUploading 
                      ? const Center(child: CircularProgressIndicator())
                      : (imageUrl.isNotEmpty 
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(imageUrl, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                Text("Chọn ảnh món ăn", style: TextStyle(color: Colors.grey)),
                              ],
                            )),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(controller: n, decoration: const InputDecoration(labelText: "Tên món", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: p, decoration: const InputDecoration(labelText: "Giá (đ)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: ing, decoration: const InputDecoration(labelText: "Nguyên liệu/Mô tả", border: OutlineInputBorder()), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("HỦY")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: (isUploading || imageUrl.isEmpty) ? null : () async {
                // Kiểm tra dữ liệu đầu vào
                if (n.text.isEmpty || p.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên và giá!")));
                  return;
                }

                var data = {
                  'name': n.text, 
                  'price': int.parse(p.text), 
                  'ingredients': ing.text, 
                  'image': imageUrl
                };

                try {
                  if (doc == null) {
                    await FirebaseFirestore.instance.collection('products').add(data);
                  } else {
                    await doc.reference.update(data);
                  }
                  if (context.mounted) Navigator.pop(dialogContext);
                } catch (e) {
                  debugPrint("Lỗi lưu Firestore: $e");
                }
              },
              child: const Text("LƯU", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleProduct(context), 
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Đã xảy ra lỗi!"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Chưa có món nào. Hãy thêm món mới!"));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var d = docs[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      d['image'], 
                      width: 50, height: 50, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                    ),
                  ),
                  title: Text(d['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${d['price']}đ"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _handleProduct(context, doc: d)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Xác nhận"),
                            content: const Text("Bạn có chắc muốn xóa món này không?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
                              TextButton(onPressed: () {
                                d.reference.delete();
                                Navigator.pop(ctx);
                              }, child: const Text("Xóa", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      }),
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