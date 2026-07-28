enum PassStatus {
  pending,
  ready,
  installed,
  active,
  expired,
  refunded,
  failed,
}

class RemoteOrder {
  const RemoteOrder({
    required this.id,
    required this.email,
    required this.productName,
    required this.status,
    required this.updatedAt,
    this.activationCode,
    this.accessToken,
  });

  final String id;
  final String email;
  final String productName;
  final PassStatus status;
  final DateTime updatedAt;
  final String? activationCode;
  final String? accessToken;
}

class CachedOrder {
  const CachedOrder({
    required this.id,
    required this.maskedEmail,
    required this.productName,
    required this.status,
    required this.updatedAt,
    this.activationCode,
  });

  final String id;
  final String maskedEmail;
  final String productName;
  final PassStatus status;
  final DateTime updatedAt;
  final String? activationCode;

  CachedOrder copyWith({
    String? id,
    String? maskedEmail,
    String? productName,
    PassStatus? status,
    DateTime? updatedAt,
    String? activationCode,
  }) {
    return CachedOrder(
      id: id ?? this.id,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      productName: productName ?? this.productName,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      activationCode: activationCode ?? this.activationCode,
    );
  }

  @override
  String toString() {
    return 'CachedOrder(id: $id, email: $maskedEmail, product: $productName, status: $status, updatedAt: $updatedAt)';
  }
}

abstract interface class OrderApi {
  Future<List<RemoteOrder>> fetchOrders(String customerId);
}

abstract interface class OrderCache {
  Future<List<CachedOrder>> read(String customerId);
  Future<void> write(String customerId, List<CachedOrder> orders);
}

abstract interface class AuditLog {
  void info(String message);
  void warn(String message);
}
