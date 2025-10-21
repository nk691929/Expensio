class CurrencyModel {
  final String code;   // e.g. "USD"
  final String symbol; // e.g. "$"
  final String name;   // e.g. "US Dollar"

  const CurrencyModel({
    required this.code,
    required this.symbol,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'symbol': symbol,
      'name': name,
    };
  }

  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      code: map['code'],
      symbol: map['symbol'],
      name: map['name'],
    );
  }
}



const List<CurrencyModel> currencyList = [
  CurrencyModel(code: "USD", symbol: "\$", name: "US Dollar"),
  CurrencyModel(code: "EUR", symbol: "€", name: "Euro"),
  CurrencyModel(code: "GBP", symbol: "£", name: "British Pound"),
  CurrencyModel(code: "PKR", symbol: "₨", name: "Pakistani Rupee"),
  CurrencyModel(code: "INR", symbol: "₹", name: "Indian Rupee"),
  CurrencyModel(code: "JPY", symbol: "¥", name: "Japanese Yen"),
  CurrencyModel(code: "CNY", symbol: "¥", name: "Chinese Yuan"),
  CurrencyModel(code: "CAD", symbol: "\$", name: "Canadian Dollar"),
  CurrencyModel(code: "AUD", symbol: "\$", name: "Australian Dollar"),
];
