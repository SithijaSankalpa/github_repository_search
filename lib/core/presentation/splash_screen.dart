import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/token/bloc/token_cubit.dart';
import '../../features/token/bloc/token_state.dart';
import '../../features/token/presentation/token_screen.dart';
import '../../features/repository_search/presentation/search_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashDuration = Duration(seconds: 2);
  final _stopwatch = Stopwatch()..start();

  Future<void> _navigateAfterMinDelay(Widget destination) async {
    final elapsed = _stopwatch.elapsed;
    final remaining = _minSplashDuration - elapsed;

    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TokenCubit, TokenState>(
      listener: (context, state) {
        if (state is TokenSet) {
          _navigateAfterMinDelay(const SearchScreen());
        } else if (state is TokenMissing) {
          _navigateAfterMinDelay(const TokenScreen());
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.travel_explore,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'GitHub Repo Search',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}