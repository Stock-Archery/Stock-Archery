// import 'package:flutter/material.dart';
// import '../services/mongodb_service.dart';

// class StockViewModel extends ChangeNotifier {
//   final MongoDBService _mongoService = MongoDBService();
//   
//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   List<String> _selectedStocks = [];
//   List<String> get selectedStocks => _selectedStocks;

//   List<String> _currentLiveStocks = [];
//   List<String> get currentLiveStocks => _currentLiveStocks;

//   List<String> _allStocks = [];
//   List<String> get allStocks => _allStocks;

//   String _searchQuery = "";
//   String get searchQuery => _searchQuery;

//   List<String> get filteredStocks {
//     if (_searchQuery.isEmpty) return _allStocks;
//     return _allStocks
//         .where((stock) => stock.toLowerCase().contains(_searchQuery.toLowerCase()))
//         .toList();
//   }

//   StockViewModel() {
//     loadAllStocks();
//     loadCurrentRecommendations();
//   }

//   Future<void> loadAllStocks() async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       print("Attempting to load FNO stocks from: ${MongoDBService.mongoUri}");
//       _allStocks = await _mongoService.getFnoStocks();
//       print("Successfully loaded ${_allStocks.length} stocks.");
//     } catch (e) {
//       print("Error loading FNO stocks: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> refreshFnoStocks() async {
//     _isLoading = true;
//     notifyListeners();
//     try {
//       // Assuming server is running locally on port 3000
//       // In a real app, this would be a remote URL
//       final response = await _mongoService.triggerRefresh();
//       if (response) {
//         await loadAllStocks();
//       }
//     } catch (e) {
//       print("Error refreshing FNO stocks: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> loadCurrentRecommendations() async {
//     _isLoading = true;
//     notifyListeners();
//     
//     try {
//       _currentLiveStocks = await _mongoService.getRecommendations();
//       // We keep _selectedStocks empty initially for a fresh selection UX
//       _selectedStocks = []; 
//     } catch (e) {
//       print("Error loading recommendations: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   void clearSelections() {
//     _selectedStocks = [];
//     notifyListeners();
//   }

//   void copyCurrentToSelection() {
//     _selectedStocks = List.from(_currentLiveStocks);
//     notifyListeners();
//   }

//   void toggleStockSelection(String stock) {
//     if (_selectedStocks.contains(stock)) {
//       _selectedStocks.remove(stock);
//     } else {
//       if (_selectedStocks.length < 5) {
//         _selectedStocks.add(stock);
//       }
//     }
//     notifyListeners();
//   }

//   void setSearchQuery(String query) {
//     _searchQuery = query;
//     notifyListeners();
//   }

//   Future<bool> saveRecommendations() async {
//     if (_selectedStocks.length != 5) return false;
//     
//     _isLoading = true;
//     notifyListeners();
//     
//     try {
//       await _mongoService.updateRecommendations(_selectedStocks);
//       _currentLiveStocks = List.from(_selectedStocks);
//       _selectedStocks = [];
//       _isLoading = false;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       print("Error saving recommendations: $e");
//       _isLoading = false;
//       notifyListeners();
//       return false;
//     }
//   }
// }
