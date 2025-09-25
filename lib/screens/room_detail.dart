import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/textfeild_style.dart';

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

  // Add these variables for dropdown selections
  String? _selectedPlayer1;
  String? _selectedPlayer2;
  String? _selectedPlayer3;
  bool _selectionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  // Add method to load selections from Firestore
  _loadSelections() async {
    try {
      final selections = await _firestoreService.getRoomSelections(widget.roomId);
      if (selections != null && mounted) {
        setState(() {
          _selectedPlayer1 = selections['selectedPlayer1'];
          _selectedPlayer2 = selections['selectedPlayer2'];
          _selectedPlayer3 = selections['selectedPlayer3'];
          _selectionsLoaded = true;
        });
      } else {
        setState(() {
          _selectionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading selections: $e');
      setState(() {
        _selectionsLoaded = true;
      });
    }
  }

  // Add method to save selections to Firestore
  _saveSelections() async {
    try {
      await _firestoreService.updateRoomSelections(
        widget.roomId,
        _selectedPlayer1,
        _selectedPlayer2,
        _selectedPlayer3,
      );
    } catch (e) {
      // Handle error silently or show message if needed
      debugPrint('Error saving selections: $e');
    }
  }

  // Add method to build dropdown menu
  Widget _buildDropdownMenu(
      String label,
      String? selectedValue,
      List<QueryDocumentSnapshot> players,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text('Select Player'),
            isExpanded: true,
            underline: SizedBox(),
            items: [
              // Add clear option first
              DropdownMenuItem<String>(
                value: null,
                child: Text('No selection', style: TextStyle(color: Colors.grey)),
              ),
              // Then add existing player items
              ...players.map((player) {
                final playerData = player.data() as Map<String, dynamic>;
                final playerName = playerData['name'] ?? 'Unknown Player';
                return DropdownMenuItem<String>(
                  value: player.id,
                  child: Text(playerName),
                );
              }).toList(),
            ],
            onChanged: (value) {
              onChanged(value);
              _saveSelections();
            },
          ),
        ),
      ],
    );
  }

  // Add method to get player name by ID
  String _getPlayerNameById(List<QueryDocumentSnapshot> players, String? playerId) {
    if (playerId == null) return 'No selection';

    try {
      final player = players.firstWhere((p) => p.id == playerId);
      final playerData = player.data() as Map<String, dynamic>;
      return playerData['name'] ?? 'Unknown Player';
    } catch (e) {
      return 'Player not found';
    }
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
                  final players = snapshot.data!.docs;

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
                      SizedBox(height: 16),
                      // Add dropdown menus row - only show when selections are loaded
                      if (_selectionsLoaded)
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownMenu(
                                'Top Scorer of the Week ⭐',
                                _selectedPlayer1,
                                players,
                                    (value) => setState(() => _selectedPlayer1 = value),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownMenu(
                                'The Brilliant Player 🧠',
                                _selectedPlayer2,
                                players,
                                    (value) => setState(() => _selectedPlayer2 = value),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownMenu(
                                'Most Active 🗣️',
                                _selectedPlayer3,
                                players,
                                    (value) => setState(() => _selectedPlayer3 = value),
                              ),
                            ),
                          ],
                        ),
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

          // ...existing expanded ListView code remains the same...
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('Rank #$rank'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: playerData['points'] < 70 ? Colors.blue : Colors.green,
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

  // ... all existing methods remain the same (no changes needed) ...
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
}