import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing WooCommerce Connection...');
  await dotenv.load(fileName: '.env');

  const baseUrl = 'https://sayitnowwithselflovekidsllc.com';
  final consumerKey = dotenv.env['WOOCOMMERCE_CONSUMER_KEY']!;
  final consumerSecret = dotenv.env['WOOCOMMERCE_CONSUMER_SECRET']!;
  
  // Generate auth headers
  final credentials = base64.encode(utf8.encode('$consumerKey:$consumerSecret'));
  final headers = {
    'Authorization': 'Basic $credentials',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  try {
    print('🌐 Testing basic internet connectivity...');
    final googleResponse = await http.get(Uri.parse('https://www.google.com')).timeout(
      const Duration(seconds: 5),
    );
    print('✅ Internet connectivity: OK (${googleResponse.statusCode})');
    
    print('🛒 Testing WooCommerce API...');
    final testUri = Uri.parse('$baseUrl/wp-json/wc/v3/products').replace(queryParameters: {
      'per_page': '1',
      'page': '1',
    });
    
    final response = await http.get(testUri, headers: headers).timeout(
      const Duration(seconds: 10),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> products = json.decode(response.body);
      print('✅ WooCommerce API: SUCCESS!');
      print('📦 Found ${products.length} products');
      
      if (products.isNotEmpty) {
        final product = products.first;
        print('🎯 First product: ${product['name']} - \$${product['price']}');
      }
      
      // Get total count from headers
      final totalCount = response.headers['x-wp-total'] ?? '0';
      final totalPages = response.headers['x-wp-totalpages'] ?? '0';
      print('📊 Total products in store: $totalCount');
      print('📄 Total pages: $totalPages');
      
    } else {
      print('❌ WooCommerce API failed: ${response.statusCode}');
      print('📄 Response: ${response.body}');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
} 