import 'dart:io';

import 'package:agua_med/_helpers/encrypption.dart';
import 'package:agua_med/_services/user_services.dart';
import 'package:agua_med/models/user.dart';
import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(AuthenticationInitial()) {
    on<AuthenticationStarted>(_onAuthenticationStarted);
    on<CheckAuth>(_onCheckAuth);
    on<LoginByEmail>(_onLoginByEmail);
    on<RegisterByEmail>(_onRegisterByEmail);
    on<SendForgotPasswordLink>(_onSendForgotPasswordLink);
  }

  final _firebaseAuth = FirebaseAuth.instance;

  Future<void> _onAuthenticationStarted(
    AuthenticationStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(AuthenticationInitial());
  }

  Future<void> _onCheckAuth(
    CheckAuth event,
    Emitter<AuthenticationState> emit,
  ) async {
    await Future.delayed(Duration(seconds: event.kIsWeb ? 1 : 2));
    if (_firebaseAuth.currentUser != null) {
      AppUser? value =
          await UserServices.fetchById(_firebaseAuth.currentUser!.uid);
      if (value != null) {
        emit(Authenticated(user: value));
      } else {
        _firebaseAuth.signOut();
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginByEmail(
    LoginByEmail event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(EmailAuthenticationStarted());
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      UserServices.update(
        uid: _firebaseAuth.currentUser!.uid,
        data: {'platform': event.platform, 'fcmToken': event.token},
      );
      AppUser? value =
          await UserServices.fetchById(_firebaseAuth.currentUser!.uid);
      if (value != null) {
        if (_firebaseAuth.currentUser!.emailVerified) {
          emit(Authenticated(user: value));
        } else {
          await _firebaseAuth.currentUser!.sendEmailVerification();
          emit(EmailUnverified());
          _firebaseAuth.signOut();
        }
      } else {
        _firebaseAuth.signOut();
        emit(
          EmailAuthenticationFailed(
            error: 'LoginScreen.pleaseEnterValidCredentials'.tr(),
          ),
        );
      }
    } catch (e) {
      emit(
        EmailAuthenticationFailed(
          error: 'LoginScreen.pleaseEnterValidCredentials'.tr(),
        ),
      );
    }
  }

  Future<void> _onRegisterByEmail(
    RegisterByEmail event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(EmailAuthenticationStarted());
    try {
      var searchEmail = await UserServices.fetchByEmail(event.user.email);

      if (searchEmail == null) {
        var searchPhoneNumber =
            await UserServices.fetchByPhone(event.user.phoneNumber);

        if (searchPhoneNumber == null) {
          final userCredential =
              await _firebaseAuth.createUserWithEmailAndPassword(
            email: event.user.email,
            password: event.password,
          );

          if (_firebaseAuth.currentUser != null) {
            await userCredential.user?.sendEmailVerification();
            final encryptionResult =
                encryptPass(text: event.password, key: 'SECRET_KEY');
            String? profileImageURL;
            if (event.image != null) {
              profileImageURL = await UserServices.storeProfileImage(
                  userCredential.user?.uid ?? 'Not Assigned', event.image!);
            }
            await UserServices.register(
              event.user.copyWith(
                uid: userCredential.user?.uid ?? 'Not Assigned',
                encryptedPassword: encryptionResult.encryptedData,
                iv: encryptionResult.iv,
                profileImageURL: profileImageURL,
              ),
            );
            emit(EmailUnverified());
            _firebaseAuth.signOut();
          } else {
            emit(
              EmailAuthenticationFailed(
                error: 'AuthService.somethingWentWrong'.tr(),
              ),
            );
          }
        } else {
          emit(
            EmailAuthenticationFailed(
              error: 'AuthService.thisPhoneNumberIsAlreadyRegistered'.tr(),
            ),
          );
        }
      } else {
        emit(
          EmailAuthenticationFailed(
            error: 'AuthService.thisEmailAddressIsAlreadyRegistered'.tr(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      emit(
        EmailAuthenticationFailed(
          error: '${'AuthService.failedToSignUp'.tr()}${e.message}',
        ),
      );
    } catch (e) {
      emit(
        EmailAuthenticationFailed(
          error: '${'AuthService.anErrorOccurred'.tr()}$e',
        ),
      );
    }
  }

  Future<void> _onSendForgotPasswordLink(
    SendForgotPasswordLink event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(SendingForgotPasswordLink());
    try {
      final user = await UserServices.fetchByEmail(event.email);
      if (user == null) {
        emit(
          EmailAuthenticationFailed(
            error: 'ForgotPasswordScreen.passwordResetLinkSent'.tr(),
          ),
        );
      } else {
        await _firebaseAuth.sendPasswordResetEmail(email: event.email);
        emit(ForgotPasswordLinkSended());
      }
    } catch (e) {
      emit(
        EmailAuthenticationFailed(
          error: 'ForgotPasswordScreen.passwordResetLinkSent'.tr(),
        ),
      );
    }
  }
}
