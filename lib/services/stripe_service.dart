import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  /// Only these Stripe payment method types may be offered in Payment Sheet.
  static const List<String> allowedPaymentMethodTypes = [
    'card', // credit & debit cards
    'us_bank_account', // ACH bank account (when enabled in Stripe Dashboard)
  ];

  // Stripe live keys, loaded from .env (see .env.example)
  static String get _publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  static String get _secretKey => dotenv.env['STRIPE_SECRET_KEY']!;

  // Pricing
  static const int monthlyPriceInCents = 795; // $7.95
  static const int yearlyPriceInCents = 7995; // $79.95

  static void init() {
    Stripe.publishableKey = _publishableKey;
    print(
      'Stripe initialized with publishable key: ${_publishableKey.substring(0, 20)}...',
    );
  }

  static String _encodePaymentIntentBody({
    required String amount,
    required String currency,
    String? planType,
  }) {
    final parts = <String>[
      'amount=${Uri.encodeComponent(amount)}',
      'currency=${Uri.encodeComponent(currency.toLowerCase())}',
      ...allowedPaymentMethodTypes.map(
        (type) =>
            '${Uri.encodeComponent('payment_method_types[]')}=${Uri.encodeComponent(type)}',
      ),
    ];
    if (planType != null) {
      parts.add(
        '${Uri.encodeComponent('metadata[plan_type]')}=${Uri.encodeComponent(planType)}',
      );
    }
    return parts.join('&');
  }

  // Create payment intent on your server
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String amount,
    required String currency,
    required String planType,
  }) async {
    try {
      print(
        'Creating payment intent for amount: $amount, currency: $currency, '
        'plan: $planType, methods: $allowedPaymentMethodTypes',
      );

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _encodePaymentIntentBody(
          amount: amount,
          currency: currency,
          planType: planType,
        ),
      );

      print('Stripe API response status: ${response.statusCode}');
      print('Stripe API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Payment intent created successfully: ${data['id']}');
        return data;
      } else {
        // Parse error response
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        throw StripeException(
          'Stripe API Error (${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      if (e is StripeException) {
        rethrow;
      }
      throw StripeException('Failed to create payment intent: ${e.toString()}');
    }
  }

  // Process payment
  static Future<PaymentResult> processPayment({
    required String planType,
    required double amount,
  }) async {
    try {
      print('🔥 DETAILED PAYMENT DEBUG 🔥');
      print(
        'Starting payment process for plan: $planType, amount: \$${amount.toStringAsFixed(2)}',
      );
      print('Using publishable key: ${_publishableKey.substring(0, 30)}...');
      print('Using secret key: ${_secretKey.substring(0, 30)}...');

      // Step 1: Create payment intent
      print('\n📡 STEP 1: Creating payment intent...');
      final paymentIntent = await createPaymentIntent(
        amount: (amount * 100).toInt().toString(), // Convert to cents
        currency: 'USD',
        planType: planType,
      );

      final clientSecret = paymentIntent['client_secret'];
      final paymentIntentId = paymentIntent['id'];

      if (clientSecret == null) {
        throw StripeException('❌ No client secret received from Stripe API');
      }

      print('✅ Payment intent created successfully!');
      print('   - Payment Intent ID: $paymentIntentId');
      print('   - Client Secret: ${clientSecret.substring(0, 30)}...');

      // Step 2: Initialize payment sheet
      print('\n🔧 STEP 2: Initializing payment sheet...');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          merchantDisplayName: 'Say It Now Self-Love Kids',
          customFlow: false,
          setupIntentClientSecret: null,
          allowsDelayedPaymentMethods: false,
          paymentMethodOrder: List<String>.from(allowedPaymentMethodTypes),
        ),
      );

      print('✅ Payment sheet initialized successfully!');

      // Step 3: Present payment sheet
      print('\n💳 STEP 3: Presenting payment sheet to user (live mode)...');

      await Stripe.instance.presentPaymentSheet();

      print('🎉 PAYMENT COMPLETED SUCCESSFULLY! 🎉');
      print('Payment Intent ID: $paymentIntentId');

      return PaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
        message: 'Payment completed successfully!',
      );
    } on StripeException catch (e) {
      print('❌ STRIPE EXCEPTION: $e');
      // Check if it's a user cancellation
      if (e.toString().toLowerCase().contains('cancel') ||
          e.toString().toLowerCase().contains('user')) {
        print('👤 User cancelled the payment');
        return PaymentResult(
          success: false,
          cancelled: true,
          message: 'Payment was cancelled by user',
        );
      }
      print('💥 Payment failed with Stripe error');
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    } on Exception catch (e) {
      print('❌ FLUTTER STRIPE EXCEPTION: $e');
      // Check for common user cancellation patterns
      if (e.toString().toLowerCase().contains('cancel') ||
          e.toString().toLowerCase().contains('abort') ||
          e.toString().toLowerCase().contains('user')) {
        print('👤 User cancelled the payment');
        return PaymentResult(
          success: false,
          cancelled: true,
          message: 'Payment was cancelled by user',
        );
      }
      print('💥 Payment failed with Flutter error');
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    } catch (e) {
      print('❌ UNEXPECTED PAYMENT ERROR: $e');
      print('Error type: ${e.runtimeType}');
      return PaymentResult(
        success: false,
        message: 'Payment failed: ${e.toString()}',
      );
    }
  }

  // Get plan details
  static Map<String, dynamic> getMonthlyPlan() {
    return {
      'title': 'Monthly Plan',
      'price': 7.95,
      'priceDisplay': '\$7.95',
      'billingPeriod': 'per month',
      'planType': 'monthly',
      'features': [
        'Access to all educational games',
        'Digital affirmation cards',
        'Reading comprehension quizzes',
        'Task management system',
        'Monthly progress reports',
      ],
    };
  }

  static Map<String, dynamic> getYearlyPlan() {
    return {
      'title': 'Yearly Plan',
      'price': 79.95,
      'priceDisplay': '\$79.95',
      'billingPeriod': 'per year (2 months free)',
      'originalPrice': '\$95.40',
      'savings': 'Save \$15.45',
      'planType': 'yearly',
      'features': [
        'All monthly plan features',
        'Priority customer support',
        'Exclusive content updates',
        'Advanced analytics',
        'Family sharing (up to 4 kids)',
        '2 months completely free!',
      ],
    };
  }

  // Test Stripe connectivity
  static Future<bool> testStripeConnection() async {
    try {
      print('🧪 TESTING STRIPE CONNECTION...');

      // Try to create a minimal payment intent
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _encodePaymentIntentBody(
          amount: '100',
          currency: 'USD',
        ),
      );

      print('Test response status: ${response.statusCode}');
      print('Test response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Stripe connection successful! Test payment intent: ${data['id']}',
        );
        return true;
      } else {
        print('❌ Stripe connection failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Stripe test error: $e');
      return false;
    }
  }

  // Comprehensive payment diagnostics
  static Future<void> runDiagnostics() async {
    print('🩺 === STRIPE PAYMENT DIAGNOSTICS === 🩺');
    print('');

    // Check 1: Stripe Keys
    print('1️⃣ CHECKING STRIPE KEYS...');
    print(
      '   ✅ Publishable Key: ${_publishableKey.substring(0, 20)}... (${_publishableKey.length} chars)',
    );
    print(
      '   ✅ Secret Key: ${_secretKey.substring(0, 20)}... (${_secretKey.length} chars)',
    );
    print(
      '   ✅ Keys are in LIVE mode: ${_publishableKey.contains('live') && _secretKey.contains('live')}',
    );
    print('');

    // Check 2: Stripe Initialization
    print('2️⃣ CHECKING STRIPE INITIALIZATION...');
    try {
      Stripe.publishableKey = _publishableKey;
      print('   ✅ Stripe.publishableKey set successfully');
    } catch (e) {
      print('   ❌ Failed to set publishable key: $e');
    }
    print('');

    // Check 3: API Connectivity
    print('3️⃣ TESTING API CONNECTIVITY...');
    final connectionTest = await testStripeConnection();
    if (connectionTest) {
      print('   ✅ Stripe API is reachable and responding');
    } else {
      print('   ❌ Stripe API connection failed');
    }
    print('');

    // Check 4: Test Payment Intent
    print('4️⃣ TESTING PAYMENT INTENT CREATION...');
    try {
      final testIntent = await createPaymentIntent(
        amount: '795', // $7.95
        currency: 'USD',
        planType: 'test',
      );
      print('   ✅ Payment intent created: ${testIntent['id']}');
      print(
        '   ✅ Client secret received: ${testIntent['client_secret']?.substring(0, 30)}...',
      );
    } catch (e) {
      print('   ❌ Payment intent creation failed: $e');
    }
    print('');

    print('🩺 === DIAGNOSTICS COMPLETE === 🩺');
    print('');
    print('📋 NEXT STEPS:');
    print('1. Run your app: flutter run');
    print('2. Navigate to the payment screen');
    print('3. Try to make a payment');
    print('4. Check the console for detailed logs');
    print('5. Use test card: 4242424242424242');
    print('');
  }
}

// Custom exception for Stripe errors
class StripeException implements Exception {
  final String message;
  StripeException(this.message);

  @override
  String toString() => message;
}

// Payment result class
class PaymentResult {
  final bool success;
  final bool cancelled;
  final String? paymentIntentId;
  final String message;

  PaymentResult({
    required this.success,
    this.cancelled = false,
    this.paymentIntentId,
    required this.message,
  });
}
