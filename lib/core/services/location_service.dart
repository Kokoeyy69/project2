import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neopay_ai/core/models/agent_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'agents';

  Future<void> seedGlobalAgentsIfEmpty() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      
      if (snapshot.docs.isEmpty) {
        final globalAgents = [
          AgentModel(
            id: '',
            name: 'NeoPay Asia Hub',
            latitude: 1.290270,
            longitude: 103.851959,
            city: 'Singapore',
          ),
          AgentModel(
            id: '',
            name: 'NeoPay JP Exchange',
            latitude: 35.6762,
            longitude: 139.6503,
            city: 'Tokyo',
          ),
          AgentModel(
            id: '',
            name: 'NeoPay Wall Street',
            latitude: 40.7128,
            longitude: -74.0060,
            city: 'New York',
          ),
          AgentModel(
            id: '',
            name: 'NeoPay Europe HQ',
            latitude: 51.5074,
            longitude: -0.1278,
            city: 'London',
          ),
          AgentModel(
            id: '',
            name: 'NeoPay MENA Branch',
            latitude: 25.2048,
            longitude: 55.2708,
            city: 'Dubai',
          ),
          AgentModel(
            id: '',
            name: 'NeoPay ID Base',
            latitude: -6.2615,
            longitude: 106.8106,
            city: 'Jakarta Selatan',
          ),
          AgentModel(
            id: '',
            name: 'NeoPay West Java',
            latitude: -6.2383,
            longitude: 107.0017,
            city: 'Bekasi',
          ),
        ];

        for (var agent in globalAgents) {
          await _firestore.collection(_collectionName).add(agent.toMap());
        }
      }
    } catch (e) {
      print('Error seeding global agents: $e');
    }
  }

  Stream<List<AgentModel>> getAgentsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AgentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}