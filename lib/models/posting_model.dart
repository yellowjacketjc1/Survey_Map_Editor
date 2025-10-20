class PostingMetadata {
  final String id;
  final String revisionDate;
  final String header;
  final List<String> areaTypes;
  final List<String> conditions;
  final List<String> entryRequirements;
  final List<String> instructions;
  final String fullText;

  PostingMetadata({
    required this.id,
    required this.revisionDate,
    required this.header,
    required this.areaTypes,
    required this.conditions,
    required this.entryRequirements,
    required this.instructions,
    required this.fullText,
  });

  factory PostingMetadata.fromJson(Map<String, dynamic> json) {
    return PostingMetadata(
      id: json['id'] as String? ?? '',
      revisionDate: json['revision_date'] as String? ?? '',
      header: json['header'] as String? ?? '',
      areaTypes: List<String>.from(json['area_types'] ?? []),
      conditions: List<String>.from(json['conditions'] ?? []),
      entryRequirements: List<String>.from(json['entry_requirements'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      fullText: json['full_text'] as String? ?? '',
    );
  }

  /// Get the SVG filename for this posting (e.g., #01 -> Slide1.svg)
  String get svgFilename {
    final number = id.replaceAll('#', '');
    final slideNumber = int.tryParse(number) ?? 0;
    return 'Slide$slideNumber.svg';
  }

  /// Get the asset path for this posting's SVG
  String get svgAssetPath => 'assets/Postings/$svgFilename';

  /// Get all searchable text from this posting
  List<String> get searchableTerms {
    return [
      id,
      header,
      ...areaTypes,
      ...conditions,
      ...entryRequirements,
      ...instructions,
      fullText,
    ];
  }

  /// Get all unique tags from this posting
  Set<String> get tags {
    final allTags = <String>{};

    // Add header as tag
    if (header.isNotEmpty) {
      allTags.add(header.toLowerCase());
    }

    // Add area types
    allTags.addAll(areaTypes.map((t) => t.toLowerCase()));

    // Add entry requirements
    allTags.addAll(entryRequirements.map((t) => t.toLowerCase()));

    // Extract common keywords from conditions and instructions
    for (final text in [...conditions, ...instructions]) {
      if (text.toLowerCase().contains('rba')) allTags.add('rba');
      if (text.toLowerCase().contains('dosimeter')) allTags.add('dosimeter');
      if (text.toLowerCase().contains('airborne')) allTags.add('airborne');
      if (text.toLowerCase().contains('high radiation')) allTags.add('high radiation');
      if (text.toLowerCase().contains('contamination')) allTags.add('contamination');
      if (text.toLowerCase().contains('protective clothing')) allTags.add('protective clothing');
    }

    return allTags;
  }

  /// Check if this posting matches a search query
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();
    return searchableTerms.any((term) =>
      term.toLowerCase().contains(lowerQuery)
    );
  }

  /// Check if this posting has any of the given tags
  bool hasAnyTag(Set<String> filterTags) {
    if (filterTags.isEmpty) return true;
    return tags.any((tag) => filterTags.contains(tag));
  }
}
