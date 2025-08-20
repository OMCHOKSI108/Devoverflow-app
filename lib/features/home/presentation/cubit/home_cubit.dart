// lib/features/home/presentation/cubit/home_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/core/services/api_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  final ApiService _apiService = ApiService();

  Future<void> fetchQuestions() async {
    try {
      emit(HomeLoading());

      // Fetch questions from the API
      final questions = await _apiService.getAllQuestions();
      emit(HomeLoaded(questions));
    } catch (e) {
      emit(HomeError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  // Method to refresh questions after adding a new one
  Future<void> refreshQuestions() async {
    try {
      // Don't emit loading state to avoid UI flicker
      final questions = await _apiService.getAllQuestions();
      emit(HomeLoaded(questions));
    } catch (e) {
      emit(HomeError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
