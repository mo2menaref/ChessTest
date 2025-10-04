import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../utils/room_helpers.dart';
import '../widgets/guest_player_list.dart';

class GuestRoomViewScreen extends StatefulWidget {
  final String roomId;

  const GuestRoomViewScreen({
    super.key,
    required this.roomId,
  });

  @override
  GuestRoomViewScreenState createState() => GuestRoomViewScreenState();
}

class GuestRoomViewScreenState extends State<GuestRoomViewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? roomData;
  Map<String, dynamic>? roomSelections;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  _loadRoomData() async {
    try {
      DocumentSnapshot roomDoc = await _firestoreService.getRoomDetails(widget.roomId);

      if (!roomDoc.exists) {
        setState(() {
          error = 'Room not found';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? selections = await _firestoreService.getRoomSelections(widget.roomId);

      setState(() {
        roomData = roomDoc.data() as Map<String, dynamic>?;
        roomSelections = selections;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading room: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Widget _buildSelectionDisplay(String label, String playerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Text(
            playerName,
            style: TextStyle(
              fontSize: 16,
              color: playerName == 'No selection' ? Colors.grey : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading Room...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(error!, style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, color: Color(0xFFECFAEB)),
                SizedBox(width: 8),
                Text(
                  'Viewing: ${roomData!['name'] ?? 'Room'}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
            SizedBox(height: 3),
            Text(
              'Read-Only Mode - Live Updates',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
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
                  final topPlayerData = topPlayer.data() as Map<String, dynamic>;
                  final kingName = topPlayerData['name'] ?? 'Unknown Player';

                  String topWeeklyScorerText = 'No player yet';
                  final playersWithWeeklyPoints = allPlayers.where((player) {
                    final data = player.data() as Map<String, dynamic>;
                    return (data['weeklyPoints'] ?? 0) > 0;
                  }).toList();

                  if (playersWithWeeklyPoints.isNotEmpty) {
                    playersWithWeeklyPoints.sort((a, b) {
                      final aWeekly = (a.data() as Map<String, dynamic>)['weeklyPoints'] ?? 0;
                      final bWeekly = (b.data() as Map<String, dynamic>)['weeklyPoints'] ?? 0;
                      return bWeekly.compareTo(aWeekly);
                    });

                    final topWeeklyPlayer = playersWithWeeklyPoints.first;
                    final topWeeklyData = topWeeklyPlayer.data() as Map<String, dynamic>;
                    final weeklyPoints = topWeeklyData['weeklyPoints'] ?? 0;
                    topWeeklyScorerText = '${topWeeklyData['name']} ($weeklyPoints pts this week)';
                  }

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
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Top Scorer of the Week ⭐: ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            topWeeklyScorerText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectionDisplay(
                              'The Brilliant Player 🧠',
                              getPlayerNameById(allPlayers, roomSelections?['selectedPlayer2']),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildSelectionDisplay(
                              'Most Active 🗣️',
                              getPlayerNameById(allPlayers, roomSelections?['selectedPlayer3']),
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
                        'No players yet',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Top Scorer of the Week ⭐: No player yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          // Use the new GuestPlayerList widget
          GuestPlayerList(roomId: widget.roomId),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        color: Colors.green.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Full leaderboard - Updates automatically',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}