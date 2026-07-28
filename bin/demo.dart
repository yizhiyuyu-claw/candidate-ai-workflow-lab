// ignore_for_file: avoid_print

import 'package:candidate_ai_workflow_lab/travel_pack.dart';

void main() async {
  final service = OrderSyncService(
    api: _DemoApi(),
    cache: _MemoryCache(),
    log: _ConsoleLog(),
  );

  final orders = await service.sync('cus_demo_123456789');
  for (final order in orders) {
    print(order);
  }
}

class _DemoApi implements OrderApi {
  @override
  Future<List<RemoteOrder>> fetchOrders(String customerId) async {
    return [
      RemoteOrder(
        id: 'ord_1001',
        email: 'alex.chen@example.com',
        productName: 'Japan 5GB 30 Days',
        status: PassStatus.ready,
        updatedAt: DateTime.utc(2026, 7, 20, 9),
        activationCode: 'JP-READY-1001',
        accessToken: 'token_should_never_be_logged',
      ),
    ];
  }
}

class _MemoryCache implements OrderCache {
  final Map<String, List<CachedOrder>> _store = {};

  @override
  Future<List<CachedOrder>> read(String customerId) async {
    return List.of(_store[customerId] ?? const []);
  }

  @override
  Future<void> write(String customerId, List<CachedOrder> orders) async {
    _store[customerId] = List.of(orders);
  }
}

class _ConsoleLog implements AuditLog {
  @override
  void info(String message) {
    print('[info] $message');
  }

  @override
  void warn(String message) {
    print('[warn] $message');
  }
}
