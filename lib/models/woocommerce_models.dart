
// Product Model
class WooProduct {
  final int id;
  final String name;
  final String description;
  final String shortDescription;
  final String sku;
  final double price;
  final double regularPrice;
  final double salePrice;
  final bool onSale;
  final String status;
  final List<WooProductImage> images;
  final List<WooProductCategory> categories;
  final List<WooProductAttribute> attributes;
  final int stockQuantity;
  final bool inStock;
  final String stockStatus;
  final int shippingClassId;
  final String shippingClass;
  /// Per-unit shipping fee from WooCommerce product meta/attributes, when set.
  final double? shippingCost;

  WooProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDescription,
    required this.sku,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.onSale,
    required this.status,
    required this.images,
    required this.categories,
    required this.attributes,
    required this.stockQuantity,
    required this.inStock,
    required this.stockStatus,
    this.shippingClassId = 0,
    this.shippingClass = '',
    this.shippingCost,
  });

  /// Per-unit shipping from product data (null when cost comes from shipping method).
  double? get unitShippingCost => shippingCost;

  String get shippingCostLabel {
    if (shippingCost != null) {
      return shippingCost == 0 ? 'Free' : '\$${shippingCost!.toStringAsFixed(2)}';
    }
    if (shippingClassId > 0 && shippingClass.isNotEmpty) {
      return 'Based on $shippingClass shipping';
    }
    return 'Calculated at checkout';
  }

  factory WooProduct.fromJson(Map<String, dynamic> json) {
    return WooProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      sku: json['sku'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      regularPrice: double.tryParse(json['regular_price']?.toString() ?? '0') ?? 0.0,
      salePrice: double.tryParse(json['sale_price']?.toString() ?? '0') ?? 0.0,
      onSale: json['on_sale'] ?? false,
      status: json['status'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => WooProductImage.fromJson(e))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => WooProductCategory.fromJson(e))
              .toList() ??
          [],
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) => WooProductAttribute.fromJson(e))
              .toList() ??
          [],
      stockQuantity: json['stock_quantity'] ?? 0,
      inStock: json['in_stock'] ?? true,
      stockStatus: json['stock_status'] ?? 'instock',
      shippingClassId: json['shipping_class_id'] ?? 0,
      shippingClass: json['shipping_class']?.toString() ?? '',
      shippingCost: _parseShippingCostFromJson(json),
    );
  }

  static double? _parseShippingCostFromJson(Map<String, dynamic> json) {
    const metaKeys = {
      'shipping_cost',
      '_shipping_cost',
      'shipping_cost_usd',
      'product_shipping_cost',
      'shipping_fee',
      '_shipping_fee',
    };

    final meta = json['meta_data'] as List<dynamic>? ?? [];
    for (final entry in meta) {
      if (entry is! Map) continue;
      final key = entry['key']?.toString().toLowerCase() ?? '';
      if (metaKeys.contains(key) ||
          (key.contains('shipping') && key.contains('cost'))) {
        final value = _parseMoney(entry['value']);
        if (value != null) return value;
      }
    }

    final attributes = json['attributes'] as List<dynamic>? ?? [];
    for (final attr in attributes) {
      if (attr is! Map) continue;
      final name = attr['name']?.toString().toLowerCase() ?? '';
      if (!name.contains('shipping')) continue;
      final options = attr['options'] as List<dynamic>? ?? [];
      if (options.isEmpty) continue;
      final value = _parseMoney(options.first);
      if (value != null) return value;
    }

    return null;
  }

  static double? _parseMoney(dynamic raw) {
    if (raw == null) return null;
    final cleaned = raw.toString().replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'short_description': shortDescription,
      'sku': sku,
      'price': price.toString(),
      'regular_price': regularPrice.toString(),
      'sale_price': salePrice.toString(),
      'on_sale': onSale,
      'status': status,
      'images': images.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'attributes': attributes.map((e) => e.toJson()).toList(),
      'stock_quantity': stockQuantity,
      'in_stock': inStock,
      'stock_status': stockStatus,
      'shipping_class_id': shippingClassId,
      'shipping_class': shippingClass,
      if (shippingCost != null) 'shipping_cost': shippingCost,
    };
  }
}

// Product Image Model
class WooProductImage {
  final int id;
  final String src;
  final String name;
  final String alt;

  WooProductImage({
    required this.id,
    required this.src,
    required this.name,
    required this.alt,
  });

  factory WooProductImage.fromJson(Map<String, dynamic> json) {
    return WooProductImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      name: json['name'] ?? '',
      alt: json['alt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
      'name': name,
      'alt': alt,
    };
  }
}

// Product Category Model
class WooProductCategory {
  final int id;
  final String name;
  final String slug;

  WooProductCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory WooProductCategory.fromJson(Map<String, dynamic> json) {
    return WooProductCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}

// Product Attribute Model
class WooProductAttribute {
  final int id;
  final String name;
  final int position;
  final bool visible;
  final bool variation;
  final List<String> options;

  WooProductAttribute({
    required this.id,
    required this.name,
    required this.position,
    required this.visible,
    required this.variation,
    required this.options,
  });

  factory WooProductAttribute.fromJson(Map<String, dynamic> json) {
    return WooProductAttribute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? 0,
      visible: json['visible'] ?? true,
      variation: json['variation'] ?? false,
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'visible': visible,
      'variation': variation,
      'options': options,
    };
  }
}

// Cart Item Model
class WooCartItem {
  final WooProduct product;
  int quantity;

  WooCartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'quantity': quantity,
    };
  }
}

// Order Model
class WooOrder {
  final int id;
  final String number;
  final String status;
  final String currency;
  final double total;
  final String dateCreated;
  final List<WooOrderLineItem> lineItems;
  final WooBilling billing;
  final WooShipping shipping;

  WooOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.currency,
    required this.total,
    required this.dateCreated,
    required this.lineItems,
    required this.billing,
    required this.shipping,
  });

  factory WooOrder.fromJson(Map<String, dynamic> json) {
    return WooOrder(
      id: json['id'] ?? 0,
      number: json['number'] ?? '',
      status: json['status'] ?? '',
      currency: json['currency'] ?? 'USD',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      dateCreated: json['date_created'] ?? '',
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) => WooOrderLineItem.fromJson(e))
              .toList() ??
          [],
      billing: WooBilling.fromJson(json['billing'] ?? {}),
      shipping: WooShipping.fromJson(json['shipping'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'status': status,
      'currency': currency,
      'total': total.toString(),
      'date_created': dateCreated,
      'line_items': lineItems.map((e) => e.toJson()).toList(),
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
    };
  }
}

// Order Line Item Model
class WooOrderLineItem {
  final int id;
  final String name;
  final int productId;
  final int quantity;
  final double price;
  final double total;

  WooOrderLineItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory WooOrderLineItem.fromJson(Map<String, dynamic> json) {
    return WooOrderLineItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_id': productId,
      'quantity': quantity,
      'price': price.toString(),
      'total': total.toString(),
    };
  }
}

// Billing Model
class WooBilling {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  WooBilling({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.email,
    required this.phone,
  });

  factory WooBilling.fromJson(Map<String, dynamic> json) {
    return WooBilling(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'email': email,
      'phone': phone,
    };
  }
}

// Shipping Model
class WooShipping {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;

  WooShipping({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  factory WooShipping.fromJson(Map<String, dynamic> json) {
    return WooShipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
    };
  }
}

// Payment Method Model
class WooPaymentMethod {
  final String id;
  final String title;
  final String description;
  final int order;
  final bool enabled;
  final Map<String, dynamic> settings;

  WooPaymentMethod({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.enabled,
    required this.settings,
  });

  factory WooPaymentMethod.fromJson(Map<String, dynamic> json) {
    return WooPaymentMethod(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: _cleanDescription(json['description'] ?? ''),
      order: _parseIntFromStringOrInt(json['order']),
      enabled: json['enabled'] ?? false,
      settings: _parseSettings(json['settings']),
    );
  }

  static Map<String, dynamic> _parseSettings(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  static int _parseIntFromStringOrInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _cleanDescription(String description) {
    // Remove HTML tags and clean up the description
    String cleaned = description.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();
    
    // If description contains configuration text, provide a simple one
    if (cleaned.toLowerCase().contains('cost') || 
        cleaned.toLowerCase().contains('code') ||
        cleaned.toLowerCase().contains('enter a cost') ||
        cleaned.toLowerCase().contains('qty') ||
        cleaned.toLowerCase().contains('percentage') ||
        cleaned.toLowerCase().contains('configuration')) {
      return 'Secure payment processing';
    }
    
    // Limit description length for better UI
    if (cleaned.length > 100) {
      cleaned = '${cleaned.substring(0, 97)}...';
    }
    
    return cleaned.isNotEmpty ? cleaned : 'Payment method';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'enabled': enabled,
      'settings': settings,
    };
  }
}

// Shipping Method Model
class WooShippingMethod {
  final int instanceId;
  final String title;
  final int order;
  final bool enabled;
  final String methodId;
  final String methodTitle;
  final Map<String, dynamic> settings;

  WooShippingMethod({
    required this.instanceId,
    required this.title,
    required this.order,
    required this.enabled,
    required this.methodId,
    required this.methodTitle,
    required this.settings,
  });

  factory WooShippingMethod.fromJson(Map<String, dynamic> json) {
    return WooShippingMethod(
      instanceId: json['instance_id'] ?? 0,
      title: _cleanTitle(json['title'] ?? ''),
      order: _parseIntFromStringOrInt(json['order']),
      enabled: json['enabled'] ?? false,
      methodId: json['method_id'] ?? '',
      methodTitle: json['method_title'] ?? '',
      settings: _normalizeSettings(json['settings']),
    );
  }

  static Map<String, dynamic> _normalizeSettings(dynamic raw) {
    if (raw is! Map) return {};
    final normalized = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is Map && value.containsKey('value')) {
        normalized[key.toString()] = value['value'];
      } else {
        normalized[key.toString()] = value;
      }
    });
    return normalized;
  }

  static String? _settingValue(Map<String, dynamic> settings, String key) {
    final raw = settings[key];
    if (raw == null) return null;
    if (raw is Map && raw['value'] != null) {
      return raw['value'].toString();
    }
    return raw.toString();
  }

  static double? _parseNumericCost(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  /// Flat-rate cost applied once per order (WooCommerce zone method settings).
  double? orderLevelCost({required int itemCount}) {
    if (methodId == 'free_shipping') return 0;
    return _parseNumericCost(_settingValue(settings, 'cost'));
  }

  /// Per-product cost for a shipping class configured on the zone method.
  double? classCostForProduct(WooProduct product) {
    if (product.shippingClassId <= 0) {
      return _parseNumericCost(_settingValue(settings, 'no_class_cost'));
    }
    return _parseNumericCost(
      _settingValue(settings, 'class_cost_${product.shippingClassId}'),
    );
  }

  static int _parseIntFromStringOrInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _cleanTitle(String title) {
    // Remove HTML tags and clean up the title
    String cleaned = title.replaceAll(RegExp(r'<[^>]*>'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();
    
    // If title contains configuration text or is too long, return simple title
    if (cleaned.length > 50 || 
        cleaned.toLowerCase().contains('cost') || 
        cleaned.toLowerCase().contains('code') ||
        cleaned.toLowerCase().contains('enter a cost') ||
        cleaned.toLowerCase().contains('qty') ||
        cleaned.toLowerCase().contains('percentage')) {
      return 'Flat Rate Shipping';
    }
    
    return cleaned.isNotEmpty ? cleaned : 'Shipping Method';
  }

  // Get clean shipping cost from settings
  String getShippingCostDisplay() {
    final costAmount = orderLevelCost(itemCount: 1);
    if (costAmount != null && costAmount > 0) {
      return '\$${costAmount.toStringAsFixed(2)}';
    }
    if (methodId == 'free_shipping') {
      return 'Free';
    }
    return 'Calculated at checkout';
  }

  // Get clean description
  String getCleanDescription() {
    final costDisplay = getShippingCostDisplay();
    
    if (methodId == 'free_shipping') {
      return 'Free shipping to your location';
    } else if (costDisplay != 'Calculated at checkout') {
      return 'Shipping cost: $costDisplay';
    } else {
      switch (methodId) {
        case 'flat_rate':
          return 'Standard flat rate shipping';
        case 'local_pickup':
          return 'Pick up from store location';
        default:
          return 'Standard shipping rates apply';
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'instance_id': instanceId,
      'title': title,
      'order': order,
      'enabled': enabled,
      'method_id': methodId,
      'method_title': methodTitle,
      'settings': settings,
    };
  }
}

// Tax Rate Model
class WooTaxRate {
  final int id;
  final String country;
  final String state;
  final String postcode;
  final String city;
  final String rate;
  final String name;
  final int priority;
  final bool compound;
  final bool shipping;
  final int order;
  final String taxClass;

  WooTaxRate({
    required this.id,
    required this.country,
    required this.state,
    required this.postcode,
    required this.city,
    required this.rate,
    required this.name,
    required this.priority,
    required this.compound,
    required this.shipping,
    required this.order,
    required this.taxClass,
  });

  factory WooTaxRate.fromJson(Map<String, dynamic> json) {
    return WooTaxRate(
      id: json['id'] ?? 0,
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      city: json['city'] ?? '',
      rate: json['rate'] ?? '0',
      name: json['name'] ?? '',
      priority: json['priority'] ?? 1,
      compound: json['compound'] ?? false,
      shipping: json['shipping'] ?? true,
      order: json['order'] ?? 0,
      taxClass: json['class'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'state': state,
      'postcode': postcode,
      'city': city,
      'rate': rate,
      'name': name,
      'priority': priority,
      'compound': compound,
      'shipping': shipping,
      'order': order,
      'class': taxClass,
    };
  }
}

// Order Totals Model
class WooOrderTotals {
  final double subtotal;
  final double shippingTotal;
  final double taxTotal;
  final double discountTotal;
  final double total;

  WooOrderTotals({
    required this.subtotal,
    required this.shippingTotal,
    required this.taxTotal,
    required this.discountTotal,
    required this.total,
  });

  factory WooOrderTotals.fromJson(Map<String, dynamic> json) {
    return WooOrderTotals(
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      shippingTotal: double.tryParse(json['shipping_total']?.toString() ?? '0') ?? 0.0,
      taxTotal: double.tryParse(json['tax_total']?.toString() ?? '0') ?? 0.0,
      discountTotal: double.tryParse(json['discount_total']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal.toString(),
      'shipping_total': shippingTotal.toString(),
      'tax_total': taxTotal.toString(),
      'discount_total': discountTotal.toString(),
      'total': total.toString(),
    };
  }
}

// Coupon Model
class WooCoupon {
  final int id;
  final String code;
  final String amount;
  final String discountType;
  final String description;
  final String dateExpires;
  final int usageCount;
  final bool individualUse;
  final List<int> productIds;
  final List<int> excludedProductIds;
  final int usageLimit;
  final int usageLimitPerUser;
  final double minimumAmount;
  final double maximumAmount;
  final bool emailRestrictions;

  WooCoupon({
    required this.id,
    required this.code,
    required this.amount,
    required this.discountType,
    required this.description,
    required this.dateExpires,
    required this.usageCount,
    required this.individualUse,
    required this.productIds,
    required this.excludedProductIds,
    required this.usageLimit,
    required this.usageLimitPerUser,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.emailRestrictions,
  });

  factory WooCoupon.fromJson(Map<String, dynamic> json) {
    return WooCoupon(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      amount: json['amount'] ?? '0',
      discountType: json['discount_type'] ?? 'fixed_cart',
      description: json['description'] ?? '',
      dateExpires: json['date_expires'] ?? '',
      usageCount: json['usage_count'] ?? 0,
      individualUse: json['individual_use'] ?? false,
      productIds: (json['product_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      excludedProductIds: (json['excluded_product_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      usageLimit: json['usage_limit'] ?? 0,
      usageLimitPerUser: json['usage_limit_per_user'] ?? 0,
      minimumAmount: double.tryParse(json['minimum_amount']?.toString() ?? '0') ?? 0.0,
      maximumAmount: double.tryParse(json['maximum_amount']?.toString() ?? '0') ?? 0.0,
      emailRestrictions: json['email_restrictions'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'amount': amount,
      'discount_type': discountType,
      'description': description,
      'date_expires': dateExpires,
      'usage_count': usageCount,
      'individual_use': individualUse,
      'product_ids': productIds,
      'excluded_product_ids': excludedProductIds,
      'usage_limit': usageLimit,
      'usage_limit_per_user': usageLimitPerUser,
      'minimum_amount': minimumAmount.toString(),
      'maximum_amount': maximumAmount.toString(),
      'email_restrictions': emailRestrictions,
    };
  }
}

// Customer Model
class WooCustomer {
  final int id;
  final String dateCreated;
  final String dateModified;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String username;
  final WooBilling billing;
  final WooShipping shipping;
  final bool isPayingCustomer;
  final String avatarUrl;

  WooCustomer({
    required this.id,
    required this.dateCreated,
    required this.dateModified,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.username,
    required this.billing,
    required this.shipping,
    required this.isPayingCustomer,
    required this.avatarUrl,
  });

  factory WooCustomer.fromJson(Map<String, dynamic> json) {
    return WooCustomer(
      id: json['id'] ?? 0,
      dateCreated: json['date_created'] ?? '',
      dateModified: json['date_modified'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? 'customer',
      username: json['username'] ?? '',
      billing: WooBilling.fromJson(json['billing'] ?? {}),
      shipping: WooShipping.fromJson(json['shipping'] ?? {}),
      isPayingCustomer: json['is_paying_customer'] ?? false,
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_created': dateCreated,
      'date_modified': dateModified,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'username': username,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'is_paying_customer': isPayingCustomer,
      'avatar_url': avatarUrl,
    };
  }
} 