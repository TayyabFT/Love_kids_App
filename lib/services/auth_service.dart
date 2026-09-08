import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(name);

      // Store additional user data in Firestore
      await _storeUserData(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        photoUrl: null,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw _handleUnexpectedAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw _handleUnexpectedAuthError(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Store user data in Firestore if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _storeUserData(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Google User',
          email: userCredential.user!.email!,
          photoUrl: userCredential.user!.photoURL,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // More specific error message to help with debugging
      String errorMessage = e.toString();
      if (errorMessage.contains('PlatformException') || errorMessage.contains('10:')) {
        throw 'Google Sign-In configuration error. Please check SHA-1 fingerprints in Firebase Console.';
      }
      throw 'Failed to sign in with Google. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Store user data in Firestore
  Future<void> _storeUserData({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Don't throw error for Firestore operations to avoid blocking auth
      print('Error storing user data: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    final message = e.message ?? '';
    if (_isFirebaseConfigurationError(e.code, message)) {
      return _firebaseConfigurationErrorMessage;
    }

    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is disabled in Firebase. Open Firebase Console '
            '→ Authentication → Sign-in method → Email/Password → Enable, then try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  static const String _firebaseConfigurationErrorMessage =
      'Firebase Auth is not set up for this Android build. In Firebase Console '
      '(project: sayitloveforkid), add your debug SHA-1 fingerprint, enable '
      'Email/Password sign-in, download a new google-services.json, and rebuild the app.';

  bool _isFirebaseConfigurationError(String code, String message) {
    final normalized = message.toUpperCase();
    return code == 'internal-error' &&
        (normalized.contains('CONFIGURATION_NOT_FOUND') ||
            normalized.contains('CONFIGURATION NOT FOUND'));
  }

  String _handleUnexpectedAuthError(Object error) {
    final text = error.toString().toUpperCase();
    if (text.contains('CONFIGURATION_NOT_FOUND') ||
        text.contains('CONFIGURATION NOT FOUND')) {
      return _firebaseConfigurationErrorMessage;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    if (currentUser != null) {
      try {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating last login: $e');
      }
    }
  }

  // Change password for email/password users
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw 'No user signed in';
      }

      // Check if user signed in with Google (they can't change password)
      bool isGoogleSignIn = false;
      for (final providerData in user.providerData) {
        if (providerData.providerId == 'google.com') {
          isGoogleSignIn = true;
          break;
        }
      }
      
      if (isGoogleSignIn) {
        throw 'Cannot change password for Google sign-in users';
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Check if user signed in with Google
  Future<bool> isGoogleUser() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      // Check if any of the user's providers is Google
      for (final providerData in user.providerData) {
        if (providerData.providerId == 'google.com') {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking if Google user: $e');
      return false;
    }
  }

  // Add book to reading history
  Future<void> addToReadingHistory({
    required String bookId,
    required String title,
    required String imageUrl,
    required String pdfName,
    required List<String> tags,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final bookData = {
        'bookId': bookId,
        'title': title,
        'imageUrl': imageUrl,
        'pdfName': pdfName,
        'tags': tags,
        'readAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      // Add to user's reading history collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('readingHistory')
          .doc(bookId)
          .set(bookData, SetOptions(merge: true));

      print('Book added to reading history: $title');
    } catch (e) {
      print('Error adding book to reading history: $e');
    }
  }

  // Get user's reading history
  Future<List<Map<String, dynamic>>> getReadingHistory({int limit = 10}) async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('readingHistory')
          .orderBy('readAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to readable format
        if (data['readAt'] != null) {
          final timestamp = data['readAt'] as Timestamp;
          final now = DateTime.now();
          final readDate = timestamp.toDate();
          final difference = now.difference(readDate);

          String timeAgo;
          if (difference.inDays == 0) {
            if (difference.inHours == 0) {
              timeAgo = 'Just now';
            } else {
              timeAgo = '${difference.inHours}h ago';
            }
          } else if (difference.inDays == 1) {
            timeAgo = 'Yesterday';
          } else if (difference.inDays < 7) {
            timeAgo = '${difference.inDays} days ago';
          } else {
            timeAgo = '${(difference.inDays / 7).floor()} weeks ago';
          }

          data['lastRead'] = 'Last read: $timeAgo';
        } else {
          data['lastRead'] = 'Recently read';
        }

        return data;
      }).toList();
    } catch (e) {
      print('Error getting reading history: $e');
      return [];
    }
  }

  // Check if book is in reading history
  Future<bool> isBookInHistory(String bookId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('readingHistory')
          .doc(bookId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking book in history: $e');
      return false;
    }
  }
} 