import 'package:chess_test/widgets/player_list.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/players_functions.dart';
import '../widgets/room_dailogs.dart';

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
  final PlayerFunctionManager _playerManager = PlayerFunctionManager();
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
      final selections = await _playerManager.loadSelections(widget.roomId);
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
    await _playerManager.saveSelections(
      roomId: widget.roomId,
      selectedPlayer1: _selectedPlayer1,
      selectedPlayer2: _selectedPlayer2,
      selectedPlayer3: _selectedPlayer3,
    );
  }

  // Add method to build dropdown menu
  Widget _buildDropdownMenu(String label,
      String? selectedValue,
      List<QueryDocumentSnapshot> players,
      Function(String?) onChanged,) {
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
                child: Text(
                    'No selection', style: TextStyle(color: Colors.grey)),
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

  // Reset weekly points using PlayerFunctionManager
  resetWeeklyPoints() async {
    await _playerManager.resetWeeklyPoints(
      context: context,
      roomId: widget.roomId,
      onSuccess: () {
        _loadSelections(); // Reload selections after reset
      },
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
            onPressed: () =>
                RoomDialogs.showShareRoomDialog(
                  context: context,
                  roomId: widget.roomId,
                ),
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
                  final allPlayers = snapshot.data!.docs;
                  final topPlayer = allPlayers.first;
                  final topPlayerData = topPlayer.data() as Map<String,
                      dynamic>;
                  final kingName = topPlayerData['name'] ?? 'Unknown Player';

                  // Find top weekly scorer
                  String topWeeklyScorerText = 'No player yet';
                  final playersWithWeeklyPoints = allPlayers.where((player) {
                    final data = player.data() as Map<String, dynamic>;
                    return (data['weeklyPoints'] ?? 0) > 0;
                  }).toList();

                  if (playersWithWeeklyPoints.isNotEmpty) {
                    // Sort by weekly points to find the top weekly scorer
                    playersWithWeeklyPoints.sort((a, b) {
                      final aWeekly = (a.data() as Map<String,
                          dynamic>)['weeklyPoints'] ?? 0;
                      final bWeekly = (b.data() as Map<String,
                          dynamic>)['weeklyPoints'] ?? 0;
                      return bWeekly.compareTo(aWeekly);
                    });

                    final topWeeklyPlayer = playersWithWeeklyPoints.first;
                    final topWeeklyData = topWeeklyPlayer.data() as Map<
                        String,
                        dynamic>;
                    final weeklyPoints = topWeeklyData['weeklyPoints'] ?? 0;
                    topWeeklyScorerText =
                    '${topWeeklyData['name']} ($weeklyPoints pts this week)';
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'The King of The Room is: ',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          Text(
                            kingName,
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Show Top Scorer of the Week
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Top Scorer of the Week ⭐: ',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium,
                          ),
                          Text(
                            topWeeklyScorerText,
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
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
                                'The Brilliant Player 🧠',
                                _selectedPlayer2,
                                allPlayers,
                                    (value) =>
                                    setState(() => _selectedPlayer2 = value),
                              ),
                            ),
                            // Reset button
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              child: ElevatedButton.icon(
                                onPressed: resetWeeklyPoints,
                                icon: Icon(Icons.refresh, size: 18),
                                label: Text("Reset"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownMenu(
                                'Most Active 🗣️',
                                _selectedPlayer3,
                                allPlayers,
                                    (value) =>
                                    setState(() => _selectedPlayer3 = value),
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
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Top Scorer of the Week ⭐: No player yet',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          PlayerList(roomId: widget.roomId),
        ],
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.streamRoomPlayers(widget.roomId),
        builder: (context, snapshot) {
          final playerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
          final isRoomFull = playerCount >= 6;

          return FloatingActionButton(
            onPressed: isRoomFull ? null : () =>
                RoomDialogs.showAddPlayerDialog(
                  context: context,
                  playerNameController: _playerNameController,
                  onAdd: () =>
                      _playerManager.addPlayer(
                        context: context,
                        roomId: widget.roomId,
                        playerNameController: _playerNameController,
                      ),
                ),
            backgroundColor: isRoomFull ? Colors.grey : null,
            tooltip: isRoomFull ? 'Room is full (6 players max)' : 'Add Player',
            child: Icon(Icons.person_add),
          );
        },
      ),
    );
  }
}


