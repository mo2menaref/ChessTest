import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/textfeild_style.dart';
import 'rooms_list.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  UserSetupScreenState createState() => UserSetupScreenState();
}

class UserSetupScreenState extends State<UserSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  _createUser() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.createUser(_nameController.text.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RoomsListScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome',style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(100.0),
        child: ListView(
          children: [
            Column(
              children: [
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: Colors.green,
                ),
                SizedBox(height: 32),
                Text(
                  'Enter Your Name',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Align(
                  alignment: Alignment.center,
                  child:  SizedBox(
                    width: 500,
                    child: TextField(
                      controller: _nameController,
                      decoration: userPlayer,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createUser(),
                    ),
                  ),
                ),
                SizedBox(height: 100),
                SizedBox(
                  width: 200,
                  child:ElevatedButton(
                    onPressed: _isLoading ? null : _createUser,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Color(0xAA7b9c79),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Continue',
                      style: TextStyle(fontSize: 16,color: Color(0xFF152914)),
                    ),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}