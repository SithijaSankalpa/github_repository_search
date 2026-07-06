import 'package:equatable/equatable.dart';

sealed class TokenState extends Equatable{
  const TokenState();
  @override
  List<Object?> get props => [];
}

class TokenInitial extends TokenState {}

class TokenLoading extends TokenState {}

class TokenSet extends TokenState{
  final String token;
  const TokenSet(this.token);
  @override
  List<Object?> get props => [token];
}

class TokenMissing extends TokenState {}