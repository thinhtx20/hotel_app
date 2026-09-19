import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bộ giám sát BLoC & Cubit toàn cục (Global BLoC Observer).
///
/// Ghi nhận và xử lý tập trung mọi ngoại lệ phát sinh trong quá trình
/// xử lý sự kiện (event handler) và biến đổi trạng thái (state transition)
/// của tất cả BLoC/Cubit trong ứng dụng.
class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('🔴 [BlocObserver] Lỗi trong ${bloc.runtimeType}: $error');
    if (kDebugMode) {
      debugPrint('$stackTrace');
    }
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Trong môi trường dev có thể bật log chuyển đổi state nếu cần debug sâu
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // Trong môi trường dev có thể bật log transition nếu cần debug sâu
  }
}
