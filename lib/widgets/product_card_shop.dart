import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../screens/product_detail.dart';
import '../provider/globalprovider.dart';

class ProductCardShop extends StatelessWidget {
  final ProductModel data;
  const ProductCardShop(this.data, {Key? key}) : super(key: key);

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetail(data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueGrey.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        margin: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: data.image != null && data.image!.isNotEmpty
                        ? FadeInImage.assetNetwork(
                            placeholder: 'assets/products.json',
                            image: data.image!,
                            fit: BoxFit.cover,
                            imageErrorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                          )
                        : const Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title ?? '-',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.red, size: 20),
                          Text(
                            data.price != null ? data.price!.toStringAsFixed(2) : '-',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Consumer<GlobalProvider>(
                builder: (_, prov, __) {
                  final isFav = prov.isFavorite(data);
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      key: ValueKey(isFav),
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.pink : Colors.redAccent,
                        size: 28,
                      ),
                      onPressed: () => prov.toggleFavorite(data),
                      tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                    ),
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

