import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    // LOGIN
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.login(email: event.email, password: event.password);

        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // REGISTER
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.register(
          email: event.email,
          password: event.password,
        );

        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // LOGOUT
    on<LogoutRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        await authService.logout();

        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
  }
}
