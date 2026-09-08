import 'package:flutter/material.dart';

class TrackOrderScreen extends StatefulWidget {
  final String? orderId;
  
  const TrackOrderScreen({super.key, this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  bool _isTracking = false;
  bool _isOrderFound = false;
  String _currentStatus = '';
  int _statusIndex = 0;
  
  // Sample order data - in a real app, this would come from an API
  final Map<String, Map<String, dynamic>> _sampleOrders = {
    'SLK-1234': {
      'status': 'Shipped',
      'statusIndex': 2,
      'date': '04/15/2025',
      'estimatedDelivery': '04/22/2025',
      'items': [
        {
          'name': 'Kyle & Baby Danielle Dolls',
          'quantity': 1,
          'price': 79.95,
          'image': 'assets/images/product1.jpg',
        },
        {
          'name': 'SAY IT NOW WITH SELF LOVE KIDS LLC HOODIE (BLUE)',
          'quantity': 2,
          'price': 37.95,
          'image': 'assets/images/product6.png',
        },
      ],
      'shipping': {
        'address': '123 Main St, Anytown, CA 90210',
        'method': 'Standard Shipping',
      }
    },
    'SLK-5678': {
      'status': 'Processing',
      'statusIndex': 1,
      'date': '04/17/2025',
      'estimatedDelivery': '04/25/2025',
      'items': [
        {
          'name': 'Pre-Order Kylie Say It Now with Self-Love Kids Affirmation Plush Talking Doll (Purple)',
          'quantity': 1,
          'price': 99.95,
          'image': 'assets/images/product5.png',
        },
      ],
      'shipping': {
        'address': '456 Oak Ave, Somewhere, NY 10001',
        'method': 'Express Shipping',
      }
    },
  };

  final List<String> _statusSteps = [
    'Order Placed',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered'
  ];
  
  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _orderIdController.text = widget.orderId!;
      _trackOrder();
    }
  }
  
  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }
  
  void _trackOrder() {
    final orderId = _orderIdController.text.trim();
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an order ID')),
      );
      return;
    }
    
    setState(() {
      _isTracking = true;
    });
    
    // Simulate API call delay
    Future.delayed(const Duration(seconds: 1), () {
      if (_sampleOrders.containsKey(orderId)) {
        setState(() {
          _isOrderFound = true;
          _currentStatus = _sampleOrders[orderId]!['status'] as String;
          _statusIndex = _sampleOrders[orderId]!['statusIndex'] as int;
        });
      } else {
        setState(() {
          _isOrderFound = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order not found. Please check the order ID.')),
        );
      }
      
      setState(() {
        _isTracking = false;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8D0),
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF9A826),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrackingInput(),
              const SizedBox(height: 24),
              if (_isOrderFound) _buildOrderDetails(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTrackingInput() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your order ID',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can find your order ID in the confirmation email',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orderIdController,
              decoration: InputDecoration(
                hintText: 'e.g., SLK-1234',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF9A826)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFF9A826),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTracking ? null : _trackOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A826),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: const Color(0xFFF9A826).withValues(alpha: 0.5),
                ),
                child: _isTracking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Track Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Try with sample order IDs: SLK-1234 or SLK-5678',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF718096),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderDetails() {
    final orderId = _orderIdController.text.trim();
    final orderData = _sampleOrders[orderId]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tracking Status
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tracking Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_statusIndex),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTrackingSteps(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Date: ${orderData['date']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                    Text(
                      'Est. Delivery: ${orderData['estimatedDelivery']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Order Summary
        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        
        // Order Items
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Items: ${(orderData['items'] as List).length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...(orderData['items'] as List).map<Widget>((item) => _buildOrderItem(item)),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Shipping Information
        const Text(
          'Shipping Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  orderData['shipping']['address'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Shipping Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  orderData['shipping']['method'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Need Help Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // In a real app, this would navigate to a help screen or open a chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support feature would go here')),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Need Help With Your Order?'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF9A826),
              side: const BorderSide(color: Color(0xFFF9A826)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildTrackingSteps() {
    return Row(
      children: List.generate(_statusSteps.length, (index) {
        final bool isActive = index <= _statusIndex;
        final bool isLast = index == _statusSteps.length - 1;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFF9A826) : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getStatusIcon(index),
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusSteps[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? const Color(0xFF2D3748) : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < _statusIndex ? const Color(0xFFF9A826) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item['image'] as String,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item['quantity']} × \$${(item['price'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: \$${((item['quantity'] as int) * (item['price'] as double)).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getStatusIcon(int index) {
    switch (index) {
      case 0:
        return Icons.receipt_outlined;
      case 1:
        return Icons.inventory_2_outlined;
      case 2:
        return Icons.local_shipping_outlined;
      case 3:
        return Icons.delivery_dining_outlined;
      case 4:
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }
  
  Color _getStatusColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return const Color(0xFFF9A826);
      case 3:
        return Colors.purple;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}