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
    // Use Future.microtask to ensure that the context is available and
    // to call Provider after the build phase.
    Future.microtask(() {
      if (mounted) {
        // Ensure product.id is converted to string; provide an empty string if id is null.
        // The revised fetchProductComments in GlobalProvider will handle an empty string
        // by clearing comments and setting loading state appropriately.
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

  // Method to handle comment submission
  Future<void> _submitComment(GlobalProvider provider) async {
    final localizedStrings = provider.localizedStrings;

    // Check if comment is empty
    if (_commentController.text.trim().isEmpty) {
      if (!mounted) return; // Guard BuildContext
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

    // Check if product ID is missing
    if (widget.product.id == null) {
      if (!mounted) return; // Guard BuildContext
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

    // Check if user is logged in
    if (provider.currentUser == null) {
      if (!mounted) return; // Guard BuildContext
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

    // Attempt to add the comment via the provider
    final success = await provider.addProductComment(
      widget.product.id.toString(), // Ensure ID is a string
      _commentController.text.trim(),
    );

    if (!mounted) return; // Guard BuildContext after await

    // Show feedback based on success
    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Hide keyboard
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
    // Access the provider and localized strings
    final provider = Provider.of<GlobalProvider>(context);
    final localizedStrings = provider.localizedStrings;

    // Prepare product details with fallbacks for null values
    final String productTitle =
        widget.product.title ??
        (localizedStrings['unknown_product'] ?? 'Product');
    final String? productImage = widget.product.image;
    final String productDescription =
        widget.product.description ??
        (localizedStrings['no_description'] ?? 'No description available.');
    final double productPrice = widget.product.price ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(productTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  if (productImage != null && productImage.isNotEmpty)
                    Center(
                      child: Hero(
                        tag:
                            'product_image_${widget.product.id}', // Unique tag for Hero animation
                        child: Image.network(
                          productImage,
                          height: 250,
                          fit: BoxFit.contain,
                          // Error builder for image loading issues
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image_outlined,
                                size: 100,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Product Title
                  Text(
                    productTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product Price
                  Text(
                    '${localizedStrings['price_label'] ?? 'PRICE'}: \$${productPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Description
                  Text(
                    localizedStrings['description_label'] ?? 'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Comments Section
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    localizedStrings['comments_section_title'] ?? 'Comments',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCommentInputSection(provider), // Comment input widget
                  const SizedBox(height: 16),
                  _buildCommentsListSection(provider), // Comments list widget
                ],
              ),
            ),
          ),
        ],
      ),
      // Add to Cart Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Check if user is logged in before adding to cart
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
          // Add product to cart and show confirmation
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
      ),
    );
  }

  // Widget to build the comment input field and post button
  Widget _buildCommentInputSection(GlobalProvider provider) {
    final localizedStrings = provider.localizedStrings;

    // If user is not logged in, show a prompt to log in
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
              ElevatedButton(
                onPressed: () {
                  // Navigate to profile/login screen
                  Navigator.pushNamed(context, '/profile');
                },
                child: Text(localizedStrings['login_button'] ?? 'Login'),
              ),
            ],
          ),
        ),
      );
    }

    // If user is logged in, show the comment input field
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText:
                    localizedStrings['write_comment_hint'] ??
                    'Write your comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
              ),
              maxLines: 3, // Allow multiple lines for comments
              minLines: 1,
              textInputAction: TextInputAction.newline, // For multiline input
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_outlined),
              label: Text(
                localizedStrings['post_comment_button'] ?? 'Post Comment',
              ),
              onPressed:
                  () => _submitComment(provider), // Submit comment on press
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build the list of comments
  Widget _buildCommentsListSection(GlobalProvider provider) {
    final localizedStrings = provider.localizedStrings;

    // Show loading indicator while comments are being fetched
    if (provider.isLoadingComments) {
      return const Center(child: CircularProgressIndicator());
    }

    final comments = provider.productComments;

    // If there are no comments, show a message
    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            localizedStrings['no_comments_yet_message'] ??
                'No comments yet. Be the first to share your thoughts!',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If comments exist, display them in a ListView
    return ListView.separated(
      shrinkWrap: true, // Important for ListView inside SingleChildScrollView
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return Card(
          elevation: 1.0,
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            // User Avatar
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              backgroundImage:
                  comment.userAvatarUrl != null &&
                          comment.userAvatarUrl!.isNotEmpty
                      ? NetworkImage(
                        comment.userAvatarUrl!,
                      ) // Network image for avatar
                      : null, // No image if URL is null or empty
              // Fallback to initials if no avatar URL
              child:
                  (comment.userAvatarUrl == null ||
                              comment.userAvatarUrl!.isEmpty) &&
                          comment.username.isNotEmpty
                      ? Text(
                        comment.username[0].toUpperCase(),
                        style: TextStyle(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                      )
                      : null,
            ),
            // Username
            title: Text(
              comment.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Comment content and timestamp
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.content, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 5),
                Text(
                  // Format timestamp for display
                  DateFormat(
                    'MMM d, yyyy \'at\' hh:mm a', // Example: May 28, 2023 at 05:30 PM
                  ).format(comment.timestamp.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            isThreeLine: true, // Allows more space for subtitle
          ),
        );
      },
      separatorBuilder:
          (context, index) =>
              const SizedBox(height: 4), // Space between comments
    );
  }
}
