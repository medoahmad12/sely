import 'package:flutter/material.dart';

class RewardItem {
  const RewardItem(this.id, this.nameKey, this.cost);
  final String id;
  final String nameKey;

  /// Stars the child must have earned to unlock it (stars are never spent).
  final int cost;
  bool unlockedFor(int stars) => stars >= cost;
}

class RewardCatalog {
  RewardCatalog._();
  static const hats = [
    RewardItem('none', 'reward_none', 0),
    RewardItem('party', 'reward_party', 10),
    RewardItem('bow', 'reward_bow', 25),
    RewardItem('glasses', 'reward_glasses', 40),
    RewardItem('crown', 'reward_crown', 60),
  ];
  static const backgrounds = [
    RewardItem('sky', 'bg_sky', 0),
    RewardItem('sunset', 'bg_sunset', 15),
    RewardItem('forest', 'bg_forest', 30),
    RewardItem('candy', 'bg_candy', 50),
    RewardItem('space', 'bg_space', 75),
  ];

  static const _gradients = <String, List<Color>>{
    'sky': [Color(0xFF6FD0FF), Color(0xFFE6F7FF)],
    'sunset': [Color(0xFFFFB86B), Color(0xFFFFE3F1)],
    'forest': [Color(0xFF7ED68B), Color(0xFFE8FBE6)],
    'candy': [Color(0xFFFF9FCB), Color(0xFFFFF0F7)],
    'space': [Color(0xFF5B52D6), Color(0xFFC9C4FF)],
  };

  static List<Color> gradientFor(String id) => _gradients[id] ?? _gradients['sky']!;
}
