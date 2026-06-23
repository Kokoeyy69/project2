import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QRViewModel extends ChangeNotifier {
  String? _userName;
  String? _userUid;
  bool _isLoading = true;

  String? get userName => _userName;
  String? get userUid => _userUid;
  bool get isLoading => _isLoading;

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      _userUid = user.uid;
      _userName = doc.data()?['name'] ?? 'NeoPay User';
      _isLoading = false;
    } catch (e) {
      _userUid = user.uid;
      _userName = 'NeoPay User';
      _isLoading = false;
    }
    notifyListeners();
  }
}
