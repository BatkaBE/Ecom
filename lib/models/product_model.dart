// models/product_model.dart
// Assuming ProductModel looks something like this.
// Add or ensure fromJson and toJson for Firestore.

class Rating {
  final double? rate;
  final int? count;

  Rating({this.rate, this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rate: (json['rate'] as num?)?.toDouble(),
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'rate': rate, 'count': count};
  }
}

class ProductModel {
  final int? id;
  final String? title;
  final double? price;
  final String? description;
  final String? category;
  final String? image;
  final Rating? rating;
  bool isFavorite; // Already exists, good.
  int count; // Already exists, good.

  ProductModel({
    this.id,
    this.title,
    this.price,
    this.description,
    this.category,
    this.image,
    this.rating,
    this.isFavorite = false,
    this.count = 0, // Default count
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int?,
      title: json['title'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      description: json['description'] as String?,
      category: json['category'] as String?,
      image: json['image'] as String?,
      rating: json['rating'] != null ? Rating.fromJson(json['rating']) : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      'rating': rating?.toJson(),
      'isFavorite': isFavorite,
      'count': count,
    };
  }

  static List<ProductModel> fromList(List<dynamic> list) =>
      list.map((item) => ProductModel.fromJson(item)).toList();

  // For Firestore cart items, we might only need a subset or reference
  // But if storing the whole product, toJson/fromJson are key.
}
