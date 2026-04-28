import 'package:hive/hive.dart';

class GameHistory extends HiveObject {
  String id;
  String result;      // 'blackjack' | 'win' | 'lose' | 'push'
  int bet;
  int chipChange;     // positivo = ganancia, negativo = pérdida
  int chipsAfter;
  DateTime playedAt;
  String playerCards; // códigos separados por coma "AH,KC"
  String dealerCards;

  GameHistory({
    required this.id,
    required this.result,
    required this.bet,
    required this.chipChange,
    required this.chipsAfter,
    required this.playedAt,
    required this.playerCards,
    required this.dealerCards,
  });
}

// Adaptador Hive escrito manualmente (no requiere build_runner)
class GameHistoryAdapter extends TypeAdapter<GameHistory> {
  @override
  final int typeId = 0;

  @override
  GameHistory read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return GameHistory(
      id:          fields[0] as String,
      result:      fields[1] as String,
      bet:         fields[2] as int,
      chipChange:  fields[3] as int,
      chipsAfter:  fields[4] as int,
      playedAt:    fields[5] as DateTime,
      playerCards: fields[6] as String,
      dealerCards: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GameHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.result)
      ..writeByte(2)..write(obj.bet)
      ..writeByte(3)..write(obj.chipChange)
      ..writeByte(4)..write(obj.chipsAfter)
      ..writeByte(5)..write(obj.playedAt)
      ..writeByte(6)..write(obj.playerCards)
      ..writeByte(7)..write(obj.dealerCards);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
