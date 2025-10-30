import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DropDownMenu extends StatelessWidget {
  final String label;
  final String? selectedValue;
  final Function(String?) onChanged;
  final List<QueryDocumentSnapshot> players;

  const DropDownMenu({
    required this.label,
    required this.selectedValue,
    required this.onChanged,
    required this.players,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Check if selectedValue exists in current players list
    final selectedPlayerExists = selectedValue == null ||
        players.any((player) => player.id == selectedValue);

    // If selected player doesn't exist, reset to null
    final safeSelectedValue = selectedPlayerExists ? selectedValue : null;

    // Auto-clear selection if player was deleted
    if (!selectedPlayerExists && selectedValue != null) {
      // Call onChanged with null to clear the selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(null);
      });
    }

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
            value: safeSelectedValue, // Use safe value instead of selectedValue
            hint: Text('Select Player'),
            isExpanded: true,
            underline: SizedBox(),
            items: [
              // Add clear option first
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'No selection',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              // Then add existing player items
              ...players.map((player) {
                final playerData = player.data() as Map<String, dynamic>;
                final playerName = playerData['name'] ?? 'Unknown Player';
                return DropdownMenuItem<String>(
                  value: player.id,
                  child: Text(playerName),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}