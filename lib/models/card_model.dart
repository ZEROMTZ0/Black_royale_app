class CardModel {
  final String value; // "ACE","2"..."10","JACK","QUEEN","KING"
  final String suit;  // "HEARTS","DIAMONDS","CLUBS","SPADES"
  final String imageUrl;
  final String code;

  const CardModel({
    required this.value,
    required this.suit,
    required this.imageUrl,
    required this.code,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      value: json['value'] as String,
      suit: json['suit'] as String,
      imageUrl: json['image'] as String,
      code: json['code'] as String,
    );
  }

  int get numericValue {
    switch (value) {
      case 'ACE':
        return 11;
      case 'JACK':
      case 'QUEEN':
      case 'KING':
        return 10;
      default:
        return int.parse(value);
    }
  }

  String get suitSymbol {
    switch (suit) {
      case 'HEARTS':   return '♥';
      case 'DIAMONDS': return '♦';
      case 'CLUBS':    return '♣';
      case 'SPADES':   return '♠';
      default:         return '?';
    }
  }

  bool get isRed => suit == 'HEARTS' || suit == 'DIAMONDS';

  String get displayValue {
    switch (value) {
      case 'ACE':   return 'A';
      case 'JACK':  return 'J';
      case 'QUEEN': return 'Q';
      case 'KING':  return 'K';
      default:      return value;
    }
  }
}
