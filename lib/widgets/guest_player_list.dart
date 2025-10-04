import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/room_helpers.dart';

class GuestPlayerList extends StatefulWidget {
  final String roomId;

  const GuestPlayerList({
    super.key,
    required this.roomId,
  });

  @override
  State<GuestPlayerList> createState() => _GuestPlayerListState();
}

class _GuestPlayerListState extends State<GuestPlayerList> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Expanded(
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

          final allPlayers = snapshot.data!.docs;

          if (allPlayers.isEmpty) {
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
                  Text('Players will appear here when added to the room'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final player = allPlayers[index];
              final playerData = player.data() as Map<String, dynamic>;
              final rank = index + 1;
              final electricCount = playerData['electricCount'] ?? 0;

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 4,
                child: ListTile(
                  leading: buildRankingBadge(rank),
                  title: Text(
                    playerData['name'] ?? 'Unknown Player',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Rank #$rank',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Multiple Electric Containers - Show each electric symbol separately
                      ...List.generate(electricCount, (electricIndex) =>
                          Container(
                            margin: EdgeInsets.only(right: 4), // Space between electric symbols
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent[700], // Yellow for consistency
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green, width: 1), // Add border for distinction
                            ),
                            child: Text(
                              '⚡',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                      ),

                      // Add spacing if there are electric symbols
                      if (electricCount > 0) SizedBox(width: 8),

                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: playerData['points'] < 70 ? Colors.blue : Colors.green,
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
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}