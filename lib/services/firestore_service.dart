import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<String> createUser(String name) async {
    try {
      DocumentReference userDoc = await _firestore.collection('users').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Save user session locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userDoc.id);
      await prefs.setString('userName', name);
      
      return userDoc.id;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      String? userName = prefs.getString('userName');
      
      if (userId != null && userName != null) {
        return {
          'userId': userId,
          'name': userName,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
  }

  // Room operations
  Future<String> createRoom(String name, String ownerId) async {
    try {
      DocumentReference roomDoc = await _firestore.collection('rooms').add({
        'name': name,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return roomDoc.id;
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  Stream<QuerySnapshot> getRooms(String ownerId) {
    return _firestore
        .collection('rooms')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      // Delete all players in the room first
      QuerySnapshot playersSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .get();
      
      for (QueryDocumentSnapshot playerDoc in playersSnapshot.docs) {
        await playerDoc.reference.delete();
      }
      
      // Delete the room
      await _firestore.collection('rooms').doc(roomId).delete();
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  // Player operations
  Future<String> addPlayer(String roomId, String playerName) async {
    try {
      // Check if room has less than 6 players
      QuerySnapshot playersSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .get();
      
      if (playersSnapshot.docs.length >= 6) {
        throw Exception('Room is full (maximum 6 players)');
      }
      
      DocumentReference playerDoc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .add({
        'name': playerName,
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return playerDoc.id;
    } catch (e) {
      throw Exception('Failed to add player: $e');
    }
  }

  Future<void> updatePlayerPoints(String roomId, String playerId, int newPoints) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .doc(playerId)
          .update({'points': newPoints});
    } catch (e) {
      throw Exception('Failed to update player points: $e');
    }
  }

  Future<void> deletePlayer(String roomId, String playerId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .doc(playerId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete player: $e');
    }
  }

  Stream<QuerySnapshot> streamRoomPlayers(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .orderBy('points', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getRoomDetails(String roomId) {
    return _firestore.collection('rooms').doc(roomId).get();
  }
}