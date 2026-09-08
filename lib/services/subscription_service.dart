import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _logTag = 'SUB_NAV';

  /// Minimum days after purchase before a subscription may be cancelled.
  static const int cancellationMinDays = 7;

  static const String cancellationTooEarlyMessage =
      'Subscriptions can only be cancelled after 7 days from the purchase date.';

  /// Firestore document used to read trusted server time (not device clock).
  static const String _serverClockCollection = 'appMeta';
  static const String _serverClockDoc = 'serverClock';

  /// Parses [expiryDate] from Firestore safely. Returns null if missing/invalid.
  DateTime? parseExpiryDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Returns trusted UTC time from Firestore (immune to device clock changes).
  Future<DateTime> getServerTime() async {
    final docRef = _firestore
        .collection(_serverClockCollection)
        .doc(_serverClockDoc);

    await docRef.set(
      {'lastSync': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    final snapshot = await docRef.get(const GetOptions(source: Source.server));
    final serverTime = parseExpiryDate(snapshot.data()?['lastSync']);

    if (serverTime == null) {
      throw Exception('Failed to obtain Firestore server time');
    }

    return serverTime;
  }

  /// Reusable subscription validation used on launch, login, and app resume.
  /// Fetches from Firestore, expires stale records, and returns premium access.
  Future<bool> checkSubscriptionStatus() async {
    print('[$_logTag] SubscriptionService.checkSubscriptionStatus()');
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current');

      final doc = await docRef.get(const GetOptions(source: Source.server));
      if (!doc.exists) return false;

      final data = doc.data()!;
      final status = data['status'] as String?;

      if (status == 'cancelled' || status == 'expired') {
        return false;
      }

      final expiryDate = parseExpiryDate(data['expiryDate']);
      if (expiryDate == null) {
        print('Subscription check: invalid or missing expiryDate');
        return false;
      }

      final serverNow = await getServerTime();
      if (serverNow.isAfter(expiryDate)) {
        print('[$_logTag] Subscription expired — updating Firestore and returning false');
        await _markSubscriptionExpired(docRef);
        return false;
      }

      final isActive = data['isActive'] as bool? ?? false;
      print('[$_logTag] SubscriptionService.checkSubscriptionStatus() → $isActive');
      return isActive;
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
    }
  }

  Future<void> _markSubscriptionExpired(DocumentReference<Map<String, dynamic>> docRef) async {
    print('[$_logTag] _markSubscriptionExpired() path=${docRef.path}');
    await docRef.set({
      'isActive': false,
      'status': 'expired',
      'expiredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Check if user has an active subscription
  Future<bool> hasActiveSubscription() => checkSubscriptionStatus();

  // Get subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      print('Error getting subscription details: $e');
      return null;
    }
  }

  // Create or update subscription
  Future<void> createSubscription({
    required String planType,
    required double amount,
    required String paymentIntentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated - no current user found');
      }

      print('Creating subscription for user: ${user.uid}');
      print('User email: ${user.email}');
      print('Plan type: $planType, Amount: $amount');

      // Ensure user document exists in Firestore
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();
      
      if (!userSnapshot.exists) {
        print('User document does not exist, creating it...');
        await userDoc.set({
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('User document created successfully');
      } else {
        print('User document exists');
      }

      final serverNow = await getServerTime();
      final expiryDate = planType == 'monthly'
          ? serverNow.add(const Duration(days: 30))
          : serverNow.add(const Duration(days: 365));

      final subscriptionData = {
        'planType': planType,
        'amount': amount,
        'currency': 'USD',
        'paymentIntentId': paymentIntentId,
        'isActive': true,
        'status': 'active',
        'startDate': Timestamp.fromDate(serverNow),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('Writing subscription data to: users/${user.uid}/subscription/current');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .set(subscriptionData);

      print('Subscription document created successfully');

      // Also save to payment history
      print('Writing payment history to: users/${user.uid}/payments');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .add({
        ...subscriptionData,
        'type': 'subscription',
        'status': 'completed',
      });

      print('Payment history created successfully');
      print('Subscription created successfully for user: ${user.uid}');
    } catch (e) {
      print('Error creating subscription: $e');
      print('Error type: ${e.runtimeType}');
      if (e.toString().contains('permission-denied')) {
        print('Permission denied error - check Firestore security rules');
        print('Make sure user is authenticated and rules allow write access');
      }
      rethrow;
    }
  }

  /// Throws when fewer than [cancellationMinDays] have passed since [startDate].
  Future<void> assertCancellationAllowed(Map<String, dynamic> subscriptionData) async {
    final startDate = parseExpiryDate(subscriptionData['startDate']);
    if (startDate == null) {
      throw Exception('Unable to verify subscription purchase date.');
    }

    final serverNow = await getServerTime();
    final daysSincePurchase = serverNow.difference(startDate).inDays;

    if (daysSincePurchase < cancellationMinDays) {
      print(
        '[$_logTag] Cancellation blocked — $daysSincePurchase days since purchase '
        '(minimum $cancellationMinDays)',
      );
      throw Exception(cancellationTooEarlyMessage);
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current');

      final existing = await docRef.get(const GetOptions(source: Source.server));
      if (!existing.exists) {
        throw Exception('No subscription document found at users/${user.uid}/subscription/current');
      }

      await assertCancellationAllowed(existing.data()!);

      // merge write is more reliable than update() if fields/rules differ
      await docRef.set({
        'isActive': false,
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Confirm the write reached Firestore (not just local cache)
      final verified = await docRef.get(const GetOptions(source: Source.server));
      final data = verified.data();
      final isActive = data?['isActive'];
      final status = data?['status'];

      if (isActive != false || status != 'cancelled') {
        throw Exception(
          'Cancellation was not saved. isActive=$isActive, status=$status',
        );
      }

      print('Subscription cancelled successfully for user: ${user.uid}');
    } catch (e) {
      print('Error cancelling subscription: $e');
      rethrow;
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }
} 