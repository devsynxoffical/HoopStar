class StrategyModel {
  final String id;
  final String title;
  final String category;
  final String sourceType;
  final String sourceText;
  final String videoUrl;
  final DateTime createdAt;
  final String createdByName;
  final String createdByRole;
  final List<String> tags;
  final int viewCount;
  final int likeCount;
  final List<String> likedBy;
  final bool isPublic;
  final String? thumbnailUrl;
  final Duration? duration;
  final Map<String, dynamic>? metadata;

  StrategyModel({
    required this.id,
    required this.title,
    required this.category,
    required this.sourceType,
    required this.sourceText,
    required this.videoUrl,
    required this.createdAt,
    required this.createdByName,
    required this.createdByRole,
    this.tags = const [],
    this.viewCount = 0,
    this.likeCount = 0,
    this.likedBy = const [],
    this.isPublic = true,
    this.thumbnailUrl,
    this.duration,
    this.metadata,
  });

  factory StrategyModel.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] is Map
        ? Map<String, dynamic>.from(json['createdBy'])
        : <String, dynamic>{};

    return StrategyModel(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      sourceType: (json['sourceType'] ?? 'text').toString(),
      sourceText: (json['sourceText'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      createdByName: (createdBy['username'] ?? 'Coach').toString(),
      createdByRole: (createdBy['role'] ?? '').toString(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      viewCount: (json['viewCount'] ?? 0) as int,
      likeCount: (json['likeCount'] ?? 0) as int,
      likedBy: (json['likedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isPublic: (json['isPublic'] ?? true) as bool,
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      duration: json['duration'] != null ? Duration(seconds: json['duration'] as int) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'sourceType': sourceType,
      'sourceText': sourceText,
      'videoUrl': videoUrl,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': {
        'username': createdByName,
        'role': createdByRole,
      },
      'tags': tags,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'isPublic': isPublic,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration?.inSeconds,
      'metadata': metadata,
    };
  }

  StrategyModel copyWith({
    String? id,
    String? title,
    String? category,
    String? sourceType,
    String? sourceText,
    String? videoUrl,
    DateTime? createdAt,
    String? createdByName,
    String? createdByRole,
    List<String>? tags,
    int? viewCount,
    int? likeCount,
    List<String>? likedBy,
    bool? isPublic,
    String? thumbnailUrl,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    return StrategyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      sourceText: sourceText ?? this.sourceText,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      isPublic: isPublic ?? this.isPublic,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      metadata: metadata ?? this.metadata,
    );
  }
}
