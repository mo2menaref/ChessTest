import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  RoomDetailScreenState createState() => RoomDetailScreenState();
}

class RoomDetailScreenState extends State<RoomDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();

  @override
  void dispose() {
    _playerNameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  // Add this method to RoomDetailScreenState
  _shareRoomLink() {
    final roomUrl = 'https://chess-test-f33d1.web.app/rooms/${widget.roomId}';

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
              // Copy to clipboard (you'll need to add clipboard package)
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

  _showAddPlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Player'),
        content: TextField(
          controller: _playerNameController,
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
              _playerNameController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addPlayer,
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  _addPlayer() async {
    if (_playerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a player name')),
      );
      return;
    }

    try {
      await _firestoreService.addPlayer(
        widget.roomId,
        _playerNameController.text.trim(),
      );
      Navigator.pop(context);
      _playerNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Player added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  _showUpdatePointsDialog(String playerId, String playerName, int currentPoints) {
    _pointsController.text = currentPoints.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Points for $playerName'),
        content: TextField(
          controller: _pointsController,
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
              _pointsController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updatePoints(playerId),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  _updatePoints(String playerId) async {
    final pointsText = _pointsController.text.trim();
    if (pointsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter points')),
      );
      return;
    }

    final points = int.tryParse(pointsText);
    if (points == null || points < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    try {
      await _firestoreService.updatePlayerPoints(
        widget.roomId,
        playerId,
        points,
      );
      Navigator.pop(context);
      _pointsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Points updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  _deletePlayer(String playerId, String playerName) async {
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
        await _firestoreService.deletePlayer(widget.roomId, playerId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player removed successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildRankingBadge(int rank) {
    Color color;
    IconData icon;
    
    switch (rank) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown;
        icon = Icons.emoji_events;
        break;
      default:
        color = Colors.green;
        icon = Icons.person;
    }

    return CircleAvatar(
      backgroundColor: color,
      radius: 20,
      child: rank <= 3 
          ? Icon(icon, color: Colors.white, size: 20)
          : Text('$rank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareRoomLink,
            tooltip: 'Share Room',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            color: Color(0xFFECFAEB),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.streamRoomPlayers(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final topPlayer = snapshot.data!.docs.first;
                  final topPlayerData = topPlayer.data() as Map<String, dynamic>;
                  final kingName = topPlayerData['name'] ?? 'Unknown Player';

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'The King of The Room is: ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            kingName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Text(
                        'No King Yet - Add Players!',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                    ],
                  );
                }
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.streamRoomPlayers(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final players = snapshot.data!.docs;

                if (players.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No players yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Text('Add players to start tracking points'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final playerData = player.data() as Map<String, dynamic>;
                    final rank = index + 1;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _buildRankingBadge(rank),
                        title: Text(
                          playerData['name'] ?? 'Unknown Player',
                          style: TextStyle(
                            fontWeight:FontWeight.bold ,
                          ),
                        ),
                        subtitle: Text('Rank #$rank'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${playerData['points'] ?? 0} pts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton(
                              onSelected: (value) {
                                if (value == 'update') {
                                  _showUpdatePointsDialog(
                                    player.id,
                                    playerData['name'] ?? 'Unknown Player',
                                    playerData['points'] ?? 0,
                                  );
                                } else if (value == 'delete') {
                                  _deletePlayer(
                                    player.id,
                                    playerData['name'] ?? 'Unknown Player',
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'update',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Update Points'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Remove Player'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.streamRoomPlayers(widget.roomId),
        builder: (context, snapshot) {
          final playerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
          final isRoomFull = playerCount >= 6;

          return FloatingActionButton(
            onPressed: isRoomFull ? null : _showAddPlayerDialog,
            backgroundColor: isRoomFull ? Colors.grey : null,
            tooltip: isRoomFull ? 'Room is full (6 players max)' : 'Add Player',
            child: Icon(Icons.person_add),
          );
        },
      ),
    );
  }
}