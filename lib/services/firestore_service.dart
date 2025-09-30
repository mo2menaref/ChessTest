import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Updated updatePlayerPoints to use weeklyPoints field
  Future<void> updatePlayerPoints(String roomId, String playerId, int newPoints) async {
    try {
      print('🔄 Updating points for player $playerId to $newPoints');

      // Get current points to calculate difference
      DocumentSnapshot playerDoc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .doc(playerId)
          .get();

      if (playerDoc.exists) {
        final playerData = playerDoc.data() as Map<String, dynamic>;
        final currentPoints = (playerData['points'] ?? 0) as int;
        final currentWeeklyPoints = (playerData['weeklyPoints'] ?? 0) as int;
        final pointsDifference = newPoints - currentPoints;

        print('📊 Current: $currentPoints, New: $newPoints, Difference: $pointsDifference');

        // Update both main points and weekly points
        if (pointsDifference > 0) {
          // Only add to weekly points if it's an increase
          await _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('players')
              .doc(playerId)
              .update({
            'points': newPoints,
            'weeklyPoints': currentWeeklyPoints + pointsDifference,
          });
          print('✅ Added $pointsDifference to weekly points');
        } else {
          // Just update main points for decreases
          await _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('players')
              .doc(playerId)
              .update({'points': newPoints});
          print('✅ Updated main points only');
        }
      }
    } catch (e) {
      print('❌ Failed to update player points: $e');
      throw Exception('Failed to update player points: $e');
    }
  }

  Future<void> resetWeeklyPoints(String roomId) async {
    try {
      print('🔄 Starting weekly points reset for room: $roomId');

      // Get all players ordered by weekly points
      QuerySnapshot playersSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .orderBy('weeklyPoints', descending: true)
          .get();

      if (playersSnapshot.docs.isEmpty) {
        throw Exception('No players found in room');
      }

      String? winnerId;
      WriteBatch batch = _firestore.batch();

      for (int i = 0; i < playersSnapshot.docs.length; i++) {
        final playerDoc = playersSnapshot.docs[i];
        final playerData = playerDoc.data() as Map<String, dynamic>;
        final weeklyPoints = (playerData['weeklyPoints'] ?? 0) as int;
        final playerId = playerDoc.id;

        // Set the first player (highest weekly points) as winner
        if (i == 0 && weeklyPoints > 0) {
          winnerId = playerId;
          print('🏆 Weekly winner: ${playerData['name']} with $weeklyPoints points');
        }

        // Add electric symbol if player has 20+ weekly points
        Map<String, dynamic> updates = {'weeklyPoints': 0}; // Reset weekly points

        if (weeklyPoints >= 20) {
          updates['hasElectric'] = true;
          updates['electricAddedAt'] = FieldValue.serverTimestamp();
          print('⚡ Adding electric symbol to: ${playerData['name']}');
        }

        batch.update(playerDoc.reference, updates);
      }

      // Update room with winner selection
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      batch.update(roomRef, {
        'selectedPlayer1': winnerId,
        'currentWeekNumber': FieldValue.increment(1),
        'lastResetAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('✅ Weekly points reset completed successfully');
    } catch (e) {
      print('❌ Error in resetWeeklyPoints: $e');
      throw Exception('Failed to reset weekly points: $e');
    }
  }

  // Update room selections method
  Future<void> updateRoomSelections(String roomId, String? player1Id, String? player2Id, String? player3Id) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'selectedPlayer1': player1Id,
        'selectedPlayer2': player2Id,
        'selectedPlayer3': player3Id,
        'selectionsUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update selections: $e');
    }
  }

  // Get room selections method
  Future<Map<String, dynamic>?> getRoomSelections(String roomId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'selectedPlayer1': data['selectedPlayer1'],
          'selectedPlayer2': data['selectedPlayer2'],
          'selectedPlayer3': data['selectedPlayer3'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ...keep all existing methods unchanged...
  Future<String> createUser(String name) async {
    try {
      QuerySnapshot existingUsers = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        String existingUserId = existingUsers.docs.first.id;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', existingUserId);
        await prefs.setString('userName', name);
        return existingUserId;
      } else {
        DocumentReference userDoc = await _firestore.collection('users').add({
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userDoc.id);
        await prefs.setString('userName', name);

        return userDoc.id;
      }
    } catch (e) {
      throw Exception('Failed to create or get user: $e');
    }
  }

  Future<bool> doesRoomExist(String roomId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
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

  Future<String> createRoom(String name, String ownerId) async {
    try {
      DocumentReference roomDoc = await _firestore.collection('rooms').add({
        'name': name,
        'ownerId': ownerId,
        'currentWeekNumber': 1,
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
      // Delete players
      QuerySnapshot playersSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('players')
          .get();

      for (QueryDocumentSnapshot playerDoc in playersSnapshot.docs) {
        await playerDoc.reference.delete();
      }

      // Delete room
      await _firestore.collection('rooms').doc(roomId).delete();
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  Future<String> addPlayer(String roomId, String playerName) async {
    try {
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
        'weeklyPoints': 0,  // Add weeklyPoints field
        'hasElectric': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return playerDoc.id;
    } catch (e) {
      throw Exception('Failed to add player: $e');
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