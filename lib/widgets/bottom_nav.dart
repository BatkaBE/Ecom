// lib/widgets/bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/globalprovider.dart';

class AppBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GlobalProvider>(context);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: provider.currentIdx,
      onTap: provider.changeCurrentIdx,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shopping', backgroundColor: Colors.blue),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket),
          label: 'Bag',
          backgroundColor: Colors.blue
        ),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorite', backgroundColor: Colors.blue),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile', backgroundColor: Colors.blue,
        ),
      ],
    );
  }
}
