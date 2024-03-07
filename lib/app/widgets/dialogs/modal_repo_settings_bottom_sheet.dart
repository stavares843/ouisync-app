import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ouisync_plugin/bindings.g.dart';

import '../../../generated/l10n.dart';
import '../../cubits/cubits.dart';
import '../../mixins/mixins.dart';
import '../../utils/utils.dart';
import '../widgets.dart';

class RepositorySettings extends StatefulWidget {
  const RepositorySettings(
      {required this.context, required this.cubit, required this.reposCubit});

  final BuildContext context;
  final RepoCubit cubit;
  final ReposCubit reposCubit;

  @override
  State<RepositorySettings> createState() => _RepositorySettingsState();
}

class _RepositorySettingsState extends State<RepositorySettings>
    with AppLogger, RepositoryActionsMixin {
  @override
  Widget build(BuildContext context) => BlocBuilder<RepoCubit, RepoState>(
        bloc: widget.cubit,
        builder: (context, state) => SingleChildScrollView(
            child: Container(
                padding: Dimensions.paddingBottomSheet,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Fields.bottomSheetHandle(context),
                      Fields.bottomSheetTitle(widget.cubit.name,
                          style: context.theme.appTextStyle.titleMedium),
                      _SwitchItem(
                        title: S.current.labelBitTorrentDHT,
                        icon: Icons.hub,
                        value: state.isDhtEnabled,
                        onChanged: (value) => widget.cubit.setDhtEnabled(value),
                      ),
                      _SwitchItem(
                        title: S.current.messagePeerExchange,
                        icon: Icons.group_add,
                        value: state.isPexEnabled,
                        onChanged: (value) => widget.cubit.setPexEnabled(value),
                      ),
                      if (state.accessMode == AccessMode.write)
                        _SwitchItem(
                          title: S.current.messageUseCacheServers,
                          icon: Icons.cloud_outlined,
                          value: state.isCacheServersEnabled,
                          onChanged: (value) =>
                              widget.cubit.setCacheServersEnabled(value),
                        ),
                      EntryActionItem(
                          iconData: Icons.edit,
                          title: S.current.actionRename,
                          dense: true,
                          onTap: () async => await renameRepository(
                              widget.context,
                              repository: widget.cubit,
                              reposCubit: widget.reposCubit,
                              popDialog: () => Navigator.of(context).pop())),
                      EntryActionItem(
                          iconData: Icons.share,
                          title: S.current.actionShare,
                          dense: true,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await shareRepository(context,
                                repository: widget.cubit);
                          }),
                      EntryActionItem(
                          iconData: Icons.password,
                          title: S.current.titleSecurity,
                          dense: true,
                          onTap: () async => await navigateToRepositorySecurity(
                                context,
                                repository: widget.cubit,
                                passwordHasher:
                                    widget.reposCubit.passwordHasher,
                                popDialog: () => Navigator.of(context).pop(),
                              )),
                      EntryActionItem(
                          iconData: Icons.delete,
                          title: S.current.actionDelete,
                          dense: true,
                          isDanger: true,
                          onTap: () async => await deleteRepository(context,
                              repositoryLocation: widget.cubit.location,
                              reposCubit: widget.reposCubit,
                              popDialog: () => Navigator.of(context).pop()))
                    ]))),
      );
}

class _SwitchItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;

  _SwitchItem({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
        title: Text(title, style: context.theme.appTextStyle.bodyMedium),
        secondary: Icon(
          icon,
          size: Dimensions.sizeIconMicro,
          color: Colors.black87,
        ),
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: VisualDensity(horizontal: -4.0),
        value: value,
        onChanged: onChanged,
      );
}
