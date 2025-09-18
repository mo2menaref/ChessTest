import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

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

      setState(() {
        roomData = roomDoc.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error loading room: ${e.toString()}';
        isLoading = false;
      });
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
                  'Viewing: ${roomData!['name'] ?? 'Room'}',style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
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

          // Players list (read-only)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.streamRoomPlayers(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading players'),
                        Text('${snapshot.error}', style: TextStyle(fontSize: 12)),
                      ],
                    ),
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
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No players yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Text('The room owner will add players soon'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Refresh is handled automatically by StreamBuilder
                    await Future.delayed(Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      final playerData = player.data() as Map<String, dynamic>;
                      final rank = index + 1;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        child: ListTile(
                          leading: _buildRankingBadge(rank),
                          title: Text(
                              playerData['name'] ?? 'Unknown Player',
                              style: TextStyle(
                                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 18,
                              ),
                          ),
                          subtitle: Text(
                            'Rank #$rank',
                            style: TextStyle(
                              color: rank <= 3 ? Colors.amber[700] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: rank <= 3 ? Colors.amber : Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${playerData['points'] ?? 0} pts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom info bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        color: Colors.green.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'This page updates automatically',
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