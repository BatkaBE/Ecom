import 'package:json_annotation/json_annotation.dart';
import 'package:shop/models/product_model.dart';
part 'cart_product.g.dart';

@JsonSerializable()
class CartProduct {
  final int productId;
  final int quantity;

  ProductModel? productDetails;

  CartProduct({required this.productId, required this.quantity, this.productDetails});

  factory CartProduct.fromJson(Map<String, dynamic> json) => _$CartProductFromJson(json);
  Map<String, dynamic> toJson() => _$CartProductToJson(this);
}
