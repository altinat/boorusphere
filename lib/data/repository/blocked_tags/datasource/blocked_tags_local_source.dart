import 'dart:convert';

import 'package:boorusphere/data/repository/blocked_tags/entity/booru_tag.dart';
import 'package:boorusphere/presentation/provider/data_backup/data_backup.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BlockedTagsLocalSource {
  BlockedTagsLocalSource(this.box);

  final Box<BooruTag> box;

  Map<int, BooruTag> get() {
    return Map.from(box.toMap());
  }

  Future<void> delete(key) async {
    await box.delete(key);
  }

  Future<void> push(BooruTag value) async {
    final tag = value.copyWith(name: value.name.trim());
    if (tag.name.isNotEmpty && !box.values.contains(tag)) {
      await box.add(tag);
    }
  }

  Future<void> import(String src) async {
    final List maps = jsonDecode(src);
    if (maps.isEmpty) return;
    await box.deleteAll(box.keys);
    for (final data in maps) {
      if (data is Map) {
        final tag = BooruTag.fromJson(Map.from(data));
        await push(tag);
      } else if (data is String) {
        await push(BooruTag(name: data));
      }
    }
  }

  Future<BackupItem> export() async {
    return BackupItem(key, box.values.map((e) => e.toJson()).toList());
  }

  static const String key = 'blockedTags';

  static Future<void> prepare() async {
    final box = await Hive.openBox(key);
    for (final tag in box.toMap().entries) {
      if (tag.value is String) {
        await box.put(tag.key, BooruTag(name: tag.value));
      }
    }
    await box.close();
    await Hive.openBox<BooruTag>(key);
  }
}
