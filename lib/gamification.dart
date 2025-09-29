import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'api_config.dart';

// Reputation points for different actions
class ReputationSystem {
  static const int questionUpvote = 5;
  static const int answerUpvote = 10;
  static const int answerAccepted = 15;
  static const int answerDownvote = -2;
  static const int questionDownvote = -1;

  // This method is now deprecated - reputation is handled by the backend
  @Deprecated(
    'Reputation is now handled by the backend. This method is kept for backward compatibility but does nothing.',
  )
  static Future<void> awardReputation(
    String userEmail,
    int points,
    String reason,
  ) async {
    // Reputation is now handled by the backend
    // This method is kept for backward compatibility but does nothing
  }

  static Future<Map<String, dynamic>> getReputation() async {
    try {
      final response = await ApiService().get(ApiConfig.getReputation);
      if (response['success'] == true) {
        return {
          'reputation': response['reputation'] ?? 0,
          'level': response['level'] ?? 'Beginner',
          'nextLevelPoints': response['nextLevelPoints'] ?? 100,
        };
      }
      return {'reputation': 0, 'level': 'Beginner', 'nextLevelPoints': 100};
    } catch (e) {
      // Fallback to local storage if API fails
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('current_user_email') ?? '';
      if (currentUserEmail.isNotEmpty) {
        final reputation = prefs.getInt('${currentUserEmail}_reputation') ?? 0;
        return {
          'reputation': reputation,
          'level': _getLevelFromReputation(reputation),
          'nextLevelPoints': _getNextLevelPoints(reputation),
        };
      }
      return {'reputation': 0, 'level': 'Beginner', 'nextLevelPoints': 100};
    }
  }

  static Future<List<Map<String, dynamic>>> getReputationHistory() async {
    try {
      final response = await ApiService().get(ApiConfig.getReputationHistory);
      if (response['success'] == true) {
        final historyData = response['history'] as List? ?? [];
        return historyData.map((h) => h as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      // Fallback to local storage if API fails
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('current_user_email') ?? '';
      if (currentUserEmail.isNotEmpty) {
        final historyKey = '${currentUserEmail}_rep_history';
        final historyRaw = prefs.getString(historyKey) ?? '[]';
        return (json.decode(historyRaw) as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
  }

  static String _getLevelFromReputation(int reputation) {
    if (reputation >= 500) return 'Expert';
    if (reputation >= 100) return 'Rising Star';
    if (reputation >= 50) return 'Contributor';
    if (reputation >= 10) return 'Active';
    return 'Beginner';
  }

  static int _getNextLevelPoints(int reputation) {
    if (reputation < 10) return 10;
    if (reputation < 50) return 50;
    if (reputation < 100) return 100;
    if (reputation < 500) return 500;
    return reputation + 100; // Keep increasing
  }
}

// Badge system
class BadgeSystem {
  static Future<List<Map<String, dynamic>>> getUserBadges() async {
    try {
      final response = await ApiService().get(ApiConfig.getBadges);
      if (response['success'] == true) {
        final badgesData = response['badges'] as List? ?? [];
        return badgesData.map((b) => b as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      // Fallback to local storage if API fails
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('current_user_email') ?? '';
      if (currentUserEmail.isNotEmpty) {
        final badgesRaw = prefs.getString('${currentUserEmail}_badges') ?? '[]';
        final badgeIds = (json.decode(badgesRaw) as List).cast<String>();

        // Return basic badge info for known badges
        return badgeIds.map((id) {
          final badgeInfo = _getBadgeInfo(id);
          return {
            'id': id,
            'name': badgeInfo['name'] ?? 'Unknown Badge',
            'description': badgeInfo['description'] ?? '',
            'icon': badgeInfo['icon'] ?? Icons.star,
            'color': badgeInfo['color'] ?? Colors.grey,
            'unlockedAt': DateTime.now().toIso8601String(),
          };
        }).toList();
      }
      return [];
    }
  }

  static Map<String, dynamic> _getBadgeInfo(String badgeId) {
    const badgeMap = {
      'first_answer': {
        'name': 'First Answer',
        'description': 'Answered your first question',
        'icon': Icons.chat_bubble,
        'color': Colors.blue,
      },
      'helpful_answer': {
        'name': 'Helpful Answer',
        'description': 'Received 5 upvotes on an answer',
        'icon': Icons.thumb_up,
        'color': Colors.green,
      },
      'popular_answer': {
        'name': 'Popular Answer',
        'description': 'Received 10 upvotes on an answer',
        'icon': Icons.star,
        'color': Colors.orange,
      },
      'accepted_answer': {
        'name': 'Accepted Answer',
        'description': 'Answer was accepted',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      'question_master': {
        'name': 'Question Master',
        'description': 'Asked 10 questions',
        'icon': Icons.question_answer,
        'color': Colors.purple,
      },
      'reputation_100': {
        'name': 'Rising Star',
        'description': 'Earned 100 reputation points',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      'reputation_500': {
        'name': 'Expert',
        'description': 'Earned 500 reputation points',
        'icon': Icons.workspace_premium,
        'color': Colors.red,
      },
      'mentor': {
        'name': 'Mentor',
        'description': 'Helped 50 people with answers',
        'icon': Icons.school,
        'color': Colors.teal,
      },
    };

    return badgeMap[badgeId] ??
        {
          'name': 'Unknown Badge',
          'description': '',
          'icon': Icons.star,
          'color': Colors.grey,
        };
  }

  // Deprecated - badges are now handled by backend
  @Deprecated(
    'Badges are now handled by the backend. This method is kept for backward compatibility but does nothing.',
  )
  static Future<void> checkBadgeUnlocks(
    String userEmail,
    int reputation,
  ) async {
    // Badges are now handled by the backend
  }

  // Deprecated - use getUserBadges() instead
  @Deprecated(
    'Use getUserBadges() instead. This method is kept for backward compatibility.',
  )
  static Future<List<String>> getUserBadgesDeprecated(String userEmail) async {
    final badges = await getUserBadges();
    return badges.map((b) => b['id'] as String).toList();
  }

  // Deprecated - badge history is now handled by backend
  @Deprecated(
    'Badge history is now handled by the backend. This method is kept for backward compatibility but does nothing.',
  )
  static Future<List<Map<String, dynamic>>> getBadgeHistory(
    String userEmail,
  ) async {
    return [];
  }
}

// Privilege system
class PrivilegeSystem {
  static Future<List<Map<String, dynamic>>> getUserPrivileges() async {
    try {
      final response = await ApiService().get(ApiConfig.getPrivileges);
      if (response['success'] == true) {
        final privilegesData = response['privileges'] as List? ?? [];
        return privilegesData.map((p) => p as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      // Fallback to local calculation if API fails
      final reputationData = await ReputationSystem.getReputation();
      final reputation = reputationData['reputation'] as int? ?? 0;

      const privilegeMap = {
        'edit_questions': {
          'requirement': 100,
          'name': 'Edit Questions',
          'description': 'Can edit other users\' questions',
          'icon': Icons.edit,
        },
        'moderate_content': {
          'requirement': 500,
          'name': 'Moderate Content',
          'description': 'Can flag and moderate inappropriate content',
          'icon': Icons.gavel,
        },
        'view_deleted': {
          'requirement': 1000,
          'name': 'View Deleted Content',
          'description': 'Can view recently deleted questions and answers',
          'icon': Icons.visibility,
        },
        'create_tags': {
          'requirement': 1500,
          'name': 'Create Tags',
          'description': 'Can create new tags for questions',
          'icon': Icons.tag,
        },
      };

      return privilegeMap.entries
          .where((entry) => reputation >= (entry.value['requirement'] as int))
          .map(
            (entry) => {
              'id': entry.key,
              'name': entry.value['name'],
              'description': entry.value['description'],
              'icon': entry.value['icon'],
            },
          )
          .toList();
    }
  }

  static bool hasPrivilege(
    String privilege,
    List<Map<String, dynamic>> userPrivileges,
  ) {
    return userPrivileges.any((p) => p['id'] == privilege);
  }
}

// Leaderboard system
class LeaderboardSystem {
  static Future<List<Map<String, dynamic>>> getTopUsers({
    int limit = 10,
  }) async {
    try {
      final response = await ApiService().get(
        '${ApiConfig.getLeaderboard}?limit=$limit',
      );
      if (response['success'] == true) {
        final leaderboardData = response['leaderboard'] as List? ?? [];
        return leaderboardData.map((u) => u as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      // Fallback to local calculation if API fails
      final prefs = await SharedPreferences.getInstance();
      final allUsersRaw = prefs.getString('all_users') ?? '[]';
      final allUsers = (json.decode(allUsersRaw) as List)
          .cast<Map<String, dynamic>>();

      final usersWithRep = <Map<String, dynamic>>[];

      for (final user in allUsers) {
        final email = user['email'] as String;
        final reputationData = await ReputationSystem.getReputation();
        final badges = await BadgeSystem.getUserBadges();

        usersWithRep.add({
          'rank': 0, // Will be set after sorting
          'user': {
            'id': email,
            'name': user['name'],
            'reputation': reputationData['reputation'] ?? 0,
            'badges': badges,
          },
        });
      }

      // Sort by reputation descending
      usersWithRep.sort(
        (a, b) => ((b['user'] as Map)['reputation'] as int).compareTo(
          (a['user'] as Map)['reputation'] as int,
        ),
      );

      // Set ranks
      for (int i = 0; i < usersWithRep.length; i++) {
        usersWithRep[i]['rank'] = i + 1;
      }

      return usersWithRep.take(limit).toList();
    }
  }

  static Future<Map<String, dynamic>> getUserRank(String userEmail) async {
    final topUsers = await getTopUsers(limit: 1000);
    final userIndex = topUsers.indexWhere(
      (user) => (user['user'] as Map)['id'] == userEmail,
    );

    if (userIndex == -1) {
      return {'rank': -1, 'total': topUsers.length};
    }

    return {'rank': userIndex + 1, 'total': topUsers.length};
  }
}
