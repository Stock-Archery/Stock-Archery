import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StocksService {
  static final StocksService _instance = StocksService._internal();
  factory StocksService() => _instance;
  StocksService._internal();

  Db? _db;
  
  static String get mongoUri => dotenv.get('mongoUri', fallback: '');
  static const String collectionName = "recommendations";

  Future<void> connect() async {
    if (_db != null && _db!.isConnected) return;
    
    try {
      _db = await Db.create(mongoUri);
      await _db!.open();
      print("Connected to MongoDB Atlas");
    } catch (e) {
      print("Error connecting to MongoDB: $e");
    }
  }

  Future<List<String>> getRecommendations() async {
    try {
      await connect();
      if (_db == null) return [];
      
      final collection = _db!.collection(collectionName);
      final doc = await collection.findOne(where.eq('type', 'current_recommendations'));
      
      if (doc != null && doc['stocks'] != null) {
        return List<String>.from(doc['stocks']);
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
    }
    return [];
  }

  Future<void> close() async {
    await _db?.close();
  }
}
