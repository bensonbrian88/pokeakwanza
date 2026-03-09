import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/help_center_provider.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(helpCenterProvider).fetchInfo();
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(helpCenterProvider);
    final info = provider.info;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : info == null
              ? const Center(child: Text('Unable to load help info'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ContactRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: info.phone,
                        onTap: () => _launchUrl('tel:${info.phone}'),
                      ),
                      const SizedBox(height: 16),
                      _ContactRow(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        value: info.whatsapp,
                        onTap: () =>
                            _launchUrl('https://wa.me/${info.whatsapp}'),
                      ),
                      const SizedBox(height: 16),
                      _ContactRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: info.email,
                        onTap: () => _launchUrl('mailto:${info.email}'),
                      ),
                      const SizedBox(height: 16),
                      _ContactRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: info.location,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: themeColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: themeColor),
        ],
      ),
    );
  }
}
