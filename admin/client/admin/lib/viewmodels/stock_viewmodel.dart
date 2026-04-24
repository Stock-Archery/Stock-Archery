import 'package:flutter/material.dart';
import '../services/mongodb_service.dart';

class StockViewModel extends ChangeNotifier {
  final MongoDBService _mongoService = MongoDBService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _selectedStocks = [];
  List<String> get selectedStocks => _selectedStocks;

  List<String> _allStocks = [];
  List<String> get allStocks => _allStocks;

  StockViewModel() {
    loadAllStocks();
    loadCurrentRecommendations();
  }

  Future<void> loadAllStocks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allStocks = await _mongoService.getFnoStocks();
    } catch (e) {
      print("Error loading FNO stocks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFnoStocks() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Assuming server is running locally on port 3000
      // In a real app, this would be a remote URL
      final response = await _mongoService.triggerRefresh();
      if (response) {
        await loadAllStocks();
      }
    } catch (e) {
      print("Error refreshing FNO stocks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentRecommendations() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _selectedStocks = await _mongoService.getRecommendations();
    } catch (e) {
      print("Error loading recommendations: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleStockSelection(String stock) {
    if (_selectedStocks.contains(stock)) {
      _selectedStocks.remove(stock);
    } else {
      if (_selectedStocks.length < 5) {
        _selectedStocks.add(stock);
      }
    }
    notifyListeners();
  }

  Future<bool> saveRecommendations() async {
    if (_selectedStocks.length != 5) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _mongoService.updateRecommendations(_selectedStocks);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error saving recommendations: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
