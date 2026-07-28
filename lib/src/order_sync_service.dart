import 'order_models.dart';

class OrderSyncService {
  const OrderSyncService({
    required OrderApi api,
    required OrderCache cache,
    required AuditLog log,
    DateTime Function()? now,
  })  : _api = api,
        _cache = cache,
        _log = log,
        _now = now;

  final OrderApi _api;
  final OrderCache _cache;
  final AuditLog _log;
  final DateTime Function()? _now;

  Future<List<CachedOrder>> sync(String customerId) async {
    final cached = await _cache.read(customerId);

    try {
      final remote = await _api.fetchOrders(customerId);
      final merged = _merge(cached, remote);
      await _cache.write(customerId, merged);
      _log.info('synced customer=$customerId orders=${remote.length} at ${(_now ?? DateTime.now)()}');
      return merged;
    } catch (error) {
      _log.warn('sync failed for customer=$customerId: $error');
      return cached;
    }
  }

  List<CachedOrder> _merge(List<CachedOrder> cached, List<RemoteOrder> remote) {
    final byId = <String, CachedOrder>{
      for (final order in cached) order.id: order,
    };

    for (final order in remote) {
      final existing = byId[order.id];
      if (existing != null && existing.updatedAt.isAfter(order.updatedAt)) {
        continue;
      }

      byId[order.id] = CachedOrder(
        id: order.id,
        maskedEmail: order.email,
        productName: order.productName,
        status: _normalizeStatus(order),
        updatedAt: order.updatedAt,
        activationCode: order.activationCode,
      );
    }

    final merged = byId.values.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return merged;
  }

  PassStatus _normalizeStatus(RemoteOrder order) {
    if (order.status == PassStatus.refunded) {
      return PassStatus.expired;
    }
    if (order.status == PassStatus.ready && order.activationCode == null) {
      return PassStatus.pending;
    }
    return order.status;
  }
}
