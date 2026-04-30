import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeViewModel extends ChangeNotifier {
  double _balance = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _error;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  double get balance => _balance;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get error => _error;

  Future<void> start() async {
    _isLoading = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      _hasError = true;
      _error = 'Not signed in';
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getDouble('cached_balance');
    if (cached != null) {
      _balance = cached;
    }

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snap) async {
            if (!snap.exists) return;
            final data = snap.data();
            final val = (data?['balance'] as num?)?.toDouble() ?? 0.0;
            _balance = val;
            try {
              final prefs2 = await SharedPreferences.getInstance();
              await prefs2.setDouble('cached_balance', _balance);
            } catch (_) {}
            _isLoading = false;
            _hasError = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _isLoading = false;
            _hasError = true;
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      _hasError = true;
      _error = 'Not signed in';
      notifyListeners();
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final val = (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      _balance = val;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_balance', _balance);
      _hasError = false;
      _error = null;
    } catch (e) {
      _hasError = true;
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
