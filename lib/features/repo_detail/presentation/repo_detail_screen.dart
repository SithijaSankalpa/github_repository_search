import 'package:flutter/material.dart';
import '../../repository_search/data/models/repository_model.dart';

class RepoDetailScreen extends StatelessWidget {
  final RepositoryModel repo;
  const RepoDetailScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(repo.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: repo.ownerAvatarUrl.isNotEmpty
                      ? NetworkImage(repo.ownerAvatarUrl)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(repo.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(repo.ownerLogin, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              repo.description?.isNotEmpty == true ? repo.description! : 'No description provided.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _StatTile(icon: Icons.star, label: 'Stars', value: '${repo.stars}'),
                _StatTile(icon: Icons.call_split, label: 'Forks', value: '${repo.forks}'),
                _StatTile(icon: Icons.error_outline, label: 'Open Issues', value: '${repo.openIssues}'),
                _StatTile(icon: Icons.visibility, label: 'Watchers', value: '${repo.watchers}'),
                if (repo.language != null)
                  _StatTile(icon: Icons.code, label: 'Language', value: repo.language!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}