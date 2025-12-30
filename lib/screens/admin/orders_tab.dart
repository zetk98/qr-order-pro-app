import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart'; // Thêm thư viện này để định dạng tiền tệ/thời gian

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastOrderCount = -1;

  void _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sound/tingting.mp3'));
    } catch (e) {
      debugPrint("Không thể phát âm thanh: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true) // Sửa thành 'createdAt' cho khớp model
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!.docs;

        // Logic phát âm thanh
        if (_lastOrderCount != -1 && orders.length > _lastOrderCount) {
          _playNotificationSound();
        }
        _lastOrderCount = orders.length;

        if (orders.isEmpty) {
          return const Center(
              child: Text("Chưa có đơn hàng nào", 
              style: TextStyle(fontSize: 16, color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index];
            var data = order.data() as Map<String, dynamic>;
            
            // Ép kiểu dữ liệu khớp với Model đã gửi lên
            List items = data['items'] ?? [];
            String table = data['tableNum'] ?? "??"; // Khớp 'tableNum'
            String customer = data['customerName'] ?? "Khách lạ"; // Khớp 'customerName'
            int total = data['totalPrice'] ?? 0; // Khớp 'totalPrice'
            
            // Lấy thời gian đơn hàng
            String timeStr = "";
            if (data['createdAt'] != null) {
              DateTime dt = (data['createdAt'] as Timestamp).toDate();
              timeStr = DateFormat('HH:mm').format(dt);
            }

            return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  shape: const Border(), // Xóa đường gạch mặc định khi mở rộng của ExpansionTile
                  title: Text(
                    "BÀN $table - $customer",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6F4E37)),
                  ),
                  // 1. Cập nhật thời gian bao gồm cả ngày tháng
                  subtitle: Text(
                    data['createdAt'] != null 
                        ? DateFormat('dd/MM HH:mm').format((data['createdAt'] as Timestamp).toDate())
                        : "--:--",
                    style: const TextStyle(fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Đã xóa các đường Divider() (đường gạch) ở đây
                          
                          ...items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.brown[50],
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text("x${item['qty']}",
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("${item['name']}",
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                        if (item['note'] != null && item['note'] != "")
                                          Text("${item['note']}",
                                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text("${item['price'] * item['qty']}đ"),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 10),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 3. Thay thế "Chờ cung ứng" bằng Tổng tiền
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Tổng thanh toán:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(
                                    "${NumberFormat('#,###').format(total)}đ",
                                    style: const TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _confirmComplete(order.id),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text("XONG", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
          },
        );
      },
    );
  }

  void _confirmComplete(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hoàn tất đơn hàng?"),
        content: const Text("Đơn hàng sẽ được đánh dấu là hoàn thành và xóa khỏi danh sách chờ."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
              Navigator.pop(ctx);
            }, 
            child: const Text("XÁC NHẬN", style: TextStyle(color: Colors.green))
          ),
        ],
      ),
    );
  }
}