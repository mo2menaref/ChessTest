import 'package:flutter/material.dart';

InputDecoration userPlayer = InputDecoration(
    labelText: 'Your Name',
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
          width: 2
      ),
      borderRadius: BorderRadius.circular(15),
    ),
    prefixIcon: Icon(Icons.person),
);