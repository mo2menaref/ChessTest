import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/players_functions.dart';
import '../widgets/room_dailogs.dart';
import '../widgets/player_list.dart';
import '../widgets/drop_down_menu.dart';

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

  // Dropdown selection variables
  String? _selectedPlayer1;
  String? _selectedPlayer2;
  String? _selectedPlayer3;
  bool _selectionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSelections();
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    super.dispose();
  }

  // Only keep this simple method for initial loading
  _loadInitialSelections() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.streamRoomDetails(
            widget.roomId,
          ), // We need to add this method
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final roomData = snapshot.data!.data() as Map<String, dynamic>;
              final currentWeek = roomData['currentWeekNumber'] ?? 1;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.roomName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Session $currentWeek',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }

            return Text(widget.roomName); // Fallback
          },
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => RoomDialogs.showShareRoomDialog(
              context: context,
              roomId: widget.roomId,
            ),
            tooltip: 'Share Room',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section with King, Weekly Scorer, and Dropdowns
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
                  final topPlayerData =
                      topPlayer.data() as Map<String, dynamic>;
                  final kingName = topPlayerData['name'] ?? 'Unknown Player';

                  // Find top weekly scorer
                  String topWeeklyScorerText = 'No player yet';
                  final playersWithWeeklyPoints = allPlayers.where((player) {
                    final data = player.data() as Map<String, dynamic>;
                    return (data['weeklyPoints'] ?? 0) > 0;
                  }).toList();

                  if (playersWithWeeklyPoints.isNotEmpty) {
                    playersWithWeeklyPoints.sort((a, b) {
                      final aWeekly =
                          (a.data() as Map<String, dynamic>)['weeklyPoints'] ??
                          0;
                      final bWeekly =
                          (b.data() as Map<String, dynamic>)['weeklyPoints'] ??
                          0;
                      return bWeekly.compareTo(aWeekly);
                    });

                    final topWeeklyPlayer = playersWithWeeklyPoints.first;
                    final topWeeklyData =
                        topWeeklyPlayer.data() as Map<String, dynamic>;
                    final weeklyPoints = topWeeklyData['weeklyPoints'] ?? 0;
                    topWeeklyScorerText =
                        '${topWeeklyData['name']} ($weeklyPoints pts this week)';
                  }

                  return Column(
                    children: [
                      // King Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'The King of The Room is: ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Flexible(
                            child: Text(
                              kingName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Top Weekly Scorer Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Top Scorer of the Week ⭐: ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Flexible(

                            child: Text(
                              topWeeklyScorerText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Dropdown Menus Row - Using DropDownMenu Widget
                      if (_selectionsLoaded)
                        Row(
                          children: [
                            // Brilliant Player Dropdown
                            Expanded(
                              child: DropDownMenu(
                                label: 'Brilliant Player 🧠',
                                selectedValue: _selectedPlayer2,
                                players: allPlayers,
                                onChanged: (value) async {
                                  setState(() => _selectedPlayer2 = value);
                                  // Direct call to PlayerFunctionManager
                                  await _playerManager.saveSelections(
                                    roomId: widget.roomId,
                                    selectedPlayer1: _selectedPlayer1,
                                    selectedPlayer2: value,
                                    selectedPlayer3: _selectedPlayer3,
                                  );
                                },
                              ),
                            ),

                            // Reset Button
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              child: ElevatedButton.icon(
                                // Direct call to PlayerFunctionManager
                                onPressed: () =>
                                    _playerManager.resetWeeklyPoints(
                                      context: context,
                                      roomId: widget.roomId,
                                      onSuccess: _loadInitialSelections,
                                    ),
                                icon: Icon(Icons.refresh, size: 15),
                                label: Text("Reset"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),

                            // Most Active Player Dropdown
                            Expanded(
                              child: DropDownMenu(
                                label: 'Most Active 🗣️',
                                selectedValue: _selectedPlayer3,
                                players: allPlayers,
                                onChanged: (value) async {
                                  setState(() => _selectedPlayer3 = value);
                                  // Direct call to PlayerFunctionManager
                                  await _playerManager.saveSelections(
                                    roomId: widget.roomId,
                                    selectedPlayer1: _selectedPlayer1,
                                    selectedPlayer2: _selectedPlayer2,
                                    selectedPlayer3: value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                } else {
                  // No Players State
                  return Column(
                    children: [
                      Text(
                        'No King Yet - Add Players!',
                        style: Theme.of(context).textTheme.titleLarge,
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

          // Players List - Using PlayerList Widget
          PlayerList(roomId: widget.roomId),
        ],
      ),

      // Floating Action Button for Adding Players
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.streamRoomPlayers(widget.roomId),
        builder: (context, snapshot) {
          final playerCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
          final isRoomFull = playerCount >= 6;

          return FloatingActionButton(
            // Direct call to PlayerFunctionManager via RoomDialogs
            onPressed: isRoomFull
                ? null
                : () => RoomDialogs.showAddPlayerDialog(
                    context: context,
                    playerNameController: _playerNameController,
                    onAdd: () => _playerManager.addPlayer(
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
