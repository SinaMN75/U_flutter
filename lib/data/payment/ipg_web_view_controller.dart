part of "../data.dart";

class UIpgWebViewController {
  bool finished = false;

  void cancel() {
    if (finished) return;
    finished = true;
    UNavigator.back<bool>(false);
  }
}
