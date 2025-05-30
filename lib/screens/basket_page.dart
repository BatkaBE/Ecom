
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/globalprovider.dart';
import '../models/product_model.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalProvider>(
      builder: (context, provider, _) {
        final items = provider.cartItems;
        final localizedStrings = provider.localizedStrings;

        if (provider.currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: Text(localizedStrings['cart'] ?? 'Cart')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    localizedStrings['login_to_view_cart'] ??
                        'Please log in to view your cart.',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {

                      Navigator.pushNamed(context, '/profile');

                    },
                    child: Text(localizedStrings['login'] ?? 'Login'),
                  ),
                ],
              ),
            ),
          );
        }

        if (items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(localizedStrings['cart'] ?? 'Cart')),
            body: Center(
              child: Text(
                localizedStrings['cart_empty'] ?? 'Сагс хоосон байна',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(localizedStrings['cart'] ?? 'Cart'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
          ),
          body: Container(
            color: Colors.grey[100],
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: item.image != null && item.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.image!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.image_not_supported,
                                size: 56,
                              ),
                            ),
                          )
                        : const Icon(Icons.category, size: 56, color: Colors.grey),
                    title: Text(
                      item.title ?? localizedStrings['unknown_product'] ?? 'Unknown Product',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '₮${(item.price! * item.count).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => provider.decreaseQuantity(item),
                            tooltip: localizedStrings['decrease_quantity'] ?? 'Decrease quantity',
                          ),
                          Text('${item.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => provider.increaseQuantity(item),
                            tooltip: localizedStrings['increase_quantity'] ?? 'Increase quantity',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () => provider.removeFromCart(item),
                            tooltip: localizedStrings['remove_from_cart'] ?? 'Remove from cart',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedStrings['total'] ?? 'Нийт:',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        Text(
                          '₮${provider.cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizedStrings['checkout_not_implemented'] ?? 'Checkout feature is not yet implemented.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      label: Text(localizedStrings['buy_all'] ?? 'Buy All'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
