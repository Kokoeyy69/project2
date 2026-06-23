class FraudShieldService {
  static Future<String> evaluate(double amount) async {
    int score = 0;

    if (amount > 10000000) {
      score += 50;
    }

    final now = DateTime.now();
    if (now.hour >= 23 || now.hour < 5) {
      score += 30;
    }

    if (score >= 70) {
      return 'high';
    } else if (score >= 40) {
      return 'suspicious';
    } else {
      return 'safe';
    }
  }
}
