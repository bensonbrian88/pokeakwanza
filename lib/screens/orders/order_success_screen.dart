import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/services/location_service.dart';
import 'package:stynext/providers/order_provider.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final orderId = args != null ? (args['orderId'] ?? args['order_id']) : null;
    final status = args != null ? args['status']?.toString() : null;
    final title = status == null
        ? 'Order placed. Please wait for driver'
        : status.toLowerCase().contains('pending')
            ? 'Order placed. Awaiting admin approval'
            : 'Order placed successfully';
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Order Success'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (orderId != null)
                Text('Order ID: $orderId',
                    style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/orders'),
                  child: const Text('View Orders'),
                ),
              ),
              const SizedBox(height: 8),
              if (orderId != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Share Current Location'),
                    onPressed: () async {
                      final pos =
                          await LocationService().requestCurrentPosition();
                      if (pos == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Location permission denied or disabled')),
                          );
                        }
                        return;
                      }
                      try {
                        await ref
                            .read(orderProvider.notifier)
                            .updateOrderLocation(
                              orderId: orderId as int,
                              latitude: pos.latitude,
                              longitude: pos.longitude,
                              address: 'Current location',
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Location sent to driver')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to update location: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false),
                child: const Text('Back to Home'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
