import 'package:flutter/scheduler.dart';

class GlobalTickerProvider extends TickerProvider {
  static final GlobalTickerProvider _instance =
      GlobalTickerProvider._internal();
  factory GlobalTickerProvider() => _instance;
  GlobalTickerProvider._internal();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
