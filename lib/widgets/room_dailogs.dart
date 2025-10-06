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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Helper function to update points and text field
          void updatePoints(int change) {
            int currentValue = int.tryParse(pointsController.text) ?? 0;
            int newValue = (currentValue + change).clamp(0, 999); // Prevent negative points and cap at 999
            pointsController.text = newValue.toString();
            setState(() {}); // Refresh the dialog
          }

          return AlertDialog(
            title: Text('Update Points for $playerName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current points display
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Current Points: $currentPoints',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Points input with -1 and +1 buttons
                Row(
                  children: [
                    // -1 Button
                    IconButton(
                      onPressed: () => updatePoints(-1),
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      tooltip: 'Decrease by 1',
                    ),

                    // Text Field
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        decoration: InputDecoration(
                          labelText: 'Points',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          setState(() {}); // Refresh when user types
                        },
                      ),
                    ),

                    // +1 Button
                    IconButton(
                      onPressed: () => updatePoints(1),
                      icon: Icon(Icons.add_circle, color: Colors.green),
                      tooltip: 'Increase by 1',
                    ),
                  ],
                ),

                SizedBox(height: 5),


                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 5,
                  children: [
                    // +2 Button
                    ElevatedButton(
                      onPressed: () => updatePoints(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('+2'),
                    ),

                    // +3 Button
                    ElevatedButton(
                      onPressed: () => updatePoints(3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        foregroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('+3'),
                    ),

                    // +4 Button
                    ElevatedButton(
                      onPressed: () => updatePoints(4),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[100],
                        foregroundColor: Colors.orange[700],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('+4'),
                    ),

                    // +5 Button
                    ElevatedButton(
                      onPressed: () => updatePoints(5),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100],
                        foregroundColor: Colors.purple[700],
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('+5'),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Points difference indicator
                Builder(
                  builder: (context) {
                    int newPoints = int.tryParse(pointsController.text) ?? 0;
                    int difference = newPoints - currentPoints;

                    if (difference == 0) return SizedBox.shrink();

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: difference > 0 ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: difference > 0 ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        difference > 0 ? '+$difference points' : '$difference points',
                        style: TextStyle(
                          color: difference > 0 ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text('Update'),
              ),
            ],
          );
        },
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
            Text(
              'Share this link with players to let them view the leaderboard:',
            ),
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
          ElevatedButton(onPressed: onAdd, child: Text('Add')),
        ],
      ),
    );
  }
}