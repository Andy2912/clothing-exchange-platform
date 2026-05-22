class MatchItem {
  final int matchId;
  final int otherUserId;
  final String otherUsername;
  final String matchedItemName;
  final String matchedItemImageUrl;
  final String status;

  MatchItem({
    required this.matchId,
    required this.otherUserId,
    required this.otherUsername,
    required this.matchedItemName,
    required this.matchedItemImageUrl,
    required this.status,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      matchId: json['match_id'],
      otherUserId: json['other_user_id'],
      otherUsername: json['other_username'] ?? '',
      matchedItemName: json['matched_item_name'] ?? '',
      matchedItemImageUrl: json['matched_item_image_url'] ?? '',
      status: json['status'] ?? '',
    );
  }
}