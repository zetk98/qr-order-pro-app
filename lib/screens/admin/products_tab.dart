import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final Color coffeePrimary = const Color(0xFF6F4E37);
  final ImagePicker _picker = ImagePicker();
  static const String IMGBB_API_KEY = "14b359ef2df7fed69941536be9c78f7f";

  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 10;
  String selectedCateID = "Tất cả";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchProducts();
      }
    });
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMore) return;

    setState(() => _isLoading = true);

    if (isRefresh) {
      _products.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    try {
      Query query = FirebaseFirestore.instance.collection('products');
      if (selectedCateID != "Tất cả") {
        query = query.where('cateID', isEqualTo: selectedCateID);
      }
      query = query.orderBy('name').limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _products.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint("Lỗi tải sản phẩm: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CÁC HÀM DIALOG (ĐÃ THÊM ĐỦ) ---

  void _showDeleteConfirm(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có muốn xóa món '$name' không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(id).delete();
              Navigator.pop(ctx);
              _fetchProducts(isRefresh: true);
            },
            child: const Text("XÓA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? "");
    final priceController = TextEditingController(text: product?.price.toString() ?? "");
    final ingredientsController = TextEditingController(text: product?.ingredients ?? "");
    String? currentCateID = product?.cateID;
    String? currentImageUrl = product?.image; 
    Uint8List? webImage; 
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(product == null ? "Thêm món mới" : "Sửa món ăn"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      var bytes = await pickedFile.readAsBytes();
                      setDialogState(() {
                        webImage = bytes;
                        currentImageUrl = null; 
                      });
                    }
                  },
                  child: Container(
                    height: 140, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100], borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: coffeePrimary.withOpacity(0.3)),
                    ),
                    child: webImage != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(webImage!, fit: BoxFit.cover))
                        : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(currentImageUrl!, fit: BoxFit.cover))
                          : Icon(Icons.add_a_photo, size: 40, color: coffeePrimary),
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    return DropdownButtonFormField<String>(
                      value: currentCateID,
                      hint: const Text("Chọn danh mục"),
                      items: snapshot.data!.docs.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c['namecate'] ?? ""));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => currentCateID = val),
                    );
                  },
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên món")),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Giá"), keyboardType: TextInputType.number),
                TextField(controller: ingredientsController, decoration: const InputDecoration(labelText: "Mô tả")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: coffeePrimary),
              onPressed: isUploading ? null : () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty || currentCateID == null) return;
                setDialogState(() => isUploading = true);
                
                String finalImageUrl = currentImageUrl ?? "";
                if (webImage != null) {
                  String? uploadedUrl = await _uploadToImgBB(webImage!);
                  if (uploadedUrl != null) finalImageUrl = uploadedUrl;
                }

                final data = {
                  'name': nameController.text,
                  'price': int.parse(priceController.text),
                  'image': finalImageUrl,
                  'ingredients': ingredientsController.text,
                  'cateID': currentCateID,
                  'isSelling': product?.isSelling ?? true,
                };

                if (product == null) {
                  await FirebaseFirestore.instance.collection('products').add(data);
                } else {
                  await FirebaseFirestore.instance.collection('products').doc(product.id).update(data);
                }
                Navigator.pop(ctx);
                _fetchProducts(isRefresh: true);
              },
              child: Text(isUploading ? "ĐANG LƯU..." : "LƯU", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadToImgBB(Uint8List bytes) async {
    String base64Image = base64Encode(bytes);
    try {
      var response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$IMGBB_API_KEY'),
        body: {'image': base64Image},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['data']['url'];
      }
    } catch (e) { debugPrint("Lỗi upload: $e"); }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: coffeePrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showProductDialog(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildCategoryFilter(),
          const Divider(thickness: 1, height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchProducts(isRefresh: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                  }
                  var doc = _products[index];
                  final p = Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                  return _buildProductItem(p, doc);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 50);
        var categories = snapshot.data!.docs;
        return SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              String name = (index == 0) ? "Tất cả" : categories[index - 1]['namecate'];
              String id = (index == 0) ? "Tất cả" : categories[index - 1].id;
              bool isSelected = selectedCateID == id;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: coffeePrimary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedCateID = id;
                        _fetchProducts(isRefresh: true);
                      });
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductItem(Product p, DocumentSnapshot doc) {
    final bool isVisible = p.isSelling;
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isVisible ? coffeePrimary.withOpacity(0.2) : Colors.grey),
        borderRadius: BorderRadius.circular(10)
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: p.image, width: 55, height: 55, fit: BoxFit.cover,
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
          ),
        ),
        title: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, color: isVisible ? Colors.black : Colors.grey)),
        subtitle: Text("${p.price}đ"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isVisible,
              activeColor: coffeePrimary,
              onChanged: (val) async {
                await doc.reference.update({'isSelling': val});
                // Thay vì gán p.isSelling (lỗi final), ta cập nhật bộ nhớ tạm
                setState(() {
                   _fetchProducts(isRefresh: true); 
                });
              },
            ),
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(product: p)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirm(doc.id, p.name)),
          ],
        ),
      ),
    );
  }
}