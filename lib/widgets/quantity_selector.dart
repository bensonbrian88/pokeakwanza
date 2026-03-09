import 'package:flutter/material.dart';
import 'package:stynext/theme/app_theme.dart';

class QuantitySelector extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantitySelector({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            splashRadius: 20,
            onPressed: onDecrement,
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            splashRadius: 20,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
