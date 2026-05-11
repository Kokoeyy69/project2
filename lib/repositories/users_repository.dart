import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User model for transfer recipients
class TransferUser {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? handle;

  TransferUser({
    required this.uid,
    required this.name,
    this.email,
    this.photoUrl,
    this.handle,
  });

  factory TransferUser.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      // Always use document ID as uid - never empty
      final uid = doc.id.isNotEmpty ? doc.id : 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      final user = TransferUser(
        uid: uid,
        name: data['name'] as String? ?? 'Unknown User',
        email: data['email'] as String?,
        photoUrl: data['photoUrl'] as String? ?? data['photo_url'] as String?,
        handle: data['handle'] as String?,
      );
      debugPrint('[TransferUser] Mapped user: ${user.displayName} (${user.uid})');
      return user;
    } catch (e, stackTrace) {
      debugPrint('[TransferUser] Error mapping document ${doc.id}: $e');
      debugPrint('[TransferUser] Stack trace: $stackTrace');
      debugPrint('[TransferUser] Document data: ${doc.data()}');
      // Return a fallback user instead of crashing
      return TransferUser(
        uid: 'unknown_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Unknown User',
        email: null,
        photoUrl: null,
        handle: null,
      );
    }
  }

  /// Get display name (falls back to email or uid)
  String get displayName => name.isNotEmpty ? name : (email ?? uid);

  /// Get initials for avatar
  String get initials {
    if (name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, 1).toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'handle': handle,
    };
  }
}

/// Repository for fetching users from Firestore
class UsersRepository {
  static final UsersRepository _instance = UsersRepository._internal();
  factory UsersRepository() => _instance;
  UsersRepository._internal();

  static UsersRepository get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID (may be null if not logged in)
  String? get currentUserId => _auth.currentUser?.uid;

  /// Fetch all users except the current user
  /// Uses simple query with client-side filtering to avoid Firestore query issues
  Future<List<TransferUser>> getAllUsers() async {
    try {
      final currentUid = currentUserId;
      
      // Simple fetch without any document ID filter - just limit to 50
      final snapshot = await _firestore
          .collection('users')
          .limit(50)
          .get();

      // Client-side filtering to exclude current user
      return snapshot.docs
          .map((doc) => TransferUser.fromFirestore(doc as DocumentSnapshot))
          .where((user) {
            // Filter out current user and any users with empty uid
            if (user.uid.isEmpty) return false;
            if (currentUid != null && user.uid == currentUid) return false;
            return true;
          })
          .toList();
    } catch (e) {
      debugPrint('[UsersRepository] Error fetching users: $e');
      return [];
    }
  }

  /// Search users by email or name
  Future<List<TransferUser>> searchUsers(String query) async {
    // Guard clause: empty query returns all users
    if (query.isEmpty) {
      return getAllUsers();
    }

    try {
      final currentUid = currentUserId;
      final lowerQuery = query.toLowerCase().trim();

      // Simple fetch without document ID filter
      final snapshot = await _firestore
          .collection('users')
          .limit(50)
          .get();

      // Client-side search and filtering
      return snapshot.docs
          .map((doc) => TransferUser.fromFirestore(doc as DocumentSnapshot))
          .where((user) {
            // Filter out current user and empty uids
            if (user.uid.isEmpty) return false;
            if (currentUid != null && user.uid == currentUid) return false;
            
            // Search in name, email, and handle
            final nameMatch = user.name.toLowerCase().contains(lowerQuery);
            final emailMatch = user.email?.toLowerCase().contains(lowerQuery) ?? false;
            final handleMatch = user.handle?.toLowerCase().contains(lowerQuery) ?? false;
            return nameMatch || emailMatch || handleMatch;
          })
          .toList();
    } catch (e) {
      debugPrint('[UsersRepository] Error searching users: $e');
      return [];
    }
  }

  /// Get user by UID
  Future<TransferUser?> getUserByUid(String uid) async {
    // Guard clause: empty uid
    if (uid.isEmpty) {
      debugPrint('[UsersRepository] Cannot fetch user with empty UID');
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return TransferUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('[UsersRepository] Error fetching user: $e');
      return null;
    }
  }

  /// Get user by email
  Future<TransferUser?> getUserByEmail(String email) async {
    // Guard clause: empty email
    if (email.isEmpty) {
      debugPrint('[UsersRepository] Cannot fetch user with empty email');
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TransferUser.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('[UsersRepository] Error fetching user by email: $e');
      return null;
    }
  }

  /// Stream of all users (for real-time updates)
  Stream<List<TransferUser>> watchUsers() {
    final currentUid = currentUserId;

    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TransferUser.fromFirestore(doc))
              .where((user) {
                // Filter out current user and empty uids
                if (user.uid.isEmpty) return false;
                if (currentUid != null && user.uid == currentUid) return false;
                return true;
              })
              .toList();
        });
  }
}