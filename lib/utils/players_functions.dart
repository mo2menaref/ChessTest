import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class PlayerFunctionManager {
  final FirestoreService _firestoreService = FirestoreService();

  // Remove controllers from here - pass them as parameters instead

  Future<bool?> showDeletePlayerDialog({
    required BuildContext context,
    required String playerId,
    required String playerName,
    required String roomId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Player'),
        content: Text('Are you sure you want to remove "$playerName" from the room?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deletePlayer(roomId, playerId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player removed successfully')),
        );
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        return false;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> loadSelections(String roomId) async {
    try {
      final selections = await _firestoreService.getRoomSelections(roomId);
      return selections;
    } catch (e) {
      debugPrint('Error loading selections: $e');
      return null;
    }
  }

  Future<void> saveSelections({
    required String roomId,
    String? selectedPlayer1,
    String? selectedPlayer2,
    String? selectedPlayer3,
  }) async {
    try {
      await _firestoreService.updateRoomSelections(
        roomId,
        selectedPlayer1,
        selectedPlayer2,
        selectedPlayer3,
      );
    } catch (e) {
      debugPrint('Error saving selections: $e');
    }
  }

  Future<bool> updatePoints({
    required BuildContext context,
    required String roomId,
    required String playerId,
    required TextEditingController pointsController,
  }) async {
    final pointsText = pointsController.text.trim();
    if (pointsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter points')),
      );
      return false;
    }

    final points = int.tryParse(pointsText);
    if (points == null || points < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid number')),
      );
      return false;
    }

    try {
      await _firestoreService.updatePlayerPoints(roomId, playerId, points);
      Navigator.pop(context);
      pointsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points updated successfully!')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return false;
    }
  }

  Future<bool> addPlayer({
    required BuildContext context,
    required String roomId,
    required TextEditingController playerNameController,
  }) async {
    if (playerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a player name')),
      );
      return false;
    }

    try {
      await _firestoreService.addPlayer(roomId, playerNameController.text.trim());
      Navigator.pop(context);
      playerNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Player added successfully!')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return false;
    }
  }



  Future<bool> resetWeeklyPoints({
    required BuildContext context,
    required String roomId,
    required VoidCallback onSuccess,
  }) async {
    // First, get current session number to decide which buttons to show
    DocumentSnapshot roomDoc = await _firestoreService.getRoomDetails(roomId);
    final roomData = roomDoc.data() as Map<String, dynamic>?;
    final currentWeek = roomData?['currentWeekNumber'] ?? 1;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔄 Reset Weekly Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Set current #1 weekly scorer as "Top Scorer of the Week ⭐"'),
            Text('• Add ⚡ symbol to players with 20+ weekly points'),
            Text('• Reset all weekly points to 0'),
            Text('• Start a new week (Session #${currentWeek + 1})'),
            SizedBox(height: 12),
            if (currentWeek > 1) ...[
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Made a mistake?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    Text(
                      'Click "Undo Session" to decrease session number immediately.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Show different buttons based on session number
          if (currentWeek > 1) ...[
            // Show Undo button that works immediately
            TextButton.icon(
              onPressed: () => Navigator.pop(context, 'undo'), // Return 'undo' action
              icon: Icon(Icons.undo, color: Colors.orange),
              label: Text(
                'Undo Session',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ] else ...[
            // Show Cancel button if session = 1 (can't undo)
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text('Cancel'),
            ),
          ],

          // Reset Week button (always present)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('🔄 Reset Week'),
          ),
        ],
      ),
    );

    // Handle the different actions based on what button was pressed
    if (result == 'reset') {
      // User wants to reset weekly points
      try {
        await _firestoreService.resetWeeklyPoints(roomId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Weekly points reset! New week started.'),
            backgroundColor: Colors.green,
          ),
        );
        onSuccess(); // Call the callback to reload data
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } else if (result == 'undo') {
      // User wants to undo session - do it immediately without another dialog
      try {
        await _firestoreService.undoSessionIncrement(roomId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Session number decreased by 1'),
            backgroundColor: Colors.orange,
          ),
        );
        onSuccess(); // Call the callback to reload data
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    // User cancelled or any other case
    return false;
  }
}