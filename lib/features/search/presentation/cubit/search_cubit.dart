//lib/features/search/presentation/cubit/search_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/question_model.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
SearchCubit() : super(SearchInitial());

// In a real app, this would be your full question list or an API call.
final List<Question> _allQuestions = [
Question(id: '1', title: 'How to manage state in a large Flutter application?', author: 'Jane Doe', authorImageUrl: 'https://i.pravatar.cc/150?u=jane_doe', votes: 125, answers: 12, tags: ['flutter', 'state-management', 'provider'], timestamp: DateTime.now().subtract(const Duration(hours: 2))),
Question(id: '2', title: 'What is the best way to handle API calls with error handling in Dart?', author: 'John Smith', authorImageUrl: 'https://i.pravatar.cc/150?u=john_smith', votes: 98, answers: 8, tags: ['dart', 'api', 'http'], timestamp: DateTime.now().subtract(const Duration(days: 1))),
Question(id: '3', title: 'How to implement a clean architecture in Node.js?', author: 'Alex Johnson', authorImageUrl: 'https://i.pravatar.cc/150?u=alex_johnson', votes: 210, answers: 15, tags: ['node.js', 'architecture', 'backend'], timestamp: DateTime.now().subtract(const Duration(days: 3))),
];

Future<void> searchQuestions(String query) async {
if (query.isEmpty) {
emit(SearchInitial());
return;
}
try {
emit(SearchLoading());
// Simulate a network search
await Future.delayed(const Duration(milliseconds: 500));
final results = _allQuestions
    .where((q) =>
q.title.toLowerCase().contains(query.toLowerCase()) ||
q.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
    .toList();
emit(SearchLoaded(searchResults: results, query: query));
} catch (e) {
emit(const SearchError('Failed to perform search.'));
}
}
}
