import 'dart:convert';

import 'package:boorusphere/data/entity/server_data.dart';
import 'package:boorusphere/data/source/settings/server/active.dart';
import 'package:boorusphere/utils/extensions/asyncvalue.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final _defaultData = FutureProvider((ref) => ServerDataLoader.loadDefaults());

final _savedData = FutureProvider((ref) {
  final defaults = ref.watch(_defaultData);
  return ServerDataLoader.loadSaved(defaults.maybeValue ?? {});
});

final serverDataProvider =
    StateNotifierProvider<ServerDataSource, List<ServerData>>((ref) {
  final defaults = ref.watch(_defaultData).maybeValue;
  final saved = ref.watch(_savedData).maybeValue;
  return ServerDataSource(ref, saved ?? [], defaults ?? {});
});

class ServerDataLoader {
  static Future<void> validateAndMigrateKeys(Box box) async {
    final mapped = Map<String, ServerData>.from(box.toMap());
    for (final data in mapped.entries) {
      if (data.key.startsWith('@')) {
        continue;
      }
      await box.delete(data.key);
      await box.put(data.value.key, data.value);
    }
    await box.flush();
  }

  static Future<Map<String, ServerData>> loadDefaults() async {
    final json = await rootBundle.loadString('assets/servers.json');
    final servers = jsonDecode(json) as List;

    return Map.fromEntries(servers.map((it) {
      final value = ServerData.fromJson(it);
      return MapEntry(value.key, value);
    }));
  }

  static Future<List<ServerData>> loadSaved(defaultServers) async {
    if (defaultServers.isEmpty) return [];

    final box = Hive.box('server');
    if (box.isEmpty) {
      await box.putAll(defaultServers);
    } else {
      await validateAndMigrateKeys(box);
    }
    return box.values.map((it) => it as ServerData).toList();
  }
}

class ServerDataSource extends StateNotifier<List<ServerData>> {
  ServerDataSource(this.ref, super.state, this.defaults) {
    if (super.state.isNotEmpty) {
      // execute it anonymously since we can't update other state
      // while constructing a state
      Future.delayed(Duration.zero, () => _initLazily(ref, super.state));
    }
  }

  final Ref ref;
  final Map<String, ServerData> defaults;

  Box get _box => Hive.box('server');

  Set<ServerData> get allWithDefaults => {...defaults.values, ...state};

  ServerData get serverActive => ref.read(serverActiveProvider);
  ServerActiveState get serverActiveNotifier =>
      ref.read(serverActiveProvider.notifier);

  Future<void> _initLazily(Ref ref, List<ServerData> servers) async {
    if (serverActive == ServerData.empty) {
      await serverActiveNotifier
          .update(servers.firstWhere((it) => it.id.startsWith('Safe')));
    }
  }

  void reloadFromBox() {
    state = _box.values.map((it) => it as ServerData).toList();
  }

  ServerData getById(String id, {ServerData? or}) {
    return state.isEmpty
        ? ServerData.empty
        : state.firstWhere((it) => it.id == id,
            orElse: () => or ?? state.first);
  }

  Future<void> add({required ServerData data}) async {
    await _box.put(data.key,
        data.apiAddr == data.homepage ? data.copyWith(apiAddr: '') : data);
    reloadFromBox();
  }

  void delete({required ServerData data}) {
    if (state.length == 1) {
      throw Exception('Last server cannot be deleted');
    }
    _box.delete(data.key);
    reloadFromBox();
    if (serverActive == data) {
      serverActiveNotifier.update(state.first);
    }
  }

  Future<void> edit({
    required ServerData prev,
    required ServerData next,
  }) async {
    final newData = next.apiAddr == next.homepage
        ? next.copyWith(id: prev.id, apiAddr: '')
        : next.copyWith(id: prev.id);

    await _box.put(prev.key, newData);
    reloadFromBox();
    if (serverActive == prev) {
      await serverActiveNotifier.update(newData);
    }
  }

  Future<void> reset() async {
    await _box.deleteAll(_box.keys);
    await _box.putAll(defaults);
    reloadFromBox();
    await serverActiveNotifier.update(state.first);
  }
}