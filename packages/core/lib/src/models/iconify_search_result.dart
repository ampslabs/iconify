import 'package:meta/meta.dart';
import 'iconify_name.dart';

/// A single result from an icon search query.
@immutable
final class IconifySearchResult {
  const IconifySearchResult({
    required this.name,
    required this.score,
    this.matchedOn,
  });

  /// The icon name that matched.
  final IconifyName name;

  /// Relevance score (higher = more relevant). Range: 0.0 to 1.0.
  final double score;

  /// What the query matched on: 'exact', 'prefix', 'alias', 'tag'.
  final String? matchedOn;

  @override
  String toString() =>
      'IconifySearchResult($name, score: ${score.toStringAsFixed(2)})';
}
