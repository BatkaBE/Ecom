import 'dart:convert';
import 'package:http/http.dart' as http;
// import '../models/cart.dart'; // Not needed if cart uses ProductModel
import '../models/product_model.dart';

class ApiService {
  final String baseUrl = "https://fakestoreapi.com";

  // login, getUserIdByUsername, getUserCart, getCartByUserId, addToServerCart, updateServerCart
  // can be removed as Firebase and Firestore handle these.

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products"));
      if (response.statusCode == 200) {
        final List<dynamic> productJson = jsonDecode(response.body);
        return productJson.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        print('Failed to load products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('getAllProducts error: $e');
      return [];
    }
  }

  Future<ProductModel?> getProductById(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/products/$id"));
      if (response.statusCode == 200) {
        return ProductModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('getProductById error: $e');
    }
    return null;
  }
}
