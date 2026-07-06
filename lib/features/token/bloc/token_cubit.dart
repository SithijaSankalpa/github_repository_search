import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/token_repository.dart';
import 'token_state.dart';

class TokenCubit extends Cubit<TokenState> {
  final TokenRepository repository;

  TokenCubit(this.repository) : super(TokenInitial());

  Future<void> loadToken() async {
    emit(TokenLoading());
    final token = await repository.getToken();
    emit(token != null && token.isNotEmpty ? TokenSet(token) : TokenMissing());
  }

  Future<void> saveToken(String token) async {
    if (token.trim().isEmpty) return;
    await repository.saveToken(token.trim());
    emit(TokenSet(token.trim()));
  }

  Future<void> clearToken() async {
    await repository.clearToken();
    emit(TokenMissing());
  }
}