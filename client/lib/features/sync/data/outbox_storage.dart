import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/models/outbox_operation.dart';

abstract interface class OutboxStorage {
  Future<List<OutboxOperation>> getPendingOperations();
  Future<List<OutboxOperation>> getAllOperations();
  Future<void> saveOperation(OutboxOperation operation);
  Future<void> updateOperation(OutboxOperation operation);
  Future<void> removeOperation(String operationId);
  Future<void> clear();
  Future<int> getCursor([String? tripId]);
  Future<void> saveCursor(int cursor, [String? tripId]);
}

class SecureOutboxStorage implements OutboxStorage {
  const SecureOutboxStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const _queueKey = 'tapittrip_outbox_queue';
  static const _cursorPrefix = 'tapittrip_sync_cursor_';

  @override
  Future<List<OutboxOperation>> getAllOperations() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) =>
                OutboxOperation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<OutboxOperation>> getPendingOperations() async {
    final all = await getAllOperations();
    return all
        .where((op) => op.status == 'pending' || op.status == 'conflict')
        .toList();
  }

  @override
  Future<void> saveOperation(OutboxOperation operation) async {
    final all = await getAllOperations();
    final index = all.indexWhere(
      (op) => op.operationId == operation.operationId,
    );
    if (index >= 0) {
      all[index] = operation;
    } else {
      all.add(operation);
    }
    await _writeAll(all);
  }

  @override
  Future<void> updateOperation(OutboxOperation operation) =>
      saveOperation(operation);

  @override
  Future<void> removeOperation(String operationId) async {
    final all = await getAllOperations();
    all.removeWhere((op) => op.operationId == operationId);
    await _writeAll(all);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _queueKey);
  }

  @override
  Future<int> getCursor([String? tripId]) async {
    final key = '$_cursorPrefix${tripId ?? 'global'}';
    final raw = await _storage.read(key: key);
    if (raw == null) return 0;
    return int.tryParse(raw) ?? 0;
  }

  @override
  Future<void> saveCursor(int cursor, [String? tripId]) async {
    final key = '$_cursorPrefix${tripId ?? 'global'}';
    await _storage.write(key: key, value: cursor.toString());
  }

  Future<void> _writeAll(List<OutboxOperation> operations) async {
    final jsonList = operations.map((e) => e.toJson()).toList();
    await _storage.write(key: _queueKey, value: jsonEncode(jsonList));
  }
}

class InMemoryOutboxStorage implements OutboxStorage {
  final List<OutboxOperation> _operations = [];
  final Map<String, int> _cursors = {};

  @override
  Future<List<OutboxOperation>> getAllOperations() async {
    return List.unmodifiable(_operations);
  }

  @override
  Future<List<OutboxOperation>> getPendingOperations() async {
    return _operations
        .where((op) => op.status == 'pending' || op.status == 'conflict')
        .toList();
  }

  @override
  Future<void> saveOperation(OutboxOperation operation) async {
    final index = _operations.indexWhere(
      (op) => op.operationId == operation.operationId,
    );
    if (index >= 0) {
      _operations[index] = operation;
    } else {
      _operations.add(operation);
    }
  }

  @override
  Future<void> updateOperation(OutboxOperation operation) =>
      saveOperation(operation);

  @override
  Future<void> removeOperation(String operationId) async {
    _operations.removeWhere((op) => op.operationId == operationId);
  }

  @override
  Future<void> clear() async {
    _operations.clear();
    _cursors.clear();
  }

  @override
  Future<int> getCursor([String? tripId]) async {
    return _cursors[tripId ?? 'global'] ?? 0;
  }

  @override
  Future<void> saveCursor(int cursor, [String? tripId]) async {
    _cursors[tripId ?? 'global'] = cursor;
  }
}
