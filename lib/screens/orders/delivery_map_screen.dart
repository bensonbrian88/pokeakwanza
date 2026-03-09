import 'package:flutter/material.dart';

class DeliveryMapScreen extends StatelessWidget {
  const DeliveryMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Map')),
      body: const Center(
        child: Text(
          'Map coming soon',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
