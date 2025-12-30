import 'package:flutter/material.dart';
import 'menu_screen.dart';
import 'admin/admin_main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String table = "00";

  // ĐÃ SỬA LỖI Ở ĐÂY: 0xFF thay vì 0Base
  final Color coffeeColor = const Color(0xFF6F4E37); 

  @override
  void initState() {
    super.initState();
    table = Uri.base.queryParameters['table'] ?? "00";
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nền Gradient tông Nâu Cà Phê
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8D6E63), Color(0xFF4E342E)], 
              ),
            ),
          ),
          
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Container(
                  width: 350,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Ly Cà Phê
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: coffeeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_cafe_rounded, size: 70, color: coffeeColor),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Chào mừng!",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF3E2723)),
                      ),
                      Text(
                        "BÀN SỐ $table",
                        style: const TextStyle(fontSize: 20, color: Color(0xFF795548), fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 30),
                      
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "Nhập tên của bạn...",
                          prefixIcon: Icon(Icons.emoji_food_beverage_outlined, color: coffeeColor),
                          filled: true,
                          fillColor: Colors.brown[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: coffeeColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      // Nút Vào Menu
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: coffeeColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: coffeeColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (_nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Cho tụi mình biết tên bạn để dễ phục vụ nhé!")),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MenuScreen(name: _nameController.text, table: table)),
                            );
                          },
                          child: const Text("XEM MENU & ĐẶT MÓN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminMainScreen())),
                        child: Text(
                          "DÀNH CHO QUẢN LÝ",
                          style: TextStyle(color: Colors.brown[300], fontSize: 13, decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}