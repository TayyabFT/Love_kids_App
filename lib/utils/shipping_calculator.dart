import '../models/woocommerce_models.dart';

/// Computes cart shipping from WooCommerce product data and zone shipping methods.
class ShippingCalculator {
  ShippingCalculator._();

  static double calculate({
    required List<WooCartItem> cartItems,
    WooShippingMethod? selectedMethod,
  }) {
    if (cartItems.isEmpty) return 0;

    if (selectedMethod?.methodId == 'free_shipping') {
      return 0;
    }

    final itemCount = cartItems.fold(0, (sum, item) => sum + item.quantity);

    // 1. Per-product shipping costs stored on the product (meta / attributes).
    double productShippingTotal = 0;
    var hasProductShipping = false;
    for (final item in cartItems) {
      final unitCost = item.product.unitShippingCost;
      if (unitCost != null) {
        hasProductShipping = true;
        productShippingTotal += unitCost * item.quantity;
      }
    }
    if (hasProductShipping) {
      return productShippingTotal;
    }

    // 2. Shipping-class costs from the selected zone method.
    if (selectedMethod != null) {
      double classShippingTotal = 0;
      var hasClassShipping = false;
      for (final item in cartItems) {
        final unitCost = selectedMethod.classCostForProduct(item.product);
        if (unitCost != null) {
          hasClassShipping = true;
          classShippingTotal += unitCost * item.quantity;
        }
      }
      if (hasClassShipping) {
        return classShippingTotal;
      }

      // 3. Order-level flat rate from the shipping method settings.
      final methodCost = selectedMethod.orderLevelCost(itemCount: itemCount);
      if (methodCost != null) {
        return methodCost;
      }
    }

    return 0;
  }
}
