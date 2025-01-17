import 'package:boorusphere/data/repository/booru/entity/page_option.dart';
import 'package:boorusphere/data/repository/server/entity/server_data.dart';
import 'package:boorusphere/data/repository/setting/entity/setting.dart';
import 'package:boorusphere/domain/provider.dart';
import 'package:boorusphere/domain/repository/setting_repo.dart';
import 'package:boorusphere/presentation/provider/settings/entity/server_setting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_setting_state.g.dart';

@riverpod
class ServerSettingState extends _$ServerSettingState {
  late SettingRepo _repo;

  @override
  ServerSetting build() {
    _repo = ref.read(settingRepoProvider);
    return ServerSetting(
      active: _repo.get(Setting.serverActive, or: ServerData.empty),
      postLimit:
          _repo.get(Setting.serverPostLimit, or: PageOption.defaultLimit),
      safeMode: _repo.get(Setting.serverSafeMode, or: true),
    );
  }

  Future<void> setActiveServer(ServerData value) async {
    state = state.copyWith(active: value);
    await _repo.put(Setting.serverActive, value);
  }

  Future<void> setPostLimit(int value) async {
    state = state.copyWith(postLimit: value);
    await _repo.put(Setting.serverPostLimit, value);
  }

  Future<void> setSafeMode(bool value) async {
    state = state.copyWith(safeMode: value);
    await _repo.put(Setting.serverSafeMode, value);
  }
}
