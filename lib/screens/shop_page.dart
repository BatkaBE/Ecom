import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../widgets/product_view_shop.dart';
import '../provider/globalprovider.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late Future<void> _loadProductsFuture;

  @override
  void initState() {
    super.initState();
    // Future-г нэг удаа хадгалж авна
    _loadProductsFuture =
        Provider.of<GlobalProvider>(context, listen: false).loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final globalProvider = Provider.of<GlobalProvider>(context);

    return FutureBuilder<void>(
      future: _loadProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading products: ${snapshot.error}'),
          );
        }

        final items = globalProvider.products;

        if (items.isEmpty) {
          return const Center(child: Text('No products found.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await globalProvider.loadProducts();
            setState(() {
              _loadProductsFuture =
                  Future.value(); // эсвэл дахин шинэ Future үүсгэх
            });
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map((product) => ProductViewShop(product))
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}
