import 'package:mongo_dart/mongo_dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  Db? _db;
  
  // Use environment variables for sensitive data
  static String get mongoUri => dotenv.get('mongoUri', fallback: '');
  static const String collectionName = "recommendations";
  static const String fnoCollectionName = "fnostocks";
  static const String serverUrl = "http://10.16.4.230:3000"; // Update this for production

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

  Future<void> updateRecommendations(List<String> stocks) async {
    await connect();
    final collection = _db!.collection(collectionName);
    
    // We update the document with type 'current_recommendations'
    await collection.update(
      where.eq('type', 'current_recommendations'),
      {
        '\$set': {
          'stocks': stocks,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      },
      upsert: true,
    );
  }

  Future<List<String>> getRecommendations() async {
    await connect();
    final collection = _db!.collection(collectionName);
    final doc = await collection.findOne(where.eq('type', 'current_recommendations'));
    
    if (doc != null && doc['stocks'] != null) {
      return List<String>.from(doc['stocks']);
    }
    return [];
  }

  Future<List<String>> getFnoStocks() async {
    await connect();
    final collection = _db!.collection(fnoCollectionName);
    final docs = await collection.find().toList();
    
    return docs.map((doc) => doc['symbol'] as String).toList();
  }

  Future<bool> triggerRefresh() async {
    try {
      final response = await http.post(Uri.parse('$serverUrl/refresh-fno'));
      return response.statusCode == 200;
    } catch (e) {
      print("Error triggering refresh: $e");
      return false;
    }
  }

  Future<void> close() async {
    await _db?.close();
  }
}
