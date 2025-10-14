part of 'authentication_bloc.dart';

sealed class AuthenticationEvent {}

final class AuthenticationStarted extends AuthenticationEvent {}

final class CheckAuth extends AuthenticationEvent {
  final bool kIsWeb;
  CheckAuth({required this.kIsWeb});
}

final class LoginByEmail extends AuthenticationEvent {
  final String email;
  final String password;
  final String? platform;
  final String? token;
  LoginByEmail({
    required this.email,
    required this.password,
    required this.platform,
    required this.token,
  });
}

final class RegisterByEmail extends AuthenticationEvent {
  final AppUser user;
  final String password;
  final File? image;

  RegisterByEmail({
    required this.user,
    required this.password,
    required this.image,
  });
}

final class SendForgotPasswordLink extends AuthenticationEvent {
  final String email;

  SendForgotPasswordLink({required this.email});
}
