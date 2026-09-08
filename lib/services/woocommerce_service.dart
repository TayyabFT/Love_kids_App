import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/woocommerce_models.dart';
import '../utils/shipping_calculator.dart';

class WooCommerceService {
  // WooCommerce credentials, loaded from .env (see .env.example)
  static const String _baseUrl = 'https://sayitnowwithselflovekidsllc.com';
  static String get _consumerKey => dotenv.env['WOOCOMMERCE_CONSUMER_KEY']!;
  static String get _consumerSecret => dotenv.env['WOOCOMMERCE_CONSUMER_SECRET']!;

  // Generate basic auth headers
  Map<String, String> _generateAuthHeaders() {
    final credentials = base64.encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Helper method for making HTTP requests with retry logic
  Future<http.Response> _makeRequestWithRetry(Uri uri, Map<String, String> headers, {int maxRetries = 2}) async {
    int attempts = 0;
    Duration timeout = Duration(seconds: 15); // Increased timeout
    
    while (attempts < maxRetries) {
      try {
        print('🔄 Attempt ${attempts + 1}/$maxRetries for: ${uri.toString()}');
        print('🌐 Using headers: ${headers.keys.join(', ')}');
        
        final response = await http.get(uri, headers: headers).timeout(
          timeout,
          onTimeout: () {
            throw Exception('Request timeout after ${timeout.inSeconds} seconds');
          },
        );
        
        print('✅ Request successful: ${response.statusCode}');
        print('📄 Response headers: ${response.headers}');
        return response;
        
      } catch (e) {
        attempts++;
        print('❌ Attempt $attempts failed: $e');
        
        // Check if it's a DNS resolution error
        if (e.toString().contains('Failed host lookup') || e.toString().contains('No address associated with hostname')) {
          print('🌐 DNS Resolution Error - This might be a network issue on the device');
          print('💡 Try checking your device\'s internet connection');
        }
        
        if (attempts < maxRetries) {
          final waitTime = Duration(seconds: attempts * 3); // Increased wait time
          print('⏳ Waiting ${waitTime.inSeconds} seconds before retry...');
          await Future.delayed(waitTime);
          timeout = Duration(seconds: timeout.inSeconds + 5); // Increased timeout increment
        } else {
          rethrow;
        }
      }
    }
    
    throw Exception('All retry attempts failed');
  }

  // Test WooCommerce API connection and get product count
  Future<Map<String, dynamic>> testWooCommerceConnection() async {
    try {
      print('🔍 Testing WooCommerce API connection...');
      
      // First, test basic internet connectivity
      try {
        print('🌐 Testing basic internet connectivity...');
        await http.get(Uri.parse('https://www.google.com')).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Internet connectivity timeout');
          },
        );
        print('✅ Basic internet connectivity: OK');
      } catch (e) {
        print('❌ Basic internet connectivity failed: $e');
        return {
          'success': false,
          'error': 'No internet connectivity on device',
          'statusCode': 0,
        };
      }
      
      final testUri = Uri.parse('$_baseUrl/wp-json/wc/v3/products').replace(queryParameters: {
        'per_page': '1',
        'page': '1',
      });
      final headers = _generateAuthHeaders();
      
      print('🌐 Testing URL: ${testUri.toString()}');
      print('🔑 Using credentials: $_consumerKey');
      
      final response = await http.get(testUri, headers: headers).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ API connection successful!');
        print('📦 Found ${jsonList.length} products in test request');
        
        final totalCount = response.headers['x-wp-total'] ?? '0';
        final totalPages = response.headers['x-wp-totalpages'] ?? '0';
        
        print('📊 Total products in store: $totalCount');
        print('📄 Total pages: $totalPages');
        
        return {
          'success': true,
          'totalProducts': int.tryParse(totalCount) ?? 0,
          'totalPages': int.tryParse(totalPages) ?? 0,
          'testProducts': jsonList.length,
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ API connection failed with status: ${response.statusCode}');
        print('📄 Error response: ${response.body}');
        
        return {
          'success': false,
          'error': 'API returned status: ${response.statusCode}',
          'statusCode': response.statusCode,
          'response': response.body,
        };
      }
    } catch (e) {
      print('❌ API connection test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'statusCode': 0,
      };
    }
  }

  // Get products with proper pagination
  Future<List<WooProduct>> getProducts({
    int page = 1,
    int perPage = 10,
    String search = '',
    String category = '',
    String status = 'publish',
    bool fetchAll = false, 
  }) async {
    try {
      List<WooProduct> allProducts = [];
      int currentPage = page;
      bool hasMoreProducts = true;
      int maxPages = fetchAll ? 50 : 1;
      int pageCount = 0;

      while (hasMoreProducts && pageCount < maxPages && (fetchAll || currentPage == page)) {
        final queryParams = {
          'page': currentPage.toString(),
          'per_page': perPage.toString(),
          'status': status,
          'orderby': 'date', 
          'order': 'desc',
        };
        
        if (search.isNotEmpty && search.length > 1) {
          queryParams['search'] = search;
        }
        
        if (category.isNotEmpty && int.tryParse(category) != null) {
          queryParams['category'] = category;
        }

        final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/products').replace(queryParameters: queryParams);
        final headers = _generateAuthHeaders();

        try {
          final response = await _makeRequestWithRetry(uri, headers);
          
          if (response.statusCode == 200) {
            final List<dynamic> jsonList = json.decode(response.body);
            print('Found ${jsonList.length} products on page $currentPage');
            
            if (jsonList.isEmpty) {
              hasMoreProducts = false;
            } else {
              final pageProducts = jsonList.map((json) => WooProduct.fromJson(json)).toList();
              allProducts.addAll(pageProducts);
              pageCount++;
              
              if (jsonList.length < perPage) {
                hasMoreProducts = false;
              } else if (fetchAll && pageCount < maxPages) {
                currentPage++;
                await Future.delayed(Duration(milliseconds: 1000));
              } else {
                hasMoreProducts = false;
              }
            }
          } else if (response.statusCode == 400 && search.isNotEmpty) {
            print('Search failed, retrying without search parameter...');
            return getProducts(
              page: page,
              perPage: perPage,
              category: category,
              status: status,
              fetchAll: false,
            );
          } else {
            throw Exception('API returned status: ${response.statusCode}');
          }
        } catch (e) {
          if (currentPage == 1 || allProducts.isEmpty) {
            print('⚠️ API failed, returning mock data...');
            return _getMockProducts();
          } else {
            break;
          }
        }
      }

      print('Total products fetched: ${allProducts.length}');
      return allProducts;
    } catch (e) {
      print('Exception in getProducts: $e');
      
      // Try alternative approach for DNS issues
      if (e.toString().contains('Failed host lookup') || e.toString().contains('No address associated with hostname')) {
        print('🔄 Trying alternative DNS resolution...');
        try {
          // Try with IP address directly
          final ipUri = Uri.parse('https://82.197.83.92/wp-json/wc/v3/products').replace(queryParameters: {
            'page': page.toString(),
            'per_page': perPage.toString(),
            'status': status,
            'orderby': 'date', 
            'order': 'desc',
          });
          final headers = _generateAuthHeaders();
          headers['Host'] = 'sayitnowwithselflovekidsllc.com'; // Add host header
          
          final response = await http.get(ipUri, headers: headers).timeout(
            const Duration(seconds: 10),
          );
          
          if (response.statusCode == 200) {
            final List<dynamic> jsonList = json.decode(response.body);
            print('✅ Successfully fetched products using IP address!');
            return jsonList.map((json) => WooProduct.fromJson(json)).toList();
          }
        } catch (ipError) {
          print('❌ IP address approach also failed: $ipError');
        }
      }
      
      print('🔄 Returning mock data due to API failure...');
      return _getMockProducts();
    }
  }

  // Get product categories
  Future<List<WooProductCategory>> getCategories() async {
    try {
      final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/products/categories').replace(queryParameters: {
        'per_page': '30',
        'hide_empty': 'false',
        'orderby': 'name',
        'order': 'asc',
      });

      final headers = _generateAuthHeaders();
      final response = await _makeRequestWithRetry(uri, headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ Loaded ${jsonList.length} categories from API');
        
        return jsonList.map((json) => WooProductCategory.fromJson(json)).toList();
      } else {
        print('❌ Categories API failed: ${response.statusCode}');
        return _getMockCategories();
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      return _getMockCategories();
    }
  }

  // Get product by ID
  Future<WooProduct?> getProduct(int productId) async {
    try {
      final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/products/$productId');
      final headers = _generateAuthHeaders();
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return WooProduct.fromJson(json.decode(response.body));
      } else {
        print('Error fetching product: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in getProduct: $e');
      return null;
    }
  }

  // Mock data for when API fails
  List<WooProduct> _getMockProducts() {
    return [
      WooProduct(
        id: 10001,
        name: "Sample Self-Love Kids Cap",
        description: "A beautiful cap for kids to boost their self-confidence",
        shortDescription: "Kids confidence cap",
        sku: "CAP001",
        price: 25.99,
        regularPrice: 29.99,
        salePrice: 25.99,
        onSale: true,
        status: "publish",
        images: [],
        categories: [WooProductCategory(id: 101, name: "Caps", slug: "caps")],
        attributes: [],
        stockQuantity: 10,
        inStock: true,
        stockStatus: "instock",
      ),
      WooProduct(
        id: 10002,
        name: "Motivational Kids T-Shirt",
        description: "Inspiring t-shirt with positive messages for children",
        shortDescription: "Motivational kids tee",
        sku: "SHIRT001",
        price: 19.99,
        regularPrice: 19.99,
        salePrice: 0.0,
        onSale: false,
        status: "publish",
        images: [],
        categories: [WooProductCategory(id: 102, name: "Clothing", slug: "clothing")],
        attributes: [],
        stockQuantity: 25,
        inStock: true,
        stockStatus: "instock",
      ),
      WooProduct(
        id: 10003,
        name: "Self-Love Affirmation Book",
        description: "A wonderful book filled with positive affirmations for kids",
        shortDescription: "Kids affirmation book",
        sku: "BOOK001",
        price: 15.99,
        regularPrice: 15.99,
        salePrice: 0.0,
        onSale: false,
        status: "publish",
        images: [],
        categories: [WooProductCategory(id: 103, name: "Books", slug: "books")],
        attributes: [],
        stockQuantity: 50,
        inStock: true,
        stockStatus: "instock",
      ),
    ];
  }

  List<WooProductCategory> _getMockCategories() {
    return [
      WooProductCategory(id: 101, name: "Caps", slug: "caps"),
      WooProductCategory(id: 102, name: "Clothing", slug: "clothing"),
      WooProductCategory(id: 103, name: "Books", slug: "books"),
      WooProductCategory(id: 104, name: "Accessories", slug: "accessories"),
      WooProductCategory(id: 105, name: "Toys", slug: "toys"),
    ];
  }

  // ─── CUSTOMER ─────────────────────────────────────────────────────────────

  Future<WooCustomer?> getCustomerByEmail(String email) async {
    try {
      final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/customers').replace(
        queryParameters: {'email': email, 'role': 'all'},
      );
      final response = await http.get(uri, headers: _generateAuthHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        if (list.isNotEmpty) {
          return WooCustomer.fromJson(list.first);
        }
      }
      return null;
    } catch (e) {
      print('getCustomerByEmail error: $e');
      return null;
    }
  }

  // ─── PAYMENT GATEWAYS ────────────────────────────────────────────────────

  /// WooCommerce gateway ids that route checkout through Stripe (card/debit/bank).
  static const Set<String> _allowedStripeGatewayIds = {'stripe'};

  static bool isAllowedPaymentGateway(String id) =>
      _allowedStripeGatewayIds.contains(id.toLowerCase());

  Future<List<WooPaymentMethod>> getPaymentMethods() async {
    try {
      print('Fetching payment gateways from WooCommerce...');
      final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/payment_gateways');
      final response = await http
          .get(uri, headers: _generateAuthHeaders())
          .timeout(const Duration(seconds: 15));

      print('Payment gateways status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        // Only return gateways that are enabled
        final methods = list
            .where((g) => g['enabled'] == true)
            .map((g) => WooPaymentMethod.fromJson(Map<String, dynamic>.from(g)))
            .where((m) => isAllowedPaymentGateway(m.id))
            .toList();

        print('Loaded ${methods.length} approved Stripe payment gateways');
        for (final m in methods) {
          print('  Gateway: ${m.id} — ${m.title}');
        }
        if (methods.isEmpty) {
          print('No approved gateways found — using Stripe fallback');
          return _fallbackPaymentMethods();
        }
        return methods;
      } else {
        print('Payment gateways API error: ${response.statusCode}\n${response.body}');
        return _fallbackPaymentMethods();
      }
    } catch (e) {
      print('getPaymentMethods error: $e');
      return _fallbackPaymentMethods();
    }
  }

  List<WooPaymentMethod> _fallbackPaymentMethods() {
    return [
      WooPaymentMethod(
        id: 'stripe',
        title: 'Credit / Debit Card / Bank Account',
        description: 'Pay securely with card or bank account via Stripe',
        order: 0,
        enabled: true,
        settings: {},
      ),
    ];
  }

  // ─── SHIPPING METHODS ────────────────────────────────────────────────────

  Future<List<WooShippingMethod>> getShippingMethods() async {
    try {
      print('Fetching shipping zones/methods from WooCommerce...');
      // Step 1: get all shipping zones
      final zonesUri = Uri.parse('$_baseUrl/wp-json/wc/v3/shipping/zones');
      final zonesResp = await http
          .get(zonesUri, headers: _generateAuthHeaders())
          .timeout(const Duration(seconds: 15));

      if (zonesResp.statusCode != 200) {
        print('Shipping zones error: ${zonesResp.statusCode}');
        return _fallbackShippingMethods();
      }

      final List<dynamic> zones = json.decode(zonesResp.body);
      final List<WooShippingMethod> allMethods = [];

      // Step 2: for each zone get its shipping methods
      for (final zone in zones) {
        final zoneId = zone['id'];
        final methodsUri = Uri.parse(
            '$_baseUrl/wp-json/wc/v3/shipping/zones/$zoneId/methods');
        final methodsResp = await http
            .get(methodsUri, headers: _generateAuthHeaders())
            .timeout(const Duration(seconds: 15));

        if (methodsResp.statusCode == 200) {
          final List<dynamic> methods = json.decode(methodsResp.body);
          for (final m in methods) {
            if (m['enabled'] == true) {
              allMethods.add(WooShippingMethod.fromJson(m));
            }
          }
        }
      }

      print('Loaded ${allMethods.length} shipping methods');
      for (final m in allMethods) {
        print('  Shipping: ${m.methodId} — ${m.title}');
      }

      return allMethods.isEmpty ? _fallbackShippingMethods() : allMethods;
    } catch (e) {
      print('getShippingMethods error: $e');
      return _fallbackShippingMethods();
    }
  }

  List<WooShippingMethod> _fallbackShippingMethods() {
    return [
      WooShippingMethod(
        instanceId: 1,
        title: 'Standard Shipping',
        order: 0,
        enabled: true,
        methodId: 'flat_rate',
        methodTitle: 'Flat Rate',
        settings: const {},
      ),
    ];
  }

  // ─── COUPON VALIDATION ───────────────────────────────────────────────────

  Future<WooCoupon?> validateCoupon(String couponCode) async {
    try {
      final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/coupons').replace(
        queryParameters: {'code': couponCode},
      );
      final response = await http
          .get(uri, headers: _generateAuthHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        if (list.isNotEmpty) {
          return WooCoupon.fromJson(list.first);
        }
      }
      return null;
    } catch (e) {
      print('validateCoupon error: $e');
      return null;
    }
  }

  // ─── ORDER TOTALS ────────────────────────────────────────────────────────

  Future<WooOrderTotals?> calculateOrderTotals({
    required List<WooCartItem> cartItems,
    required String country,
    required String state,
    required String postcode,
    String? couponCode,
    String? shippingMethodId,
    List<WooShippingMethod>? shippingMethods,
  }) async {
    // WooCommerce REST API doesn't expose a cart-totals endpoint; derive shipping
    // from product shipping data and zone shipping-method settings.
    try {
      final subtotal =
          cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

      WooShippingMethod? selectedMethod;
      if (shippingMethods != null && shippingMethods.isNotEmpty) {
        if (shippingMethodId != null && shippingMethodId.isNotEmpty) {
          for (final method in shippingMethods) {
            if (method.instanceId.toString() == shippingMethodId) {
              selectedMethod = method;
              break;
            }
          }
        }
        selectedMethod ??= shippingMethods.first;
      }

      final shipping = ShippingCalculator.calculate(
        cartItems: cartItems,
        selectedMethod: selectedMethod,
      );

      const taxRate = 0.10;
      final tax = (subtotal + shipping) * taxRate;
      final total = subtotal + shipping + tax;

      return WooOrderTotals(
        subtotal: subtotal,
        shippingTotal: shipping,
        taxTotal: tax,
        discountTotal: 0.0,
        total: total,
      );
    } catch (e) {
      print('calculateOrderTotals error: $e');
      return null;
    }
  }

  // ─── CREATE ORDER ────────────────────────────────────────────────────────

  Future<WooOrder?> createOrder({
    required List<WooCartItem> cartItems,
    required WooBilling billing,
    required WooShipping shipping,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Cash on Delivery',
    String currency = 'USD',
    String? couponCode,
    String? shippingMethodId,
    WooShippingMethod? shippingMethod,
    double? shippingTotal,
    String? customerNote,
    int? customerId,
    Map<String, dynamic>? metaData,
  }) async {
    try {
      print('Creating WooCommerce order...');
      print('  Payment method: $paymentMethod — $paymentMethodTitle');
      print('  Items: ${cartItems.length}');

      final lineItems = cartItems
          .map((item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              })
          .toList();

      final body = <String, dynamic>{
        'payment_method': paymentMethod,
        'payment_method_title': paymentMethodTitle,
        'set_paid': paymentMethod != 'cod', // mark paid for card payments
        'status': paymentMethod == 'cod' ? 'pending' : 'processing',
        'currency': currency,
        'billing': billing.toJson(),
        'shipping': shipping.toJson(),
        'line_items': lineItems,
        if (couponCode != null && couponCode.isNotEmpty)
          'coupon_lines': [
            {'code': couponCode}
          ],
        if (shippingMethod != null ||
            (shippingMethodId != null && shippingMethodId.isNotEmpty))
          'shipping_lines': [
            {
              'method_id': shippingMethod?.methodId ?? 'flat_rate',
              'method_title': shippingMethod != null
                  ? (shippingMethod.methodTitle.isNotEmpty
                      ? shippingMethod.methodTitle
                      : shippingMethod.title)
                  : 'Flat Rate',
              'instance_id': shippingMethod?.instanceId ??
                  int.tryParse(shippingMethodId ?? '') ??
                  0,
              'total': (shippingTotal ?? 0).toStringAsFixed(2),
            }
          ],
        if (customerNote != null && customerNote.isNotEmpty)
          'customer_note': customerNote,
        if (customerId != null) 'customer_id': customerId,
      };

      final uri = Uri.parse('$_baseUrl/wp-json/wc/v3/orders');
      final response = await http
          .post(
            uri,
            headers: _generateAuthHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('Create order response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final orderData = json.decode(response.body);
        print('Order created: #${orderData['number']}');
        return WooOrder.fromJson(orderData);
      } else {
        print('Create order failed: ${response.statusCode}\n${response.body}');
        return null;
      }
    } catch (e) {
      print('createOrder error: $e');
      return null;
    }
  }

  // ─── ALIAS ───────────────────────────────────────────────────────────────

  Future<bool> testConnection() async {
    final result = await testWooCommerceConnection();
    return result['success'] == true;
  }
} 