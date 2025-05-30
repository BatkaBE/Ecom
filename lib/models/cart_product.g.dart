// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartProduct _$CartProductFromJson(Map<String, dynamic> json) => CartProduct(
      productId: (json['productId'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      productDetails: json['productDetails'] == null
          ? null
          : ProductModel.fromJson(
              json['productDetails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CartProductToJson(CartProduct instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
      'productDetails': instance.productDetails,
    };
