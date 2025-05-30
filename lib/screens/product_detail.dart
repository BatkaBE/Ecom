// lib/screens/product_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/comment_model.dart'; // This import is actively used
import '../provider/globalprovider.dart';

class ProductDetail extends StatefulWidget {
  final ProductModel product;
  const ProductDetail(this.product, {super.key});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final String productIdToFetch = widget.product.id?.toString() ?? "";
        Provider.of<GlobalProvider>(
          context,
          listen: false,
        ).fetchProductComments(productIdToFetch);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(GlobalProvider provider) async {
    final localizedStrings = provider.localizedStrings;

    if (_commentController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedStrings['comment_empty_error'] ??
                'Comment cannot be empty.',
          ),
        ),
      );
      return;
    }

    if (widget.product.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedStrings['product_id_missing_error'] ??
                'Product ID is missing.',
          ),
        ),
      );
      return;
    }

    if (provider.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedStrings['login_to_comment_error'] ??
                'Please log in to comment.',
          ),
        ),
      );
      return;
    }

    final success = await provider.addProductComment(
      widget.product.id.toString(),
      _commentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedStrings['comment_added_success'] ?? 'Comment added!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedStrings['comment_add_failed_error'] ??
                'Failed to add comment.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GlobalProvider>(context);
    final localizedStrings = provider.localizedStrings;

    final String productTitle =
        widget.product.title ??
            (localizedStrings['unknown_product'] ?? 'Product');
    final String? productImage = widget.product.image;
    final String productDescription =
        widget.product.description ??
            (localizedStrings['no_description'] ?? 'No description available.');
    final double productPrice = widget.product.price ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(productTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rearranged: Image, Price, Title, Description
                  if (productImage != null && productImage.isNotEmpty)
                    Center(
                      child: Hero(
                        tag: 'product_image_${widget.product.id}',
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.network(
                              productImage,
                              height: 220,
                              width: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image_outlined,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '${localizedStrings['price_label'] ?? ''} ${productPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizedStrings['description_label'] ?? 'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        productDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(thickness: 1.2, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    localizedStrings['comments_section_title'] ?? 'Comments',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCommentInputSection(provider),
                  const SizedBox(height: 16),
                  _buildCommentsListSection(provider),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (provider.currentUser == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizedStrings['login_to_add_to_cart_error'] ??
                      'Please log in to add items to the cart.',
                ),
              ),
            );
            return;
          }
          provider.addToCart(widget.product);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizedStrings['added_to_cart_message'] ??
                    '${widget.product.title} added to cart!',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: Text(localizedStrings['add_to_cart_button'] ?? 'Add to Cart'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildCommentInputSection(GlobalProvider provider) {
    final localizedStrings = provider.localizedStrings;

    if (provider.currentUser == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Text(
                localizedStrings['login_to_comment_prompt'] ??
                    'Please log in to share your thoughts!',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
                icon: const Icon(Icons.login),
                label: Text(localizedStrings['login_button'] ?? 'Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: localizedStrings['comment_hint'] ??
                      'Write a comment... 💬',
                  prefixIcon: const Icon(Icons.mode_comment_outlined),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: provider.isLoadingComments
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),

              )
                  : ElevatedButton(
                onPressed: () => _submitComment(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(localizedStrings['send_button'] ?? 'Send'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsListSection(GlobalProvider provider) {
    final comments = provider.productComments;
    final localizedStrings = provider.localizedStrings;

    if (provider.isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (comments.isEmpty) {
      return Center(
        child: Text(
          localizedStrings['no_comments_yet'] ?? 'No comments yet.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueGrey[100],
              child: const Icon(Icons.person, color: Colors.black54),
            ),
            title: Text(comment.username ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(comment.content),
            trailing: Text(
              DateFormat('yyyy.MM.dd HH:mm')
                  .format(comment.timestamp.toDate()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
