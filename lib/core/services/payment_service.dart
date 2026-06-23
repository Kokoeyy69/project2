import 'dart:async';

class PaymentService {
  Future<bool> simulateTopUpVA(int amount, String bankName) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  bool isValidLuhn(String cardNumber) {
    String clean = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = clean.length - 1; i >= 0; i--) {
      int n = int.parse(clean[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n -= 9;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  Future<bool> simulateTopUpCreditCard(String cardNumber, String cvv) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}
