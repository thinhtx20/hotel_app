import 'package:get_it/get_it.dart';
import '../core/network/dio_client.dart';
import '../core/storage/token_storage.dart';
import '../features/admin/bloc/today_check_outs_bloc.dart';
import '../features/admin/bloc/user_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/cashier/bloc/invoice_bloc.dart';
import '../shared/repositories/analytics_repository.dart';
import '../shared/repositories/booking_repository.dart';
import '../shared/repositories/invoice_repository.dart';
import '../shared/repositories/room_repository.dart';
import '../shared/repositories/service_repository.dart';
import '../shared/repositories/shift_repository.dart';
import '../shared/repositories/upload_repository.dart';
import '../shared/repositories/user_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());

  // Repositories
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<ServiceRepository>(
    () => ServiceRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<ShiftRepository>(
    () => ShiftRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<UploadRepository>(
    () => UploadRepository(dioClient: sl<DioClient>()),
  );

  // Features - Auth
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      dioClient: sl<DioClient>(),
      tokenStorage: sl<TokenStorage>(),
      onSessionReset: clearUserScopedCaches,
    ),
  );

  // Features - Cashier / Invoices
  sl.registerFactory<InvoiceBloc>(
    () => InvoiceBloc(invoiceRepository: sl<InvoiceRepository>()),
  );

  // Features - Admin / Users
  sl.registerFactory<UserBloc>(
    () => UserBloc(userRepository: sl<UserRepository>()),
  );

  // Features - Admin / Today Check-Outs
  sl.registerFactory<TodayCheckOutsBloc>(
    () => TodayCheckOutsBloc(bookingRepository: sl<BookingRepository>()),
  );
}

/// Dọn dữ liệu gắn với người dùng đang đăng nhập.
///
/// Các repository là singleton nên cache của chúng sống lâu hơn phiên đăng
/// nhập; gọi hàm này khi đăng nhập tài khoản khác hoặc đăng xuất để tài khoản
/// mới không nhìn thấy dữ liệu của tài khoản cũ.
void clearUserScopedCaches() {
  if (sl.isRegistered<RoomRepository>()) sl<RoomRepository>().clearSession();
  if (sl.isRegistered<BookingRepository>()) {
    sl<BookingRepository>().clearSession();
  }
  if (sl.isRegistered<ServiceRepository>()) {
    sl<ServiceRepository>().clearSession();
  }
}

