import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ← Provider-ийн импорт
import '../models/product_model.dart';
import '../screens/product_detail.dart';
import '../provider/globalprovider.dart';

class ProductViewShop extends StatelessWidget {
  final ProductModel data;
  const ProductViewShop(this.data, {Key? key}) : super(key: key);

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetail(data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Stack(
          // ← Column → Stack болгосон
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(data.image!),
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${data.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Favorite button overlay
            Positioned(
              top: 8,
              right: 8,
              child: Consumer<GlobalProvider>(
                builder: (_, prov, __) {
                  final isFav = prov.isFavorite(data);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () => prov.toggleFavorite(data),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
