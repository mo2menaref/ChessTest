import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String getPlayerNameById(List<QueryDocumentSnapshot> players, String? playerId) {
  if (playerId == null) return 'No selection';

  try {
    final player = players.firstWhere((p) => p.id == playerId);
    final playerData = player.data() as Map<String, dynamic>;
    return playerData['name'] ?? 'Unknown Player';
  } catch (e) {
    return 'Player not found';
  }
}

Widget buildRankingBadge(int rank) {
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