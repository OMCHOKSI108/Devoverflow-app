import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'question_detail.dart';
import 'api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allQuestions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  List<Map<String, dynamic>> _searchHistory = [];
  List<Map<String, dynamic>> _savedSearches = [];
  final List<String> _selectedTags = [];
  String _sortBy = 'relevance';
  bool _showUnansweredOnly = false;
  bool _isLoading = true;
  String _currentQuery = '';

  // Available tags for filtering
  final List<String> _availableTags = [
    'flutter',
    'dart',
    'state-management',
    'ui',
    'api',
    'database',
    'firebase',
    'provider',
    'riverpod',
    'bloc',
    'getx',
    'mobx',
    'sqlite',
    'hive',
    'shared-preferences',
    'http',
    'dio',
    'json',
    'async',
    'future',
    'stream',
    'animation',
    'navigation',
    'routing',
    'testing',
    'debugging',
    'performance',
    'security',
    'deployment',
    'ci-cd',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Load search history
    final historyRaw = prefs.getString('search_history');
    if (historyRaw != null) {
      _searchHistory = (json.decode(historyRaw) as List)
          .cast<Map<String, dynamic>>();
    }

    // Load saved searches
    final savedRaw = prefs.getString('saved_searches');
    if (savedRaw != null) {
      _savedSearches = (json.decode(savedRaw) as List)
          .cast<Map<String, dynamic>>();
    }

    // Initialize with empty results - search will be performed when user types
    setState(() {
      _allQuestions = [];
      _filteredQuestions = [];
      _isLoading = false;
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredQuestions = _allQuestions;
        _currentQuery = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _currentQuery = query;
      _isLoading = true;
    });

    // Add to search history
    _addToSearchHistory(query);

    try {
      // Try API search first
      final response = await ApiService().searchQuestions(query);

      if (response['success'] == true) {
        final questionsData = response['questions'] as List? ?? [];
        final apiQuestions = questionsData
            .map((q) => q as Map<String, dynamic>)
            .toList();

        // Apply local filters to API results
        var filtered = apiQuestions;

        // Tag filtering
        if (_selectedTags.isNotEmpty) {
          filtered = filtered.where((question) {
            final questionTags = List<String>.from(question['tags'] ?? []);
            return _selectedTags.every((tag) => questionTags.contains(tag));
          }).toList();
        }

        // Unanswered filter
        if (_showUnansweredOnly) {
          filtered = filtered
              .where((question) => !(question['isAnswered'] ?? false))
              .toList();
        }

        // Sorting
        filtered.sort((a, b) {
          switch (_sortBy) {
            case 'newest':
              final aTime = DateTime.parse(
                a['createdAt'] ?? a['timestamp'] ?? DateTime.now().toString(),
              );
              final bTime = DateTime.parse(
                b['createdAt'] ?? b['timestamp'] ?? DateTime.now().toString(),
              );
              return bTime.compareTo(aTime);
            case 'oldest':
              final aTime = DateTime.parse(
                a['createdAt'] ?? a['timestamp'] ?? DateTime.now().toString(),
              );
              final bTime = DateTime.parse(
                b['createdAt'] ?? b['timestamp'] ?? DateTime.now().toString(),
              );
              return aTime.compareTo(bTime);
            case 'most-voted':
              return (b['votes'] ?? b['voteCount'] ?? 0).compareTo(
                a['votes'] ?? a['voteCount'] ?? 0,
              );
            case 'least-voted':
              return (a['votes'] ?? a['voteCount'] ?? 0).compareTo(
                b['votes'] ?? b['voteCount'] ?? 0,
              );
            case 'most-answered':
              final aAnswers =
                  (a['answers'] as List?)?.length ?? (a['answerCount'] ?? 0);
              final bAnswers =
                  (b['answers'] as List?)?.length ?? (b['answerCount'] ?? 0);
              return bAnswers.compareTo(aAnswers);
            default: // relevance
              return 0; // API already returns relevance-sorted results
          }
        });

        setState(() {
          _filteredQuestions = filtered;
          _isLoading = false;
        });
      } else {
        // API failed, fallback to local search
        _performLocalSearch(query);
      }
    } catch (e) {
      // API error, fallback to local search
      _performLocalSearch(query);
    }
  }

  void _performLocalSearch(String query) {
    // Perform semantic search on local data
    final results = _semanticSearch(query);

    // Apply filters
    var filtered = results;

    // Tag filtering
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((question) {
        final questionTags = List<String>.from(question['tags'] ?? []);
        return _selectedTags.every((tag) => questionTags.contains(tag));
      }).toList();
    }

    // Unanswered filter
    if (_showUnansweredOnly) {
      filtered = filtered
          .where((question) => !(question['isAnswered'] ?? false))
          .toList();
    }

    // Sorting
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'newest':
          final aTime = DateTime.parse(a['timestamp']);
          final bTime = DateTime.parse(b['timestamp']);
          return bTime.compareTo(aTime);
        case 'oldest':
          final aTime = DateTime.parse(a['timestamp']);
          final bTime = DateTime.parse(b['timestamp']);
          return aTime.compareTo(bTime);
        case 'most-voted':
          return (b['votes'] ?? 0).compareTo(a['votes'] ?? 0);
        case 'least-voted':
          return (a['votes'] ?? 0).compareTo(b['votes'] ?? 0);
        case 'most-answered':
          final aAnswers = (a['answers'] as List?)?.length ?? 0;
          final bAnswers = (b['answers'] as List?)?.length ?? 0;
          return bAnswers.compareTo(aAnswers);
        default: // relevance
          return _calculateRelevanceScore(
            b,
            query,
          ).compareTo(_calculateRelevanceScore(a, query));
      }
    });

    setState(() {
      _filteredQuestions = filtered;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _semanticSearch(String query) {
    final queryLower = query.toLowerCase();
    final queryWords = queryLower
        .split(' ')
        .where((word) => word.length > 2)
        .toList();

    return _allQuestions.where((question) {
      final title = (question['title'] ?? '').toLowerCase();
      final body = (question['body'] ?? '').toLowerCase();
      final tags = List<String>.from(
        question['tags'] ?? [],
      ).map((tag) => tag.toLowerCase()).toList();

      // Exact phrase match gets highest priority
      if (title.contains(queryLower) || body.contains(queryLower)) {
        return true;
      }

      // Tag match
      if (tags.any((tag) => tag.contains(queryLower))) {
        return true;
      }

      // Word-by-word match
      return queryWords.every(
        (word) =>
            title.contains(word) ||
            body.contains(word) ||
            tags.any((tag) => tag.contains(word)),
      );
    }).toList();
  }

  double _calculateRelevanceScore(Map<String, dynamic> question, String query) {
    final queryLower = query.toLowerCase();
    final title = (question['title'] ?? '').toLowerCase();
    final body = (question['body'] ?? '').toLowerCase();
    final tags = List<String>.from(question['tags'] ?? []);

    double score = 0;

    // Title matches get highest weight
    if (title.contains(queryLower)) {
      score += 10;
    }

    // Tag matches get high weight
    if (tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
      score += 8;
    }

    // Body matches get medium weight
    if (body.contains(queryLower)) {
      score += 5;
    }

    // Votes and answers boost relevance
    score += (question['votes'] ?? 0) * 0.1;
    score += ((question['answers'] as List?)?.length ?? 0) * 0.5;

    // Recency boost (newer questions slightly more relevant)
    final questionDate = DateTime.parse(question['timestamp']);
    final daysSincePosted = DateTime.now().difference(questionDate).inDays;
    score += (30 - daysSincePosted.clamp(0, 30)) * 0.1;

    return score;
  }

  Future<void> _addToSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove if already exists
    _searchHistory.removeWhere((item) => item['query'] == query);

    // Add to beginning
    _searchHistory.insert(0, {
      'query': query,
      'timestamp': DateTime.now().toString(),
    });

    // Keep only last 10 searches
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.take(10).toList();
    }

    await prefs.setString('search_history', json.encode(_searchHistory));
  }

  Future<void> _saveSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if already saved
    if (_savedSearches.any((item) => item['query'] == query)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Search already saved')));
      }
      return;
    }

    _savedSearches.insert(0, {
      'query': query,
      'timestamp': DateTime.now().toString(),
    });

    await prefs.setString('saved_searches', json.encode(_savedSearches));
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search saved successfully')),
      );
    }
  }

  Future<void> _deleteSavedSearch(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _savedSearches.removeAt(index);
    await prefs.setString('saved_searches', json.encode(_savedSearches));
    setState(() {});
  }

  List<Map<String, dynamic>> _getRelatedQuestions(String currentQuery) {
    if (currentQuery.isEmpty) return [];

    final queryWords = currentQuery
        .toLowerCase()
        .split(' ')
        .where((word) => word.length > 2)
        .toList();

    return _allQuestions
        .where((question) {
          final title = (question['title'] ?? '').toLowerCase();
          final tags = List<String>.from(
            question['tags'] ?? [],
          ).map((tag) => tag.toLowerCase()).toList();

          return queryWords.any(
            (word) =>
                title.contains(word) || tags.any((tag) => tag.contains(word)),
          );
        })
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF667eea),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search questions, topics, or tags...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          suffixIcon: _currentQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                        onSubmitted: _performSearch,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _performSearch(_searchController.text),
                              icon: const Icon(Icons.search),
                              label: const Text('Search'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF667eea),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showFiltersDialog(),
                            icon: const Icon(
                              Icons.filter_list,
                              color: Colors.white,
                            ),
                            tooltip: 'Filters',
                          ),
                          if (_currentQuery.isNotEmpty)
                            IconButton(
                              onPressed: () => _saveSearch(_currentQuery),
                              icon: const Icon(
                                Icons.bookmark_border,
                                color: Colors.white,
                              ),
                              tooltip: 'Save Search',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Search History & Saved Searches Tabs
                if (_currentQuery.isEmpty)
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Recent'),
                            Tab(text: 'Saved'),
                            Tab(text: 'Trending'),
                          ],
                          labelColor: Color(0xFF667eea),
                          unselectedLabelColor: Colors.grey,
                        ),
                        SizedBox(
                          height: 200,
                          child: TabBarView(
                            children: [
                              _buildSearchHistory(),
                              _buildSavedSearches(),
                              _buildTrendingTopics(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Results
                Expanded(
                  child: _currentQuery.isEmpty
                      ? _buildEmptyState()
                      : _buildSearchResults(),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text('No recent searches', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final item = _searchHistory[index];
        return ListTile(
          leading: const Icon(Icons.history, color: Color(0xFF667eea)),
          title: Text(item['query']),
          subtitle: Text(_formatTimestamp(item['timestamp'])),
          trailing: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _searchController.text = item['query'];
              _performSearch(item['query']);
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedSearches() {
    if (_savedSearches.isEmpty) {
      return const Center(
        child: Text('No saved searches', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _savedSearches.length,
      itemBuilder: (context, index) {
        final item = _savedSearches[index];
        return ListTile(
          leading: const Icon(Icons.bookmark, color: Color(0xFF667eea)),
          title: Text(item['query']),
          subtitle: Text(_formatTimestamp(item['timestamp'])),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _searchController.text = item['query'];
                  _performSearch(item['query']);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSavedSearch(index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingTopics() {
    final trendingTags = _getTrendingTags();

    return ListView.builder(
      itemCount: trendingTags.length,
      itemBuilder: (context, index) {
        final tag = trendingTags[index];
        return ListTile(
          leading: const Icon(Icons.trending_up, color: Colors.orange),
          title: Text('#${tag['tag']}'),
          subtitle: Text('${tag['count']} questions'),
          onTap: () {
            _searchController.text = tag['tag'];
            _performSearch(tag['tag']);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getTrendingTags() {
    final tagCounts = <String, int>{};

    for (final question in _allQuestions) {
      final tags = List<String>.from(question['tags'] ?? []);
      for (final tag in tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    return tagCounts.entries
        .map((entry) => {'tag': entry.key, 'count': entry.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int))
      ..take(10);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start searching for questions',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use keywords, tags, or phrases to find relevant questions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No questions found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount:
          _filteredQuestions.length +
          (_getRelatedQuestions(_currentQuery).isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredQuestions.length) {
          return _buildRelatedQuestions();
        }

        final question = _filteredQuestions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      QuestionDetailScreen(question: question),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question['title'] ?? 'Untitled Question',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question['body'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: (question['tags'] as List<dynamic>? ?? [])
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: const Color(
                              0xFF667eea,
                            ).withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                              color: Color(0xFF667eea),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.thumb_up, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${question['votes'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.comment, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${(question['answers'] as List?)?.length ?? 0} answers',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.visibility, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${question['views'] ?? 0} views',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimestamp(question['timestamp']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelatedQuestions() {
    final related = _getRelatedQuestions(_currentQuery);
    if (related.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          ...related.map(
            (question) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                question['title'] ?? 'Untitled',
                style: const TextStyle(fontSize: 14),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        QuestionDetailScreen(question: question),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Search Filters'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sort By
                const Text(
                  'Sort By',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text('Relevance'),
                    ),
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(
                      value: 'most-voted',
                      child: Text('Most Voted'),
                    ),
                    DropdownMenuItem(
                      value: 'least-voted',
                      child: Text('Least Voted'),
                    ),
                    DropdownMenuItem(
                      value: 'most-answered',
                      child: Text('Most Answered'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Tags
                const Text(
                  'Filter by Tags',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Unanswered Only
                Row(
                  children: [
                    Checkbox(
                      value: _showUnansweredOnly,
                      onChanged: (value) {
                        setState(() => _showUnansweredOnly = value ?? false);
                      },
                    ),
                    const Text('Show unanswered questions only'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                  _sortBy = 'relevance';
                  _showUnansweredOnly = false;
                });
              },
              child: const Text('Reset'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_currentQuery.isNotEmpty) {
                  _performSearch(_currentQuery);
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return 'Unknown';
    }
  }
}
