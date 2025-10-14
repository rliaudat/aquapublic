import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'SERVICE_SID', obfuscate: true)
  static String sidKey = _Env.sidKey;
  @EnviedField(varName: 'ACCOUNT_SID', obfuscate: true)
  static String accountSid = _Env.accountSid;
  @EnviedField(varName: 'AUTH_TOKEN', obfuscate: true)
  static String authToken = _Env.authToken;
}
