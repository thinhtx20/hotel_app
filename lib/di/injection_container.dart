import 'package:get_it/get_it.dart';
import '../core/network/dio_client.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../shared/repositories/room_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());

  // Repositories
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepository(dioClient: sl<DioClient>()),
  );

  // Features - Auth
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      dioClient: sl<DioClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );
}
