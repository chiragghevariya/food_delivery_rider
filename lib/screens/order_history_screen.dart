import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/order.dart';
import '../services/rider_service.dart';
import '../utils/error_utils.dart';
import '../widgets/status_badge.dart';

/// Lists the rider's completed (delivered) orders.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final RiderService _service = RiderService();
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.history();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.history());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery History')),
      body: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(apiErrorMessage(snapshot.error!)));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No completed deliveries yet.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, i) => _historyCard(orders[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _historyCard(Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            StatusBadge(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(order.restaurantName ?? 'Restaurant'),
            const SizedBox(height: 2),
            Text(
              '\$${order.total.toStringAsFixed(2)}'
              '${order.createdAt != null ? '  •  ${DateFormat('MMM d, h:mm a').format(order.createdAt!)}' : ''}',
              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
