import 'package:flutter/material.dart';
import 'orders_tab.dart';
import 'products_tab.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  // Tông màu đồng bộ với Welcome và Menu
  final Color coffeeDark = const Color(0xFF4E342E);
  final Color coffeePrimary = const Color(0xFF6F4E37);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.brown[50], // Nền sáng dễ nhìn cho Admin
        appBar: AppBar(
          elevation: 4,
          shadowColor: coffeeDark.withOpacity(0.5),
          backgroundColor: coffeePrimary,
          title: const Text(
            "HỆ THỐNG QUẢN TRỊ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            // Hiệu ứng thanh chỉ báo Tab mượt hơn
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_rounded),
                    SizedBox(width: 8),
                    Text("ĐƠN HÀNG"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.coffee_maker_rounded),
                    SizedBox(width: 8),
                    Text("SẢN PHẨM"),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Sử dụng AnimatedBuilder hoặc đơn giản là TabBarView với hiệu ứng mặc định
        // Nếu muốn hiệu ứng mạnh hơn, ta bọc trong AnimatedSwitcher
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [coffeePrimary.withOpacity(0.05), Colors.white],
            ),
          ),
          child: const TabBarView(
            // Hiệu ứng vật lý khi vuốt giữa các tab
            physics: BouncingScrollPhysics(),
            children: [
              OrdersTab(),
              ProductsTab(),
            ],
          ),
        ),
      ),
    );
  }
}