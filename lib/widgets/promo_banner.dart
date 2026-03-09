import 'package:flutter/material.dart';
import 'package:stynext/widgets/primary_button.dart';

class PromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback? onTap;
  final Widget? illustration;

  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.cta,
    this.onTap,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF0E7A39)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 150,
                  child: PrimaryButton(
                    label: cta,
                    onPressed: onTap,
                    fullWidth: false,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            height: 96,
            child: illustration ??
                const Icon(Icons.local_offer, color: Colors.white, size: 64),
          ),
        ],
      ),
    );
  }
}
