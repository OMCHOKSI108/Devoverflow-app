//lib/features/search/presentation/cubit/search_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  final ApiService _apiService = ApiService();

  Future<void> searchQuestions(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }
    try {
      emit(SearchLoading());
      final results = await _apiService.searchQuestions(query: query);
      emit(SearchLoaded(searchResults: results, query: query));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
