import 'package:flutter/material.dart';

class RoomDialogs {
  static void showUpdatePointsDialog({
    required BuildContext context,
    required String playerId,
    required String playerName,
    required int currentPoints,
    required TextEditingController pointsController,
    required VoidCallback onUpdate,
  }) {
    pointsController.text = currentPoints.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Points for $playerName'),
        content: TextField(
          controller: pointsController,
          decoration: InputDecoration(
            labelText: 'Points',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pointsController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onUpdate,
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  static void showShareRoomDialog({
    required BuildContext context,
    required String roomId,
  }) {
    final roomUrl = 'https://chess-test-f33d1.web.app/rooms/$roomId';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this link with players to let them view the leaderboard:'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                roomUrl,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Players can view scores without making changes',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
            child: Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  static void showAddPlayerDialog({
    required BuildContext context,
    required TextEditingController playerNameController,
    required VoidCallback onAdd,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Player'),
        content: TextField(
          controller: playerNameController,
          decoration: InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              playerNameController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onAdd,
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}