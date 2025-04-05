import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:navobs/menu_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _unverifiedMenu = false;
  final String _adminEmail = 'admin@email.com';

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  bool _isAdmin() {
    return FirebaseAuth.instance.currentUser?.email == _adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navobs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => setState(() => _unverifiedMenu = !_unverifiedMenu),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _unverifiedMenu
          ? const MenuScreen(
              menuTitle: "Unverified", 
              isUnverified: true,
              canEdit: true,
            )
          : MenuScreen(
              menuTitle: "Verified", 
              isUnverified: false,
              canEdit: _isAdmin(),
            ),
    );
  }
}
