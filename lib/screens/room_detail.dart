import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomDetailScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

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
    if (points == null) {
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
        color = Colors.blue;
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
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  'Room: ${widget.roomName}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'ID: ${widget.roomId}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
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
                            fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
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