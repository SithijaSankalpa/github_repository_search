class RepositoryModel {
  final String fullName;
  final String ownerLogin;
  final String ownerAvatarUrl;
  final String? description;
  final int stars;
  final String? language;
  final int forks;
  final int openIssues;
  final int watchers;
  final String htmlUrl;

  RepositoryModel({
    required this.fullName,
    required this.ownerLogin,
    required this.ownerAvatarUrl,
    this.description,
    required this.stars,
    this.language,
    required this.forks,
    required this.openIssues,
    required this.watchers,
    required this.htmlUrl,
  });

  factory RepositoryModel.fromJson(Map<String, dynamic> json) {
    return RepositoryModel(
      fullName: json['full_name'] as String? ?? '',
      ownerLogin: json['owner']?['login'] as String? ?? '',
      ownerAvatarUrl: json['owner']?['avatar_url'] as String? ?? '',
      description: json['description'] as String?,
      stars: json['stargazers_count'] as int? ?? 0,
      language: json['language'] as String?,
      forks: json['forks_count'] as int? ?? 0,
      openIssues: json['open_issues_count'] as int? ?? 0,
      watchers: json['watchers_count'] as int? ?? 0,
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }
}