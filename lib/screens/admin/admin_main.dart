import 'package:flutter/material.dart';
import 'orders_tab.dart';
import 'products_tab.dart';
import 'category_tab.dart'; // Đảm bảo bạn đã tạo file này

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  // Tông màu đồng bộ
  final Color coffeeDark = const Color(0xFF4E342E);
  final Color coffeePrimary = const Color(0xFF6F4E37);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Sửa từ 2 thành 3 để có thêm tab Danh mục
      child: Scaffold(
        backgroundColor: Colors.brown[50],
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
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), // Chỉnh nhỏ lại một chút để vừa 3 tab
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_rounded, size: 20),
                    SizedBox(height: 4),
                    Text("ĐƠN HÀNG"),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.coffee_maker_rounded, size: 20),
                    SizedBox(height: 4),
                    Text("SẢN PHẨM"),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_rounded, size: 20),
                    SizedBox(height: 4),
                    Text("DANH MỤC"),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [coffeePrimary.withOpacity(0.05), Colors.white],
            ),
          ),
          child: const TabBarView(
            physics: BouncingScrollPhysics(),
            children: [
              OrdersTab(),
              ProductsTab(),
              CategoryTab(), // Thêm màn hình quản lý danh mục vào đây
            ],
          ),
        ),
      ),
    );
  }
}