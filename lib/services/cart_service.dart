import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/woocommerce_models.dart';
import '../utils/shipping_calculator.dart';
import 'woocommerce_service.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<WooCartItem> _cartItems = [];
  final WooCommerceService _wooService = WooCommerceService();
  
  // WooCommerce data cache
  List<WooPaymentMethod> _paymentMethods = [];
  List<WooShippingMethod> _shippingMethods = [];
  WooOrderTotals? _currentTotals;
  WooCustomer? _currentCustomer;
  String _selectedShippingMethodId = '';
  String _selectedPaymentMethodId = 'stripe';
  String _appliedCouponCode = '';

  List<WooCartItem> get cartItems => List.unmodifiable(_cartItems);
  List<WooPaymentMethod> get paymentMethods => _paymentMethods;
  List<WooShippingMethod> get shippingMethods => _shippingMethods;
  WooOrderTotals? get currentTotals => _currentTotals;
  WooCustomer? get currentCustomer => _currentCustomer;
  String get selectedShippingMethodId => _selectedShippingMethodId;
  String get selectedPaymentMethodId => _selectedPaymentMethodId;
  String get appliedCouponCode => _appliedCouponCode;
  
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Initialize WooCommerce data
  Future<void> initializeWooCommerceData() async {
    try {
      print('Initializing WooCommerce data...');
      
      // Test connection first
      print('Testing WooCommerce API connection...');
      final connectionTest = await _wooService.testConnection();
      if (!connectionTest) {
        print('⚠️ WooCommerce API connection failed, using fallback methods');
        _useFallbackMethods();
        return;
      }
      
      // Fetch payment methods
      print('Fetching payment methods...');
      _paymentMethods = await _wooService.getPaymentMethods();
      print('Loaded ${_paymentMethods.length} approved payment methods');
      if (_paymentMethods.isNotEmpty &&
          !WooCommerceService.isAllowedPaymentGateway(_selectedPaymentMethodId)) {
        _selectedPaymentMethodId = _paymentMethods.first.id;
      }
      
      // Fetch shipping methods
      print('Fetching shipping methods...');
      _shippingMethods = await _wooService.getShippingMethods();
      print('Loaded ${_shippingMethods.length} shipping methods');
      
      // Set default payment method
      if (_paymentMethods.isNotEmpty && _selectedPaymentMethodId.isEmpty) {
        _selectedPaymentMethodId = _paymentMethods.first.id;
        print('Set default payment method: $_selectedPaymentMethodId');
      }
      
      // Set default shipping method
      if (_shippingMethods.isNotEmpty && _selectedShippingMethodId.isEmpty) {
        _selectedShippingMethodId = _shippingMethods.first.instanceId.toString();
        print('Set default shipping method: $_selectedShippingMethodId');
      }
      
      print('WooCommerce initialization complete');
      notifyListeners();
    } catch (e) {
      print('Error initializing WooCommerce data: $e');
      _useFallbackMethods();
    }
  }

  void _useFallbackMethods() {
    // Ensure we have fallback methods even if initialization fails
    if (_paymentMethods.isEmpty) {
      _paymentMethods = [
        WooPaymentMethod(
          id: 'stripe',
          title: 'Credit / Debit Card / Bank Account',
          description: 'Pay securely with card or bank account via Stripe',
          order: 0,
          enabled: true,
          settings: {},
        ),
      ];
      _selectedPaymentMethodId = 'stripe';
    }
    
    if (_shippingMethods.isEmpty) {
      _shippingMethods = [
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
      _selectedShippingMethodId = '1';
    }
    
    notifyListeners();
  }

  // Add item to cart
  void addToCart(WooProduct product, {int quantity = 1}) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex >= 0) {
      // Update quantity if item already exists
      _cartItems[existingItemIndex].quantity += quantity;
    } else {
      // Add new item
      _cartItems.add(WooCartItem(product: product, quantity: quantity));
    }
    
    // Clear current totals to force recalculation
    _currentTotals = null;
    notifyListeners();
    _saveCartToStorage();
  }

  // Remove item from cart
  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    // Clear current totals to force recalculation
    _currentTotals = null;
    notifyListeners();
    _saveCartToStorage();
  }

  // Update item quantity
  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final itemIndex = _cartItems.indexWhere(
      (item) => item.product.id == productId,
    );

    if (itemIndex >= 0) {
      _cartItems[itemIndex].quantity = newQuantity;
      // Clear current totals to force recalculation
      _currentTotals = null;
      notifyListeners();
      _saveCartToStorage();
    }
  }

  // Increase quantity by 1
  void incrementQuantity(int productId) {
    final itemIndex = _cartItems.indexWhere(
      (item) => item.product.id == productId,
    );

    if (itemIndex >= 0) {
      _cartItems[itemIndex].quantity++;
      _currentTotals = null;
      notifyListeners();
      _saveCartToStorage();
    }
  }

  // Decrease quantity by 1
  void decrementQuantity(int productId) {
    final itemIndex = _cartItems.indexWhere(
      (item) => item.product.id == productId,
    );

    if (itemIndex >= 0) {
      if (_cartItems[itemIndex].quantity > 1) {
        _cartItems[itemIndex].quantity--;
      } else {
        removeFromCart(productId);
        return;
      }
      _currentTotals = null;
      notifyListeners();
      _saveCartToStorage();
    }
  }

  // Check if product is in cart
  bool isInCart(int productId) {
    return _cartItems.any((item) => item.product.id == productId);
  }

  // Get quantity of specific product in cart
  int getProductQuantity(int productId) {
    final item = _cartItems.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => WooCartItem(
        product: WooProduct(
          id: 0,
          name: '',
          description: '',
          shortDescription: '',
          sku: '',
          price: 0,
          regularPrice: 0,
          salePrice: 0,
          onSale: false,
          status: '',
          images: [],
          categories: [],
          attributes: [],
          stockQuantity: 0,
          inStock: false,
          stockStatus: '',
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Set customer for order calculations
  void setCustomer(WooCustomer customer) {
    _currentCustomer = customer;
    notifyListeners();
  }

  // Set selected shipping method
  void setSelectedShippingMethod(String methodId) {
    _selectedShippingMethodId = methodId;
    // Clear current totals to force recalculation with new shipping method
    _currentTotals = null;
    notifyListeners();
  }

  // Set selected payment method
  void setSelectedPaymentMethod(String methodId) {
    _selectedPaymentMethodId = methodId;
    notifyListeners();
  }

  // Apply coupon code
  Future<bool> applyCoupon(String couponCode) async {
    try {
      final coupon = await _wooService.validateCoupon(couponCode);
      if (coupon != null) {
        _appliedCouponCode = couponCode;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error applying coupon: $e');
      return false;
    }
  }

  // Remove applied coupon
  void removeCoupon() {
    _appliedCouponCode = '';
    _currentTotals = null;
    notifyListeners();
  }

  // Calculate totals using WooCommerce
  Future<void> calculateTotals({
    required String country,
    required String state,
    required String postcode,
    bool notify = true,
  }) async {
    if (_cartItems.isEmpty) {
      _currentTotals = null;
      if (notify) notifyListeners();
      return;
    }

    try {
      _currentTotals = await _wooService.calculateOrderTotals(
        cartItems: _cartItems,
        country: country,
        state: state,
        postcode: postcode,
        couponCode: _appliedCouponCode.isNotEmpty ? _appliedCouponCode : null,
        shippingMethodId:
            _selectedShippingMethodId.isNotEmpty ? _selectedShippingMethodId : null,
        shippingMethods: _shippingMethods,
      );
      if (notify) notifyListeners();
    } catch (e) {
      print('Error calculating totals: $e');
    }
  }

  // Clear cart
  void clearCart() {
    _cartItems.clear();
    _currentTotals = null;
    _appliedCouponCode = '';
    notifyListeners();
    _saveCartToStorage();
  }

  // Get cart as JSON for storage
  String _cartToJson() {
    return jsonEncode({
      'items': _cartItems.map((item) => {
        'product': item.product.toJson(),
        'quantity': item.quantity,
      }).toList(),
      'selected_shipping_method': _selectedShippingMethodId,
      'selected_payment_method': _selectedPaymentMethodId,
      'applied_coupon': _appliedCouponCode,
    });
  }

  // Load cart from JSON
  void _loadCartFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> items = data['items'] ?? [];
      
      _cartItems.clear();
      for (final item in items) {
        final product = WooProduct.fromJson(item['product']);
        final quantity = item['quantity'] as int;
        _cartItems.add(WooCartItem(product: product, quantity: quantity));
      }
      
      _selectedShippingMethodId = data['selected_shipping_method'] ?? '';
      _selectedPaymentMethodId = data['selected_payment_method'] ?? 'stripe';
      if (!WooCommerceService.isAllowedPaymentGateway(_selectedPaymentMethodId)) {
        _selectedPaymentMethodId = 'stripe';
      }
      _appliedCouponCode = data['applied_coupon'] ?? '';
      
      notifyListeners();
    } catch (e) {
      print('Error loading cart from storage: $e');
    }
  }

  // Save cart to local storage (implement based on your preference)
  void _saveCartToStorage() {
    // For now, just save to memory
    // In a real app, you might use shared_preferences or secure storage
    final cartJson = _cartToJson();
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setString('cart_data', cartJson);
    // });
  }

  // Load cart from local storage
  void loadCart() {
    // In a real app, load from shared_preferences
    // SharedPreferences.getInstance().then((prefs) {
    //   final cartJson = prefs.getString('cart_data');
    //   if (cartJson != null) {
    //     _loadCartFromJson(cartJson);
    //   }
    // });
  }

  double getShippingCost() {
    if (_currentTotals != null) {
      return _currentTotals!.shippingTotal;
    }
    return ShippingCalculator.calculate(
      cartItems: _cartItems,
      selectedMethod: getSelectedShippingMethod(),
    );
  }

  // Calculate tax (uses WooCommerce data or fallback to 10% calculation)
  double getTaxAmount() {
    // If WooCommerce returns valid tax, use it
    if (_currentTotals != null && _currentTotals!.taxTotal > 0) {
      return _currentTotals!.taxTotal;
    }
    
    // Otherwise calculate 10% tax on subtotal + shipping
    final subtotal = getSubtotal();
    final shipping = getShippingCost();
    final taxableAmount = subtotal + shipping;
    return taxableAmount * 0.10; // 10% tax rate
  }

  // Get discount amount
  double getDiscountAmount() {
    return _currentTotals?.discountTotal ?? 0.0;
  }

  // Get subtotal
  double getSubtotal() {
    return _currentTotals?.subtotal ?? totalAmount;
  }

  // Get total including shipping and tax (ensures proper calculation)
  double getTotalWithShippingAndTax() {
    final subtotal = getSubtotal();
    final shipping = getShippingCost();
    final tax = getTaxAmount();
    final discount = getDiscountAmount();
    
    // Always calculate our own total to ensure shipping and tax are included
    final calculatedTotal = subtotal + shipping + tax - discount;
    
    // If WooCommerce total is available and higher (includes more fees), use it
    final wooTotal = _currentTotals?.total ?? 0.0;
    
    return calculatedTotal > wooTotal ? calculatedTotal : 
           (wooTotal > subtotal ? wooTotal : calculatedTotal);
  }

  // Get cart summary for display (enhanced with WooCommerce data)
  Map<String, dynamic> getCartSummary() {
    return {
      'subtotal': getSubtotal(),
      'shipping': getShippingCost(),
      'tax': getTaxAmount(),
      'discount': getDiscountAmount(),
      'total': getTotalWithShippingAndTax(),
      'item_count': itemCount,
      'applied_coupon': _appliedCouponCode,
      'selected_payment_method': _selectedPaymentMethodId,
      'selected_shipping_method': _selectedShippingMethodId,
    };
  }

  // Get selected payment method details
  WooPaymentMethod? getSelectedPaymentMethod() {
    return _paymentMethods.firstWhere(
      (method) => method.id == _selectedPaymentMethodId,
      orElse: () => WooPaymentMethod(
        id: 'stripe',
        title: 'Credit / Debit Card / Bank Account',
        description: 'Pay securely with card or bank account via Stripe',
        order: 0,
        enabled: true,
        settings: {},
      ),
    );
  }

  // Get selected shipping method details
  WooShippingMethod? getSelectedShippingMethod() {
    return _shippingMethods.firstWhere(
      (method) => method.instanceId.toString() == _selectedShippingMethodId,
      orElse: () => WooShippingMethod(
        instanceId: 0,
        title: 'Standard Shipping',
        order: 0,
        enabled: true,
        methodId: 'flat_rate',
        methodTitle: 'Flat Rate',
        settings: {},
      ),
    );
  }
} 