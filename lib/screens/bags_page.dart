// lib/screens/bags_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/globalprovider.dart';
import '../models/product_model.dart'; // Ensure this path is correct

class BagsPage extends StatelessWidget {
  const BagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalProvider>(
      builder: (context, provider, _) {
        final items = provider.cartItems;
        final localizedStrings = provider.localizedStrings;

        // Handle case where user is not logged in
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
                      // Navigate to the profile page which will then show FirebaseUI's SignInScreen
                      // Assumes your ProfilePage or a dedicated login route handles this.
                      // If using FirebaseUI's ProfileScreen directly for login prompt:
                      Navigator.pushNamed(context, '/profile');
                      // Or, if you have a specific login route that shows SignInScreen:
                      // Navigator.pushNamed(context, '/login');
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
          appBar: AppBar(title: Text(localizedStrings['cart'] ?? 'Cart')),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  leading:
                      item.image != null && item.image!.isNotEmpty
                          ? Image.network(
                            item.image!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                          )
                          : const Icon(Icons.category, size: 50),
                  title: Text(
                    item.title ??
                        localizedStrings['unknown_product'] ??
                        'Unknown Product',
                  ),
                  subtitle: Text(
                    '₮${(item.price! * item.count).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => provider.decreaseQuantity(item),
                        tooltip:
                            localizedStrings['decrease_quantity'] ??
                            'Decrease quantity',
                      ),
                      Text('${item.count}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => provider.increaseQuantity(item),
                        tooltip:
                            localizedStrings['increase_quantity'] ??
                            'Increase quantity',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () => provider.removeFromCart(item),
                        tooltip:
                            localizedStrings['remove_from_cart'] ??
                            'Remove from cart',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              // Wrap in a Card for better visual separation
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizedStrings['total'] ?? 'Нийт:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '₮${provider.cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      onPressed: () {
                        // TODO: Implement Checkout Logic
                        // This could navigate to a new page, show a dialog, etc.
                        // For example: Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localizedStrings['checkout_not_implemented'] ??
                                  'Checkout feature is not yet implemented.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
