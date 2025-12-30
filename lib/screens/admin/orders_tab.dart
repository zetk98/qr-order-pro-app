import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastOrderCount = -1; // Theo dõi số lượng đơn hàng để phát nhạc

  // Hàm phát âm thanh khi có đơn mới
  void _playNotificationSound() async {
    try {
      // Đảm bảo file nằm đúng tại: assets/sound/tingting.mp3
      await _audioPlayer.play(AssetSource('sound/tingting.mp3'));
    } catch (e) {
      print("Không thể phát âm thanh: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Giải phóng bộ nhớ khi thoát
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        // --- LOGIC PHÁT ÂM THANH ---
        if (_lastOrderCount != -1 && orders.length > _lastOrderCount) {
          _playNotificationSound();
        }
        _lastOrderCount = orders.length;
        // ---------------------------

        if (orders.isEmpty) {
          return const Center(
            child: Text("Chưa có đơn hàng nào hôm nay", 
            style: TextStyle(fontSize: 16, color: Colors.grey))
          );
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index];
            var data = order.data() as Map<String, dynamic>;
            
            // Xử lý dữ liệu an toàn (null-safety)
            List items = data.containsKey('items') ? data['items'] : [];
            String table = data['table'] ?? "??";
            String customer = data['customer'] ?? "Khách";
            int total = data['total'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("BÀN $table", 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        Text(customer, 
                          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    const Divider(),
                    // Hiển thị danh sách món ăn trong đơn
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text("• $item", style: const TextStyle(fontSize: 16)),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("TỔNG: ${total}đ", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Xóa đơn hàng khi đã phục vụ xong
                            FirebaseFirestore.instance.collection('orders').doc(order.id).delete();
                          },
                          icon: const Icon(Icons.done_all, color: Colors.white),
                          label: const Text("HOÀN TẤT", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}