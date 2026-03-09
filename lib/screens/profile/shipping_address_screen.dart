import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/shipping_address_provider.dart';
import 'package:stynext/models/shipping_address.dart';
import 'package:stynext/theme/app_theme.dart';

class ShippingAddressScreen extends ConsumerStatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  ConsumerState<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends ConsumerState<ShippingAddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shippingAddressProvider.notifier).fetchAddresses();
    });
  }

  void _showForm({ShippingAddress? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final addressCtrl = TextEditingController(text: existing?.address);
    final cityCtrl = TextEditingController(text: existing?.city);
    final phoneCtrl = TextEditingController(text: existing?.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Address' : 'Edit Address'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final addr = addressCtrl.text.trim();
              final city = cityCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || addr.isEmpty || city.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weka Name, Address na City'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final provider = ref.read(shippingAddressProvider.notifier);
              final payload = {
                'name': name,
                'address': addr,
                'city': city,
                if (phone.isNotEmpty) 'phone': phone,
              };
              if (existing == null) {
                final res = await provider.addAddress(payload);
                if (res == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Imeshindikana kuunda anwani'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              } else {
                final res = await provider.updateAddress(existing.id, payload);
                if (res == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Imeshindikana kuhariri anwani'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shippingAddressProvider);
    final addresses = state.addresses;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Shipping Address'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? const Center(child: Text('No addresses yet'))
              : ListView.builder(
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    return ListTile(
                      title: Text(addr.address),
                      subtitle: Text('${addr.city} • ${addr.name}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(existing: addr),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await ref
                                  .read(shippingAddressProvider.notifier)
                                  .deleteAddress(addr.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
