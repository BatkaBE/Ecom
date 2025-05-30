import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/globalprovider.dart';
import 'shop_page.dart';
import 'basket_page.dart';
import 'favorite_page.dart';
import 'profile_page.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final idx = context.watch<GlobalProvider>().currentIdx;
    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: const [ShopPage(), BagsPage(), FavoritePage(), ProfilePage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        elevation: 12,
        showUnselectedLabels: true,
        currentIndex: idx,
        onTap: context.read<GlobalProvider>().changeCurrentIdx,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop', backgroundColor: Colors.white),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Cart',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile', backgroundColor: Colors.white,),
        ],
      ),
    );
  }
}
