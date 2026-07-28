import 'package:candidate_ai_workflow_lab/travel_pack.dart';
import 'package:test/test.dart';

void main() {
  group('OrderSyncService.sync', () {
    test('merges remote orders, newest first, and masks customer email', () async {
      final cache = FakeCache(seed: [
        CachedOrder(
          id: 'ord_old',
          maskedEmail: 'o***@example.com',
          productName: 'Thailand 1GB',
          status: PassStatus.active,
          updatedAt: DateTime.utc(2026, 7, 1),
        ),
      ]);
      final log = MemoryLog();
      final service = OrderSyncService(
        api: FakeApi([
          RemoteOrder(
            id: 'ord_new',
            email: 'alex.chen@example.com',
            productName: 'Japan 5GB',
            status: PassStatus.ready,
            updatedAt: DateTime.utc(2026, 7, 20, 12),
            activationCode: 'JP-2026-READY',
            accessToken: 'secret-token-123',
          ),
        ]),
        cache: cache,
        log: log,
        now: () => DateTime.utc(2026, 7, 21),
      );

      final result = await service.sync('cus_abcdef1234567890');

      expect(result.map((order) => order.id), ['ord_new', 'ord_old']);
      expect(result.first.maskedEmail, 'a***n@example.com');
      expect(cache.lastWriteCustomerId, 'cus_abcdef1234567890');
      expect(cache.lastWrite, result);
      expect(log.allMessages.join('\n'), isNot(contains('alex.chen@example.com')));
      expect(log.allMessages.join('\n'), isNot(contains('secret-token-123')));
      expect(log.allMessages.join('\n'), isNot(contains('cus_abcdef1234567890')));
    });

    test('does not overwrite a newer cached order with stale remote data', () async {
      final newerCached = CachedOrder(
        id: 'ord_1001',
        maskedEmail: 'a***@example.com',
        productName: 'Japan 5GB',
        status: PassStatus.active,
        updatedAt: DateTime.utc(2026, 7, 22),
        activationCode: 'JP-ACTIVE',
      );
      final cache = FakeCache(seed: [newerCached]);
      final service = OrderSyncService(
        api: FakeApi([
          RemoteOrder(
            id: 'ord_1001',
            email: 'alex@example.com',
            productName: 'Japan 5GB',
            status: PassStatus.ready,
            updatedAt: DateTime.utc(2026, 7, 20),
            activationCode: 'JP-OLD',
          ),
        ]),
        cache: cache,
        log: MemoryLog(),
      );

      final result = await service.sync('cus_1');

      expect(result, [newerCached]);
      expect(cache.lastWrite, [newerCached]);
    });

    test('preserves refunded status because support workflows depend on it', () async {
      final service = OrderSyncService(
        api: FakeApi([
          RemoteOrder(
            id: 'ord_refund',
            email: 'refund@example.com',
            productName: 'USA 10GB',
            status: PassStatus.refunded,
            updatedAt: DateTime.utc(2026, 7, 18),
          ),
        ]),
        cache: FakeCache(),
        log: MemoryLog(),
      );

      final result = await service.sync('cus_2');

      expect(result.single.status, PassStatus.refunded);
    });

    test('ready remote order keeps ready status even before activation code arrives', () async {
      final service = OrderSyncService(
        api: FakeApi([
          RemoteOrder(
            id: 'ord_ready',
            email: 'ready@example.com',
            productName: 'Europe 3GB',
            status: PassStatus.ready,
            updatedAt: DateTime.utc(2026, 7, 18),
          ),
        ]),
        cache: FakeCache(),
        log: MemoryLog(),
      );

      final result = await service.sync('cus_3');

      expect(result.single.status, PassStatus.ready);
      expect(result.single.activationCode, isNull);
    });

    test('returns cached orders on API failure without writing stale data', () async {
      final cached = [
        CachedOrder(
          id: 'ord_cached',
          maskedEmail: 'c***@example.com',
          productName: 'Korea 1GB',
          status: PassStatus.installed,
          updatedAt: DateTime.utc(2026, 7, 10),
        ),
      ];
      final cache = FakeCache(seed: cached);
      final log = MemoryLog();
      final service = OrderSyncService(
        api: FailingApi(StateError('network timeout for user bob@example.com token=abc123')),
        cache: cache,
        log: log,
      );

      final result = await service.sync('cus_sensitive_999');

      expect(result, cached);
      expect(cache.writeCount, 0);
      expect(log.allMessages.join('\n'), contains('sync failed'));
      expect(log.allMessages.join('\n'), isNot(contains('bob@example.com')));
      expect(log.allMessages.join('\n'), isNot(contains('token=abc123')));
      expect(log.allMessages.join('\n'), isNot(contains('cus_sensitive_999')));
    });
  });
}

class FakeApi implements OrderApi {
  FakeApi(this.orders);

  final List<RemoteOrder> orders;

  @override
  Future<List<RemoteOrder>> fetchOrders(String customerId) async {
    return orders;
  }
}

class FailingApi implements OrderApi {
  FailingApi(this.error);

  final Object error;

  @override
  Future<List<RemoteOrder>> fetchOrders(String customerId) async {
    throw error;
  }
}

class FakeCache implements OrderCache {
  FakeCache({List<CachedOrder> seed = const []}) : _orders = List.of(seed);

  List<CachedOrder> _orders;
  String? lastWriteCustomerId;
  List<CachedOrder>? lastWrite;
  int writeCount = 0;

  @override
  Future<List<CachedOrder>> read(String customerId) async {
    return List.of(_orders);
  }

  @override
  Future<void> write(String customerId, List<CachedOrder> orders) async {
    writeCount++;
    lastWriteCustomerId = customerId;
    lastWrite = List.of(orders);
    _orders = List.of(orders);
  }
}

class MemoryLog implements AuditLog {
  final infos = <String>[];
  final warnings = <String>[];

  List<String> get allMessages => [...infos, ...warnings];

  @override
  void info(String message) {
    infos.add(message);
  }

  @override
  void warn(String message) {
    warnings.add(message);
  }
}
