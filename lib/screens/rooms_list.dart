import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'user_setup.dart';
import 'room_detail.dart';

class RoomsListScreen extends StatefulWidget {
  const RoomsListScreen({super.key});

  @override
  RoomsListScreenState createState() => RoomsListScreenState();
}

class RoomsListScreenState extends State<RoomsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _roomNameController = TextEditingController();
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  _getCurrentUser() async {
    final user = await _firestoreService.getUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['userId'];
        _currentUserName = user['name'];
      });
    }
  }

  _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Room'),
        content: TextField(
          controller: _roomNameController,
          decoration: InputDecoration(
            labelText: 'Room Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _roomNameController.clear();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(onPressed: _createRoom, child: Text('Create')),
        ],
      ),
    );
  }

  _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a room name')));
      return;
    }

    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.createRoom(
        _roomNameController.text.trim(),
        _currentUserId!,
      );
      Navigator.pop(context);
      _roomNameController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Room created successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _deleteRoom(String roomId, String roomName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Room'),
        content: Text(
          'Are you sure you want to delete "$roomName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteRoom(roomId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Room deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Rooms'),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              } else if (value == 'rules') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(title: Text('The Rules',textAlign: TextAlign.center,),
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold,fontSize: 30,color: Colors.black,),
                    content: Text(' ⭐You can earn points in different ways:\nEvery star = 4 points (max 3 stars per piece → 72 points in the first 3 sessions).\nJoining the discussion = 2 points.\nSolving a puzzle correctly = 3 points.\nTrying but not solving = 2 points.\nNot trying at all = 1 point.\nSolving fast or cracking a hard one = +2 bonus points.\nKids who try a lot (even if wrong) get bonus points.\nHelping friends or being kind = bonus points too.\n2. Your main target is to reach 70 points by the end of the first\n 3 sessions (the whole level has 8 sessions to keep going).\n3. Nobody loses! \n😃 Everyone who tries and learns is a winner.\n🎖️ Weekly Awards:\nMost Active 🗣️\nThe Genius Player 🧠\nTop Scorer of the Week ⭐\n'),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rules',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Rules'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            child: Text(
              'Welcome $_currentUserName!',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getRooms(_currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data!.docs;

                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No rooms yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Text('Create your first room to get started'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final roomData = room.data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      color: Color(0xFFECFAEB),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.groups, color: Colors.white),
                        ),
                        title: Text(
                          roomData['name'] ?? 'Unnamed Room',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Room ID: ${room.id}'),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteRoom(
                                room.id,
                                roomData['name'] ?? 'Unnamed Room',
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailScreen(
                                roomId: room.id,
                                roomName: roomData['name'] ?? 'Unnamed Room',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFECFAEB),
        onPressed: _showCreateRoomDialog,
        tooltip: 'Create Room',
        child: Icon(Icons.add, color: Colors.green, size: 35),
      ),
    );
  }
}
