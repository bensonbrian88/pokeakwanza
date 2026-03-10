import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/cart_provider.dart';
import 'package:stynext/providers/order_provider.dart';
import 'package:stynext/providers/shipping_address_provider.dart';
import 'package:stynext/models/shipping_address.dart';
import 'package:stynext/widgets/custom_button.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/services/location_service.dart';
import 'package:stynext/providers/location_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  ShippingAddress? _selectedAddress;
  String _payment = 'mpesa';
  bool _isProcessing = false;
  bool _payLater = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shippingAddressProvider.notifier).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final addressState = ref.watch(shippingAddressProvider);
    final addresses = addressState.addresses;
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            tooltip: 'Use current location',
            icon: const Icon(Icons.my_location_outlined),
            onPressed: _isProcessing ? null : _useCurrentLocation,
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty',
                      style:
                          TextStyle(fontSize: 18, color: AppColors.textGrey)),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Continue Shopping',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  locationAsync.when(
                    data: (pos) => Text(
                      '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => const Text(
                      'Location denied',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Delivery Address Section
                  _buildSectionHeader('Delivery Address'),
                  const SizedBox(height: 12),
                  addresses.isEmpty
                      ? _buildEmptyState('No addresses saved',
                          'Add a delivery address to continue')
                      : _buildAddressList(addresses),
                  const SizedBox(height: 24),

                  // Payment Method Section
                  _buildSectionHeader('Payment Method'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Pay Now'),
                        selected: !_payLater,
                        onSelected: (_) => setState(() => _payLater = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Pay Later'),
                        selected: _payLater,
                        onSelected: (_) => setState(() => _payLater = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_payLater) _buildPaymentOptions(),
                  if (_payLater) _buildPayLaterPickers(),
                  const SizedBox(height: 24),

                  // Order Summary Section
                  _buildSectionHeader('Order Summary'),
                  const SizedBox(height: 12),
                  _buildOrderSummary(cartState),
                  const SizedBox(height: 28),

                  // Confirm Button
                  CustomButton(
                    label: _payLater ? 'Confirm Order' : 'Confirm & Pay',
                    gradient: true,
                    onPressed: _selectedAddress != null && !_isProcessing
                        ? _placeOrder
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedAddress == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Please select a delivery address to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
              )),
        ],
      ),
    );
  }

  Widget _buildAddressList(List<ShippingAddress> addresses) {
    return Column(
      children: addresses.map((addr) {
        final isSelected = _selectedAddress?.id == addr.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedAddress = addr),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 14, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addr.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${addr.address}, ${addr.city}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentOptions() {
    final options = [
      {'value': 'mpesa', 'label': 'M-Pesa', 'icon': Icons.phone_iphone},
      {'value': 'tigopesa', 'label': 'Tigo Pesa', 'icon': Icons.phone_android},
      {
        'value': 'card',
        'label': 'Credit/Debit Card',
        'icon': Icons.credit_card
      },
    ];

    return Column(
      children: options.map((option) {
        final isSelected = _payment == option['value'];
        return GestureDetector(
          onTap: () => setState(() => _payment = option['value'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 14, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Icon(option['icon'] as IconData,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  option['label'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummary(CartState cart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cart.items.asMap().entries.map((e) {
            final item = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(item.product.price * item.quantity).toStringAsFixed(0)} TZS',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const Divider(color: AppColors.borderLight, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              Text(
                '${cart.totalAmount.toStringAsFixed(0)} TZS',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Fee',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13),
              ),
              Text(
                '0 TZS',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              Text(
                '${cart.totalAmount.toStringAsFixed(0)} TZS',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);
      final items = cart.items
          .map((e) => {
                'product_id': e.product.id,
                'quantity': e.quantity,
              })
          .toList();
      String? date = _payLater && _selectedDate != null
          ? _selectedDate!.toIso8601String().split('T').first
          : null;
      String? time = _payLater && _selectedTime != null
          ? _selectedTime!.format(context)
          : null;
      // Optional: time range if provided
      String? timeFrom = time;
      final result = await ref.read(orderProvider.notifier).checkout(
            _payment,
            deliveryDate: date,
            deliveryTime: timeFrom,
            addressId: _selectedAddress?.id,
            payLater: _payLater,
            cartItems: items,
          );

      if (mounted) {
        final orderId = result['orderId'] ?? result['order_id'] ?? result['id'];
        try {
          final pos = await LocationService().requestCurrentPosition();
          if (pos != null && orderId is int) {
            await ref.read(orderProvider.notifier).updateOrderLocation(
                  orderId: orderId,
                  latitude: pos.latitude,
                  longitude: pos.longitude,
                  address: _selectedAddress?.address ?? 'Delivery location',
                );
          }
        } catch (_) {}
        // Prefetch orders so profile/orders list shows the new order immediately
        await ref.read(orderProvider.notifier).fetchOrders();
        await ref.read(cartProvider.notifier).clearCart();
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/order_success',
          (route) => false,
          arguments: {'orderId': result['orderId'], 'status': result['status']},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isProcessing = true);
    try {
      final pos = await LocationService().requestCurrentPosition();
      if (pos == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Location permission denied or disabled. Please enable in settings')));
        }
        return;
      }
      final addr = await ref.read(shippingAddressProvider.notifier).addAddress({
        'name': 'Current Location',
        'address': 'My current location',
        'city': '',
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
      if (addr != null) {
        setState(() => _selectedAddress = addr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location saved as delivery address')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to use location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildPayLaterPickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _selectedDate != null
                      ? _selectedDate!.toIso8601String().split('T').first
                      : 'Pick delivery date',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 30)),
                    initialDate:
                        _selectedDate ?? now.add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Pick time',
                ),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
