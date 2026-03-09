import 'package:flutter/material.dart';

class DeliveryTimeline extends StatelessWidget {
  final String status;
  const DeliveryTimeline({super.key, required this.status});

  static const List<String> steps = [
    'confirmed',
    'packed',
    'shipped',
    'out_for_delivery',
    'delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final current = status.toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        final completed = steps.indexOf(current) >= steps.indexOf(step) &&
            steps.contains(current);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completed ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                step.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontWeight: completed ? FontWeight.bold : FontWeight.normal,
                  color: completed ? Colors.green[800] : Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
