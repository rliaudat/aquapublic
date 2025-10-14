part of 'authentication_bloc.dart';

sealed class AuthenticationState {}

final class AuthenticationInitial extends AuthenticationState {}

final class Authenticated extends AuthenticationState {
  final AppUser user;

  Authenticated({required this.user});
}

final class Unauthenticated extends AuthenticationState {}

final class EmailUnverified extends AuthenticationState {}

final class EmailAuthenticationStarted extends AuthenticationState {}

final class SendingForgotPasswordLink extends AuthenticationState {}

final class ForgotPasswordLinkSended extends AuthenticationState {}

final class EmailAuthenticationFailed extends AuthenticationState {
  final String error;

  EmailAuthenticationFailed({required this.error});
}
