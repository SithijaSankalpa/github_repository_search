import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:github_repository_search/features/repository_search/presentation/search_screen.dart';
import '../bloc/token_cubit.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Token')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter a GitHub personal access token.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Personal Access Token',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.trim().isEmpty) return;
                await context.read<TokenCubit>().saveToken(_controller.text);
                if(context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SearchScreen()),
                      (route) => false,
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Save Token'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}