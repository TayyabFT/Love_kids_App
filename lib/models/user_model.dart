class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String subscriptionPlan;
  final DateTime subscriptionStartDate;
  final DateTime subscriptionEndDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.subscriptionPlan,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
  });

  // Factory constructor to create a User from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      profileImage: map['profileImage'],
      subscriptionPlan: map['subscriptionPlan'],
      subscriptionStartDate: DateTime.parse(map['subscriptionStartDate']),
      subscriptionEndDate: DateTime.parse(map['subscriptionEndDate']),
    );
  }

  // Convert User object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStartDate': subscriptionStartDate.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate.toIso8601String(),
    };
  }

  // Create a copy of the User with modified properties
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    String? subscriptionPlan,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  // Check if subscription is active
  bool get isSubscriptionActive {
    final now = DateTime.now();
    return now.isAfter(subscriptionStartDate) && 
           now.isBefore(subscriptionEndDate);
  }

  // Get remaining days in subscription
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(subscriptionEndDate)) {
      return 0;
    }
    return subscriptionEndDate.difference(now).inDays;
  }

  // Create a demo user (for testing purposes)
  static User demoUser() {
    final now = DateTime.now();
    return User(
      id: 'demo_user_123',
      name: 'Guest User',
      email: 'guest@example.com',
      profileImage: null,
      subscriptionPlan: 'monthly',
      subscriptionStartDate: now,
      subscriptionEndDate: now.add(const Duration(days: 30)),
    );
  }
}