import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/order.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/providers/order_provider.dart';
import 'package:stynext/widgets/delivery_timeline.dart';
import 'delivery_map_screen.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Order? _order;
  int? _orderId;
  late final OrderNotifier _orderNotifier;
  Timer? _timer;

  Color _badgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'packed':
        return Colors.teal;
      case 'shipped':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    // Provider initialized in build via context; safe to read later
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderNotifier = ref.read(orderProvider.notifier);
    _order ??= ModalRoute.of(context)?.settings.arguments as Order?;
    _orderId ??= _order?.id;
    // Start periodic refresh if we have an id
    _timer ??= Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted || _orderId == null) return;
      final fresh = await _orderNotifier.fetchOrderDetail(_orderId!);
      if (fresh != null && mounted) {
        setState(() {
          _order = fresh;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order =
        _order ?? ModalRoute.of(context)?.settings.arguments as Order?;
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: TextStyle(color: Colors.grey[600])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeColor(order.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _badgeColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tracking Info
          if (order.trackingNumber.isNotEmpty ||
              order.courierName.isNotEmpty ||
              order.estimatedDelivery.isNotEmpty) ...[
            const Text('Delivery Tracking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (order.trackingNumber.isNotEmpty)
              Text('Tracking Number: ${order.trackingNumber}'),
            if (order.courierName.isNotEmpty)
              Text('Courier: ${order.courierName}'),
            if (order.estimatedDelivery.isNotEmpty)
              Text('Estimated Delivery: ${order.estimatedDelivery}'),
            const SizedBox(height: 12),
            DeliveryTimeline(
              status: order.deliveryStatus.isNotEmpty
                  ? order.deliveryStatus
                  : order.status,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeliveryMapScreen(),
                    ),
                  );
                },
                child: const Text('Track on Map'),
              ),
            ),
            const Divider(height: 32),
          ],
          const Text('Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...order.items.map((it) {
            final map = it as Map<String, dynamic>? ?? {};
            final name = map['product']?['name'] ??
                map['name'] ??
                'Product ${map['product_id'] ?? ''}';
            final qty = map['quantity'] ?? 1;
            final price = (map['price'] ?? 0).toString();
            return ListTile(
              title: Text(name),
              subtitle: Text('Qty: $qty'),
              trailing: Text('$price TZS'),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${order.total.toStringAsFixed(0)} TZS',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment', style: TextStyle(color: Colors.grey[600])),
              Text('—', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          if (order.status.toLowerCase() != 'delivered')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  if (_orderId == null) return;
                  try {
                    await ref
                        .read(orderProvider.notifier)
                        .confirmDelivery(_orderId!);
                    final fresh =
                        await ref.read(orderProvider.notifier).fetchOrderDetail(
                              _orderId!,
                            );
                    if (fresh != null && mounted) {
                      setState(() {
                        _order = fresh;
                      });
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Delivery confirmed')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                child: const Text('Confirm Delivery'),
              ),
            ),
        ],
      ),
    );
  }
}
