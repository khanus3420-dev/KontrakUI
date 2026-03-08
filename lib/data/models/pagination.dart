class Paginated<T> {
  Paginated({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) builder,
  ) {
    final itemsJson = json['items'] as List<dynamic>? ?? <dynamic>[];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return Paginated<T>(
      items: itemsJson.map((e) => builder(e as Map<String, dynamic>)).toList(),
      total: (pagination['total'] as num?)?.toInt() ?? itemsJson.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      pageSize: (pagination['page_size'] as num?)?.toInt() ?? itemsJson.length,
    );
  }
}

