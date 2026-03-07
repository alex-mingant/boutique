class CarteBancaire {
  final String id;
  final String last4;
  final String brand;
  final int expMonth;
  final int expYear;

  const CarteBancaire({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
  });

  factory CarteBancaire.fromJson(Map<String, dynamic> json) {
    return CarteBancaire(
      id: json['id'] as String,
      last4: json['last4'] as String,
      brand: json['brand'] as String,
      expMonth: json['expMonth'] as int,
      expYear: json['expYear'] as int,
    );
  }

  String get brandLabel => switch (brand.toLowerCase()) {
        'visa' => 'Visa',
        'mastercard' => 'Mastercard',
        'amex' => 'American Express',
        'discover' => 'Discover',
        'jcb' => 'JCB',
        _ => brand.toUpperCase(),
      };

  String get expiry =>
      '${expMonth.toString().padLeft(2, '0')}/${expYear % 100}';
}
