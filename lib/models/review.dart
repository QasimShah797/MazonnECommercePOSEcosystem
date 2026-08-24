class Review {
  const Review({
    required this.id,
    required this.productId,
    required this.author,
    required this.rating,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String author;
  final double rating;
  final String title;
  final String body;
  final DateTime createdAt;
}
