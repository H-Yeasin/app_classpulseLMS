import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:opalmer_education/core/services/auth_service.dart';
import 'package:opalmer_education/core/models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateProvider<UserModel?>((ref) => null);

final loginLoadingProvider = StateProvider<bool>((ref) => false);
