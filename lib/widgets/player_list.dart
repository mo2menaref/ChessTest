import 'package:chess_test/widgets/room_dailogs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/players_functions.dart';
import '../utils/room_helpers.dart';

class PlayerList extends StatefulWidget {
  final String roomId;

  const PlayerList({
    super.key,
    required this.roomId,
  });

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  final FirestoreService _firestoreService = FirestoreService();
  final PlayerFunctionManager _playerManager = PlayerFunctionManager();
  final TextEditingController _pointsController = TextEditingController();

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _updatePoints(String playerId) async {
    await _playerManager.updatePoints(
      context: context,
      roomId: widget.roomId,
      playerId: playerId,
      pointsController: _pointsController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
              final electricCount = playerData['electricCount'] ?? 0;

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: buildRankingBadge(rank),
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
                      // Multiple Electric Containers - Show each electric symbol separately
                      ...List.generate(electricCount, (electricIndex) =>
                          Container(
                            margin: EdgeInsets.only(right: 4), // Space between electric symbols
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent[700], // Changed to yellow for better visibility
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

                      // Points container
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
                            RoomDialogs.showUpdatePointsDialog(
                              context: context,
                              playerId: player.id,
                              playerName: playerData['name'] ?? 'Unknown Player',
                              currentPoints: playerData['points'] ?? 0,
                              pointsController: _pointsController,
                              onUpdate: () => _updatePoints(player.id),
                            );
                          } else   if (value == 'delete') {
                            _playerManager.showDeletePlayerDialog(
                              context: context,
                              playerId: player.id,
                              playerName: playerData['name'] ?? 'Unknown Player',
                              roomId: widget.roomId,
                              onPlayerDeleted: () {
                                // Trigger a rebuild to clean up dropdowns
                                if (mounted) {
                                  setState(() {});
                                }
                              },
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
    );
  }
}