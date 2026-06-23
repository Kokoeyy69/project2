import 'package:flutter/material.dart';

class TransferService {
  Future<bool> simulateTransfer(int amount, String destinationBank, String destinationAccount) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}