import 'package:mongo_dart/mongo_dart.dart';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  factory MongoDBService() => _instance;
  MongoDBService._internal();

  Db? _db;
  
  // Replace with your MongoDB Atlas connection string
  // Format: mongodb+srv://<username>:<password>@cluster.mongodb.net/stock_archery?retryWrites=true&w=majority
  static const String mongoUri = "mongodb+srv://harsh:whateveridc@cluster0.d4gsz5f.mongodb.net/?appName=Cluster0";
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

  Future<void> close() async {
    await _db?.close();
  }
}
