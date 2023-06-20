import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../cubits/cubits.dart';
import '../../mixins/repo_actions_mixin.dart';
import '../../utils/log.dart';
import '../../utils/platform/platform.dart';
import '../widgets.dart';

class SettingsContainer extends StatefulWidget {
  const SettingsContainer({
    required this.reposCubit,
    required this.isBiometricsAvailable,
    required this.notificationBadgeBuilder,
  });

  final ReposCubit reposCubit;
  final bool isBiometricsAvailable;
  final NotificationBadgeBuilder notificationBadgeBuilder;

  @override
  State<SettingsContainer> createState() => _SettingsContainerState();
}

class _SettingsContainerState extends State<SettingsContainer>
    with AppLogger, RepositoryActionsMixin {
  SettingItem? _selected;

  @override
  void initState() {
    final defaultSetting = settingsItems
        .firstWhereOrNull((element) => element.setting == Setting.repository);
    setState(() => _selected = defaultSetting);

    super.initState();
  }

  @override
  Widget build(BuildContext context) => PlatformValues.isMobileDevice
      ? _buildMobileLayout()
      : _buildDesktopLayout();

  Widget _buildMobileLayout() =>
      SettingsList(platform: PlatformUtils.detectPlatform(context), sections: [
        NetworkSectionMobile(),
        LogsSectionMobile(
          repos: widget.reposCubit,
          panicCounter: widget.notificationBadgeBuilder.panicCounter,
        ),
        AboutSectionMobile(repos: widget.reposCubit)
      ]);

  Widget _buildDesktopLayout() => Row(children: [
        Flexible(
          flex: 1,
          child: SettingsDesktopList(
              onItemTap: (setting) => setState(() => _selected = setting),
              notificationBadgeBuilder: widget.notificationBadgeBuilder,
              selectedItem: _selected),
        ),
        Flexible(
          flex: 4,
          child: SettingsDesktopDetail(
            item: _selected,
            reposCubit: widget.reposCubit,
            notificationBadgeBuilder: widget.notificationBadgeBuilder,
            isBiometricsAvailable: widget.isBiometricsAvailable,
          ),
        )
      ]);
}
