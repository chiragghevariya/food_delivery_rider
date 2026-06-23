import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/routes.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/rider_order_provider.dart';
import '../utils/error_utils.dart';

/// Lists orders that are ready for a rider to pick up.
class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderOrderProvider>().loadAvailable();
    });
  }

  Future<void> _accept(Order order) async {
    final provider = context.read<RiderOrderProvider>();
    try {
      final active = await provider.accept(order);
      if (!mounted) return;
      // Go to the active delivery screen, passing the accepted order.
      Navigator.pushNamed(context, Routes.activeOrder, arguments: active);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      provider.loadAvailable(); // someone may have taken it — refresh
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.pushReplacementNamed(context, Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Delivery history',
            onPressed: () => Navigator.pushNamed(context, Routes.history),
          ),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Logout', onPressed: _logout),
        ],
      ),
      body: Consumer<RiderOrderProvider>(
        builder: (context, prov, _) {
          if (prov.loading && prov.available.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null && prov.available.isEmpty) {
            return _errorView(prov);
          }
          if (prov.available.isEmpty) {
            return _emptyView(prov);
          }
          return RefreshIndicator(
            onRefresh: prov.loadAvailable,
            child: ListView.builder(
              itemCount: prov.available.length,
              itemBuilder: (context, i) => _orderCard(prov.available[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _orderCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _line(Icons.store, 'Pickup', order.restaurantName ?? 'Restaurant', order.restaurantAddress),
            const SizedBox(height: 6),
            _line(Icons.location_on, 'Drop-off', order.deliveryAddress ?? 'Customer address', null),
            if (order.distanceKm != null) ...[
              const SizedBox(height: 6),
              Text('${order.distanceKm!.toStringAsFixed(1)} km to restaurant',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _accept(order),
                child: const Text('Accept'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value, String? sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub != null && sub.isNotEmpty)
                Text(sub, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyView(RiderOrderProvider prov) {
    return RefreshIndicator(
      onRefresh: prov.loadAvailable,
      child: ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inbox, size: 60, color: AppColors.textLight),
          SizedBox(height: 8),
          Center(child: Text('No orders available right now.')),
          Center(child: Text('Pull down to refresh.', style: TextStyle(color: AppColors.textLight))),
        ],
      ),
    );
  }

  Widget _errorView(RiderOrderProvider prov) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(prov.error!, textAlign: TextAlign.center)),
          ElevatedButton(onPressed: prov.loadAvailable, child: const Text('Retry')),
        ],
      ),
    );
  }
}
