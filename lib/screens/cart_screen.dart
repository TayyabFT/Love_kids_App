import 'dart:async';

import 'package:flutter/material.dart';
import '../models/woocommerce_models.dart';
import '../services/cart_service.dart';
import '../services/woocommerce_service.dart';
import '../services/stripe_service.dart';
import 'track_order_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final WooCommerceService _wooService = WooCommerceService();
  final bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_updateCart);
    _cartService.initializeWooCommerceData();
  }

  @override
  void dispose() {
    _cartService.removeListener(_updateCart);
    super.dispose();
  }

  void _updateCart() {
    setState(() {});
  }

  void _updateQuantity(WooCartItem item, int change) {
    if (change > 0) {
      _cartService.incrementQuantity(item.product.id);
    } else {
      _cartService.decrementQuantity(item.product.id);
    }
  }

  void _removeItem(WooCartItem item) {
    _cartService.removeFromCart(item.product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.product.name} removed from cart'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _proceedToCheckout() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckoutBottomSheet(
        cartItems: _cartService.cartItems,
        onOrderComplete: () {
          _cartService.clearCart();
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TrackOrderScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartService.cartItems;
    final cartSummary = _cartService.getCartSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF8E8D0),
      appBar: AppBar(
        title: Text(
          'Your Cart (${cartItems.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF9A826),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _cartService.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(cartItems, cartSummary),
      bottomNavigationBar: cartItems.isEmpty ? null : _buildCheckoutBar(cartSummary),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some amazing products to start shopping',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9A826),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(List<WooCartItem> cartItems, Map<String, dynamic> cartSummary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cartItems.map((item) => CartItemCard(
              item: item,
              onIncrement: () => _updateQuantity(item, 1),
              onDecrement: () => _updateQuantity(item, -1),
              onRemove: () => _removeItem(item),
            )),
        const SizedBox(height: 16),
        _buildOrderSummary(cartSummary),
      ],
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> cartSummary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', '\$${cartSummary['subtotal'].toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Shipping', cartSummary['shipping'] == 0 ? 'Free' : '\$${cartSummary['shipping'].toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax', '\$${cartSummary['tax'].toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            '\$${cartSummary['total'].toStringAsFixed(2)}',
            isTotal: true,
          ),
          if (cartSummary['shipping'] == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'You qualify for FREE shipping! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF2D3748) : const Color(0xFF718096),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: isTotal ? const Color(0xFFF9A826) : const Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(Map<String, dynamic> cartSummary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
              Text(
                '\$${cartSummary['total'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF9A826),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessingOrder ? null : _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A826),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessingOrder
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final WooCartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.product.images.isNotEmpty ? item.product.images.first.src : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade400,
                          size: 40,
                        );
                      },
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (item.product.onSale) ...[
                      Text(
                        '\$${item.product.regularPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '\$${item.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF9A826),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: onDecrement,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Text(
                              item.quantity.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onIncrement,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Total Price and Remove Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: onRemove,
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutBottomSheet extends StatefulWidget {
  final List<WooCartItem> cartItems;
  final VoidCallback onOrderComplete;

  const CheckoutBottomSheet({
    super.key,
    required this.cartItems,
    required this.onOrderComplete,
  });

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final WooCommerceService _wooService = WooCommerceService();
  final CartService _cartService = CartService();
  
  bool _isProcessing = false;
  final bool _sameAsShipping = true;
  bool _isLoadingTotals = false;
  bool _isInitializing = true;
  Timer? _totalsDebounce;

  // Billing Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController(text: 'US');
  final _couponController = TextEditingController();
  final _customerNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    setState(() {
      _isInitializing = true;
    });
    
    print('Starting checkout initialization...');
    await _cartService.initializeWooCommerceData();
    
    print('Payment methods available: ${_cartService.paymentMethods.length}');
    for (final method in _cartService.paymentMethods) {
      print('- ${method.id}: ${method.title}');
    }
    
    print('Shipping methods available: ${_cartService.shippingMethods.length}');
    for (final method in _cartService.shippingMethods) {
      print('- ${method.methodId}: ${method.title}');
    }
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
    
    _calculateTotals();
  }

  void _scheduleTotalsRecalculation() {
    _totalsDebounce?.cancel();
    _totalsDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _calculateTotals(fromTyping: true);
    });
  }

  @override
  void dispose() {
    _totalsDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _couponController.dispose();
    _customerNoteController.dispose();
    super.dispose();
  }

  Future<void> _calculateTotals({bool fromTyping = false}) async {
    final country = _countryController.text.isNotEmpty ? _countryController.text : 'US';
    final state = _stateController.text.isNotEmpty ? _stateController.text : 'CA';
    final postcode = _zipController.text.isNotEmpty ? _zipController.text : '90210';

    // Avoid rebuilding the whole form on every keystroke — that disconnects the keyboard.
    if (mounted && !fromTyping) {
      setState(() => _isLoadingTotals = true);
    }

    print('Calculating totals for: $country, $state, $postcode');
    print('Cart items: ${widget.cartItems.length}');
    print('Total quantity: ${_cartService.itemCount}');

    await _cartService.calculateTotals(
      country: country,
      state: state,
      postcode: postcode,
      notify: !fromTyping,
    );

    final subtotal = _cartService.getSubtotal();
    final shipping = _cartService.getShippingCost();
    final tax = _cartService.getTaxAmount();
    final total = _cartService.getTotalWithShippingAndTax();

    print('Calculated totals:');
    print('- Subtotal: \$${subtotal.toStringAsFixed(2)}');
    print('- Shipping: \$${shipping.toStringAsFixed(2)}');
    print('- Tax: \$${tax.toStringAsFixed(2)}');
    print('- Total: \$${total.toStringAsFixed(2)}');

    if (mounted) {
      setState(() => _isLoadingTotals = false);
    }
  }

  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) return;

    print('Applying coupon: $couponCode');
    final success = await _cartService.applyCoupon(couponCode);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon applied successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _calculateTotals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeCoupon() {
    _cartService.removeCoupon();
    _couponController.clear();
    _calculateTotals();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coupon removed'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateRequired(String? value, String fieldLabel) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldLabel';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final required = _validateRequired(value, 'email');
    if (required != null) return required;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final required = _validateRequired(value, 'phone number');
    if (required != null) return required;
    final digitsOnly = value!.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return null;
    }
    if (digitsOnly.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateZip(String? value) {
    final required = _validateRequired(value, 'ZIP code');
    if (required != null) return required;
    final zip = value!.trim();
    final country = _countryController.text.trim().toUpperCase();
    if (country.isEmpty || country == 'US') {
      if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(zip)) {
        return 'Please enter a valid US ZIP code (e.g., 12345 or 12345-6789)';
      }
    }
    return null;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all required fields before paying.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final paymentMethodId = _cartService.selectedPaymentMethodId;

    if (!WooCommerceService.isAllowedPaymentGateway(paymentMethodId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Only credit card, debit card, and bank account payments are supported.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isProcessing = true);
    try {
      final total = _cartService.getTotalWithShippingAndTax();
      print('Launching Stripe sheet for \$${total.toStringAsFixed(2)}...');

      final stripeResult = await StripeService.processPayment(
        planType: 'product_purchase',
        amount: total,
      );

      if (stripeResult.cancelled) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (!stripeResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment failed: ${stripeResult.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
          setState(() => _isProcessing = false);
        }
        return;
      }

      print('Stripe payment OK: ${stripeResult.paymentIntentId}');
      final billing = WooBilling(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        company: '',
        address1: _addressController.text.trim(),
        address2: '',
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postcode: _zipController.text.trim(),
        country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : 'US',
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      final shipping = WooShipping(
        firstName: billing.firstName,
        lastName: billing.lastName,
        company: '',
        address1: billing.address1,
        address2: '',
        city: billing.city,
        state: billing.state,
        postcode: billing.postcode,
        country: billing.country,
      );

      WooCustomer? customer = _emailController.text.isNotEmpty
          ? await _wooService.getCustomerByEmail(_emailController.text)
          : null;

      final order = await _wooService.createOrder(
        cartItems: widget.cartItems,
        billing: billing,
        shipping: shipping,
        paymentMethod: 'stripe',
        paymentMethodTitle: 'Credit / Debit Card / Bank Account (Stripe)',
        couponCode: _cartService.appliedCouponCode.isNotEmpty ? _cartService.appliedCouponCode : null,
        shippingMethodId: _cartService.selectedShippingMethodId.isNotEmpty ? _cartService.selectedShippingMethodId : null,
        shippingMethod: _cartService.getSelectedShippingMethod(),
        shippingTotal: _cartService.getShippingCost(),
        customerNote: _customerNoteController.text.isNotEmpty ? _customerNoteController.text : null,
        customerId: customer?.id,
        metaData: {'stripe_payment_intent_id': stripeResult.paymentIntentId ?? ''},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(order != null
              ? 'Order #${order.number} placed — Payment received! 🎉'
              : 'Payment received! Our team will confirm your order shortly.'),
          backgroundColor: order != null ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        widget.onOrderComplete();
      }
    } catch (e) {
      print('Stripe payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading payment and shipping options...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Debug info
                if (_cartService.paymentMethods.isNotEmpty || _cartService.shippingMethods.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'WooCommerce Connected: ${_cartService.paymentMethods.length} payment methods, ${_cartService.shippingMethods.length} shipping methods',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Billing Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => _validateRequired(value, 'first name'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => _validateRequired(value, 'last name'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _addressController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Address *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => _validateRequired(value, 'address'),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'City *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => _validateRequired(value, 'city'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _stateController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'State *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => _validateRequired(value, 'state'),
                                  onChanged: (_) => _scheduleTotalsRecalculation(),
                                  onEditingComplete: () => _calculateTotals(fromTyping: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _zipController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'ZIP Code *',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: _validateZip,
                                  onChanged: (_) => _scheduleTotalsRecalculation(),
                                  onEditingComplete: () => _calculateTotals(fromTyping: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _countryController,
                                  decoration: const InputDecoration(
                                    labelText: 'Country',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                                  onChanged: (_) => _scheduleTotalsRecalculation(),
                                  onEditingComplete: () => _calculateTotals(fromTyping: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Coupon Section
                          const Text(
                            'Coupon Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _couponController,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter coupon code',
                                    border: OutlineInputBorder(),
                                  ),
                                  enabled: _cartService.appliedCouponCode.isEmpty,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_cartService.appliedCouponCode.isEmpty)
                                ElevatedButton(
                                  onPressed: _applyCoupon,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF9A826),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Apply'),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _removeCoupon,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                          if (_cartService.appliedCouponCode.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Coupon "${_cartService.appliedCouponCode}" applied',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Payment Method Selection
                          if (_cartService.paymentMethods.isNotEmpty) ...[
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_cartService.paymentMethods.map((method) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: RadioListTile<String>(
                                title: Row(
                                  children: [
                                    _getPaymentMethodIcon(method.id),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(method.title)),
                                  ],
                                ),
                                subtitle: method.description.isNotEmpty ? Text(method.description, style: const TextStyle(fontSize: 12)) : null,
                                value: method.id,
                                groupValue: _cartService.selectedPaymentMethodId,
                                onChanged: (value) {
                                  if (value != null) {
                                    print('Selected payment method: $value');
                                    _cartService.setSelectedPaymentMethod(value);
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                },
                              ),
                            ))),
                            const SizedBox(height: 16),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade600),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Card and bank payments are unavailable right now. Please try again later.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Shipping Method Selection
                          if (_cartService.shippingMethods.isNotEmpty) ...[
                            const Text(
                              'Shipping Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_cartService.shippingMethods.map((method) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: RadioListTile<String>(
                                title: Text(_getCleanShippingTitle(method)),
                                subtitle: Text(method.getCleanDescription(), style: const TextStyle(fontSize: 12)),
                                value: method.instanceId.toString(),
                                groupValue: _cartService.selectedShippingMethodId,
                                onChanged: (value) {
                                  if (value != null) {
                                    print('Selected shipping method: $value');
                                    _cartService.setSelectedShippingMethod(value);
                                    _calculateTotals();
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                },
                              ),
                            ))),
                            const SizedBox(height: 16),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange.shade600),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'No shipping methods found in WooCommerce. Using standard shipping.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Customer Note
                          TextFormField(
                            controller: _customerNoteController,
                            decoration: const InputDecoration(
                              labelText: 'Order Notes (Optional)',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          
                          // Order Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Order Summary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_isLoadingTotals)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...widget.cartItems.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity}x ${item.product.name}',
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '\$${item.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const Divider(),
                                _buildSummaryRow('Subtotal', '\$${_cartService.getSubtotal().toStringAsFixed(2)}'),
                                if (_cartService.getShippingCost() > 0)
                                  _buildSummaryRow('Shipping', '\$${_cartService.getShippingCost().toStringAsFixed(2)}'),
                                if (_cartService.getTaxAmount() > 0)
                                  _buildSummaryRow('Tax', '\$${_cartService.getTaxAmount().toStringAsFixed(2)}'),
                                if (_cartService.getDiscountAmount() > 0)
                                  _buildSummaryRow('Discount', '-\$${_cartService.getDiscountAmount().toStringAsFixed(2)}', textColor: Colors.green),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${_cartService.getTotalWithShippingAndTax().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF9A826),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Place Order Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cartService.selectedPaymentMethodId == 'stripe'
                            ? Colors.purple.shade600
                            : const Color(0xFFF9A826),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _cartService.selectedPaymentMethodId == 'stripe'
                                      ? Icons.credit_card
                                      : Icons.shopping_bag,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _cartService.selectedPaymentMethodId == 'stripe'
                                      ? 'Pay with Card 💳'
                                      : 'Place Order',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _getPaymentMethodIcon(String methodId) {
    switch (methodId.toLowerCase()) {
      case 'stripe':
      case 'credit_card':
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.credit_card, color: Colors.purple.shade700, size: 20),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.payment, color: Colors.grey.shade700, size: 20),
        );
    }
  }

  String _getCleanShippingTitle(WooShippingMethod method) {
    // If the title is clean, use it
    if (method.title.length <= 30 && !method.title.toLowerCase().contains('cost') && !method.title.toLowerCase().contains('code')) {
      return method.title;
    }
    
    // Otherwise, create a clean title based on method type
    if (method.methodId == 'free_shipping') {
      return 'Free Shipping';
    } else if (method.methodId == 'flat_rate') {
      return 'Flat Rate Shipping';
    } else if (method.methodId == 'local_pickup') {
      return 'Local Pickup';
    } else {
      return 'Standard Shipping';
    }
  }

  String _getShippingDescription(WooShippingMethod method) {
    // Try to extract clean cost from different possible locations
    String cost = '';
    
    // Check direct cost field
    if (method.settings['cost'] != null) {
      final costValue = method.settings['cost'];
      if (costValue is String) {
        cost = costValue;
      } else if (costValue is Map) {
        // Cost might be nested in a map with 'value' field
        cost = costValue['value']?.toString() ?? '';
      } else {
        cost = costValue.toString();
      }
    }
    
    // Clean up cost string - remove any HTML tags or complex configurations
    cost = cost.replaceAll(RegExp(r'<[^>]*>'), '');
    cost = cost.replaceAll(RegExp(r'[^0-9.]'), '');
    
    if (method.methodId == 'free_shipping') {
      return 'Free shipping to your location';
    } else if (cost.isNotEmpty && cost != '0' && double.tryParse(cost) != null) {
      final costAmount = double.parse(cost);
      return 'Shipping cost: \$${costAmount.toStringAsFixed(2)}';
    } else {
      // Return a simple description based on method type
      switch (method.methodId) {
        case 'flat_rate':
          return 'Standard flat rate shipping';
        case 'local_pickup':
          return 'Pick up from store location';
        default:
          return 'Shipping cost calculated at checkout';
      }
    }
  }

  Widget _buildSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}