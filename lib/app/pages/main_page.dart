import 'dart:async';
import 'dart:io' as io;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../generated/l10n.dart';
import '../bloc/blocs.dart';
import '../cubit/cubits.dart';
import '../models/folder_state.dart';
import '../models/main_state.dart';
import '../models/models.dart';
import '../utils/click_counter.dart';
import '../utils/loggers/ouisync_app_logger.dart';
import '../utils/platform/platform.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'pages.dart';

typedef RepositoryCallback = Future<void> Function(RepoState? repository, AccessMode? previousAccessMode);
typedef ShareRepositoryCallback = void Function();
typedef BottomSheetControllerCallback = void Function(PersistentBottomSheetController? controller, String entryPath);
typedef MoveEntryCallback = void Function(String origin, String path, EntryType type);
typedef SaveFileCallback = Future<void> Function({ SharedMediaFile? mobileSharedMediaFile, io.File? droppedMediaFile, bool usesModal });

class MainPage extends StatefulWidget {
  const MainPage({
    required this.session,
    required this.repositoriesLocation,
    required this.defaultRepositoryName,
    required this.mediaReceiver
  });

  final Session session;
  final String repositoriesLocation;
  final String defaultRepositoryName;
  final MediaReceiver mediaReceiver;

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
  with TickerProviderStateMixin, OuiSyncAppLogger {
    MainState _mainState = MainState();

    StreamSubscription<ConnectivityResult>? _connectivitySubscription;

    final _scaffoldKey = GlobalKey<ScaffoldState>();

    String _pathEntryToMove = '';
    PersistentBottomSheetController? _persistentBottomSheetController;

    Widget _mainWidget = LoadingMainPageState();

    final double defaultBottomPadding = kFloatingActionButtonMargin + Dimensions.paddingBottomWithFloatingButtonExtra;
    ValueNotifier<double> _bottomPaddingWithBottomSheet = ValueNotifier<double>(0.0);

    final exitClickCounter = ClickCounter(timeoutMs: 3000);

    FolderState? get currentFolder => _mainState.currentFolder;
    DirectoryBloc get _directoryBloc => BlocProvider.of<DirectoryBloc>(context);
    RepositoriesCubit get _reposCubit => BlocProvider.of<RepositoriesCubit>(context);
    RepositoryProgressCubit get _repoProgressCubit => BlocProvider.of<RepositoryProgressCubit>(context);
    UpgradeExistsCubit get _upgradeExistsCubit => BlocProvider.of<UpgradeExistsCubit>(context);

    @override
    void initState() {
      super.initState();

      widget.session.subscribeToNetworkEvents((event) {
        switch (event) {
          case NetworkEvent.peerSetChange: {
            BlocProvider.of<PeerSetCubit>(context).onPeerSetChanged(widget.session);
          }
          break;
          case NetworkEvent.protocolVersionMismatch: {
            final highest = widget.session.highest_seen_protocol_version;
            _upgradeExistsCubit.foundVersion(highest);
          }
          break;
        }
      });

      _mainState.setSubscriptionCallback((repo) {
        _repoProgressCubit.updateProgress(repo);
        getContent(repo);
      });

      _initRepositories().then((_) { initMainPage(); });

      /// The MediaReceiver uses the MediaReceiverMobile (_mediaIntentSubscription, _textIntentSubscription),
      /// or the MediaReceiverWindows (DropTarget), depending on the platform.
      widget.mediaReceiver.controller.stream.listen((media) {
        if (media is String) {
          loggy.app('mediaReceiver: String');
          addRepoWithTokenDialog(_reposCubit, initialTokenValue: media);
        }

        if (media is List<SharedMediaFile>) {
          loggy.app('mediaReceiver: List<ShareMediaFile>');
          handleShareIntentPayload(media);
        }

        if (media is io.File) {
          loggy.app('mediaReceiver: io.File');
          saveMedia(droppedMediaFile: media);
        }
      });

      _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen(_connectivityChange);
    }

    @override
    void dispose() async {
      await _mainState.close();
      _connectivitySubscription?.cancel();
      super.dispose();
    }

    Future<void> _initRepositories() async {
      final repositoriesCubit = _reposCubit;

      final initRepos = RepositoryHelper
      .localRepositoriesFiles(
        widget.repositoriesLocation,
        justNames: true
      ).map((repoName) async {
        final repo = await repositoriesCubit.initRepository(repoName);
        await _mainState.put(
          repo!,
          setCurrent: (repoName == widget.defaultRepositoryName)
        );
      }).toList();

      await Future.wait(initRepos);
    }

    void _connectivityChange(ConnectivityResult result) {
      loggy.app('Connectivity event: ${result.name}');

      BlocProvider
      .of<ConnectivityCubit>(context)
      .connectivityEvent(result);
    }

    void initMainPage() async {
      _bottomPaddingWithBottomSheet = ValueNotifier<double>(defaultBottomPadding);
      _reposCubit.selectRepository(_mainState.currentRepo);
    }

    void handleShareIntentPayload(List<SharedMediaFile> payload) {
      if (payload.isEmpty) {
        return;
      }

      _bottomPaddingWithBottomSheet.value = defaultBottomPadding + Dimensions.paddingBottomWithBottomSheetExtra;
      _showSaveSharedMedia(sharedMedia: payload);
    }

    switchMainWidget(newMainWidget) => setState(() { _mainWidget = newMainWidget; });

    getContent(RepoState repository) {
      _directoryBloc.add(GetContent(repository: repository));
    }

    navigateToPath(RepoState repository, String destination) {
      _directoryBloc.add(NavigateTo(repository, destination));
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: _buildOuiSyncBar(),
        body: WillPopScope(
          child: _mainWidget,
          onWillPop: _onBackPressed
        ),
        floatingActionButton: _buildFAB(context),
      );
    }

    Future<bool> _onBackPressed() async {
      final currentRepo = _mainState.currentRepo;
      final currentFolder = currentRepo?.currentFolder;

      if (currentFolder == null || currentFolder.isRoot()) {
        int clickCount = exitClickCounter.registerClick();

        if (clickCount <= 1) {
          showSnackBar(context, content: Text(S.current.messageExitOuiSync));

          // Don't pop => don't exit
          return false;
        } else {
          exitClickCounter.reset();
          // We still don't want to do the pop because that would destroy the
          // current Isolate's execution context and we would lose track of
          // open OuiSync objects (i.e. repositories, files, directories,
          // network handles,...). This is bad because even though the current
          // execution context is deleted, the OuiSync Rust global variables
          // and threads stay alive. If the user at that point tried to open
          // the app again, this widget would try to reinitialize all those
          // variables without previously properly closing them.
          MoveToBackground.moveTaskToBack();
          return false;
        }
      }

      if (currentRepo == null) {
        return false;
      }

      currentFolder.goUp();
      getContent(currentRepo);

      return false;
    }

    _buildOuiSyncBar() => OuiSyncBar(
      repoList: _buildRepositoriesBar(),
      settingsButton: _buildSettingsIcon(),
      bottomWidget: FolderNavigationBar(_mainState),
    );

    RepositoriesBar _buildRepositoriesBar() {
      return RepositoriesBar(
        mainState: _mainState,
        repositoriesCubit: _reposCubit,
        onRepositorySelect: switchRepository,
        shareRepositoryOnTap: shareRepository,
      );
    }

    Widget _buildSettingsIcon() {
      final button = Fields.actionIcon(
        const Icon(Icons.settings_outlined),
        onPressed: () async {
          bool dhtStatus = await _mainState.currentRepo?.isDhtEnabled() ?? false;
          settingsAction(dhtStatus);
        },
        size: Dimensions.sizeIconSmall,
        color: Theme.of(context).colorScheme.surface
      );
      // TODO: Add a link to where one can download a new version (if any).
      return Container(child: Fields.addUpgradeBadge(button));
    }

    StatelessWidget _buildFAB(BuildContext context,) {
      final current = _mainState.currentRepo;

      if (current == null) {
        return Container();
      }

      if ([AccessMode.blind, AccessMode.read].contains(current.accessMode)) {
        return Container();
      }

      return new FloatingActionButton(
        heroTag: Constants.heroTagMainPageActions,
        child: const Icon(Icons.add_rounded),
        onPressed: () => _showDirectoryActions(
          context,
          bloc: _directoryBloc,
          folder: currentFolder!
        ),
      );
    }

    Future<void> switchRepository(RepoState? repository, AccessMode? previousAccessMode) async {
      await _mainState.setCurrent(repository);

      if (repository == null) {
        switchMainWidget(
          NoRepositoriesState(
            repositoriesCubit: _reposCubit,
            onNewRepositoryPressed: createRepoDialog,
            onAddRepositoryPressed: addRepoWithTokenDialog
          )
        );
        return;
      }

      switchMainWidget(_repositoryContentBuilder());

      navigateToPath(_mainState.currentRepo!, Strings.root);
    }

    void shareRepository() async {
      final current = _mainState.currentRepo;

      if (current == null) {
        return;
      }

      await _showShareRepository(context, current);
    }

    _repositoryContentBuilder() => BlocConsumer<DirectoryBloc, DirectoryState>(
      buildWhen: (context, state) {
        return !(
        state is CreateFileDone ||
        state is WriteToFileInProgress ||
        state is WriteToFileDone ||
        state is DownloadFileInProgress ||
        state is DownloadFileDone ||
        state is DownloadFileCancel ||
        state is DownloadFileFail ||
        state is ShowMessage);
      },
      builder: (context, state) {
        if (state is DirectoryInitial) {
          return Center(
            child: Fields.inPageSecondaryMessage(S.current.messageLoadingContents)
          );
        }

        if (state is DirectoryLoadInProgress) {
          return Center(child: CircularProgressIndicator());
        }

        if (state is DirectoryReloaded) {
          return _selectLayoutWidget();
        }

        return _errorState(
          message: S.current.messageErrorLoadingContents,
          actionReload: () => getContent(_mainState.currentRepo!)
        );
      },
      listener: (context, state) {
        if (state is ShowMessage) {
          showSnackBar(context, content: Text((state as ShowMessage).message));
        }
      }
    );

    _selectLayoutWidget() {
      final current = _mainState.currentRepo;

      if (current == null) {
        return NoRepositoriesState(
          repositoriesCubit: _reposCubit,
          onNewRepositoryPressed: createRepoDialog,
          onAddRepositoryPressed: addRepoWithTokenDialog
        );
      }

      if (current.accessMode == AccessMode.blind) {
        return LockedRepositoryState(
          repositoryName: current.name,
          onUnlockPressed: unlockRepositoryDialog,
        );
      }

      if (currentFolder!.content.isEmpty) {
        return NoContentsState(
          repository: current,
          path: currentFolder!.path
        );
      }

      return _contentsList(
        repository: current,
        path: currentFolder!.path
      );
    }

    _errorState({
      required String message,
      required void Function()? actionReload
    }) => ErrorState(
      message: message,
      onReload: actionReload
    );

    _contentsList({
      required RepoState repository,
      required String path
    }) => ValueListenableBuilder(
      valueListenable: _bottomPaddingWithBottomSheet,
      builder: (context, value, child) => RefreshIndicator(
        onRefresh: () async => getContent(repository),
        child: ListView.separated(
          padding: EdgeInsets.only(bottom: value as double),
          separatorBuilder: (context, index) =>
            const Divider(
              height: 1,
              color: Colors.transparent),
          itemCount: currentFolder!.content.length,
          itemBuilder: (context, index) {
            final item = currentFolder!.content[index];
            final actionByType = item.type == ItemType.file
            ? () async {
              if (_persistentBottomSheetController != null) {
                await Dialogs.simpleAlertDialog(
                  context: context,
                  title: S.current.titleMovingEntry,
                  message: S.current.messageMovingEntry
                );
                return;
              }

              await _showFileDetails(
                repo: repository,
                directoryBloc: _directoryBloc,
                scaffoldKey: _scaffoldKey,
                data: item
              );
            }
            : () {
              if (_persistentBottomSheetController != null && _pathEntryToMove == item.path) {
                return;
              }

              navigateToPath(repository, item.path);
            };

            final listItem = ListItem (
              itemData: item,
              mainAction: actionByType,
              folderDotsAction: () async {
                if (_persistentBottomSheetController != null) {
                  await Dialogs.simpleAlertDialog(
                    context: context,
                    title: S.current.titleMovingEntry,
                    message: S.current.messageMovingEntry
                  );

                  return;
                }

                item.type == ItemType.file
                ? await _showFileDetails(
                  repo: repository,
                  directoryBloc: _directoryBloc,
                  scaffoldKey: _scaffoldKey,
                  data: item)
                : await _showFolderDetails(
                  repo: repository,
                  directoryBloc: _directoryBloc,
                  scaffoldKey: _scaffoldKey,
                  data: item);
              },
            );

            return listItem;
          }
        )
      )
    );

    Future<dynamic> _showShareRepository(context, RepoState repo_state)
        => showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusAverage),
          topRight: Radius.circular(Dimensions.radiusAverage),
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero
        ),
      ),
      builder: (context) {
        final accessModes = repo_state.accessMode == AccessMode.write
          ? [AccessMode.blind, AccessMode.read, AccessMode.write]
          : repo_state.accessMode == AccessMode.read
            ? [AccessMode.blind, AccessMode.read]
            : [AccessMode.blind];

        return ShareRepository(
          repository: repo_state,
          repositoryName: repo_state.name,
          availableAccessModes: accessModes,
        );
      }
    );

    Future<dynamic> _showFileDetails({
      required RepoState repo,
      required DirectoryBloc directoryBloc,
      required GlobalKey<ScaffoldState> scaffoldKey,
      required BaseItem data
    }) => showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusSmall),
          topRight: Radius.circular(Dimensions.radiusSmall),
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero
        ),
      ),
      builder: (context) {
        return FileDetail(
          context: context,
          bloc: directoryBloc,
          repository: repo,
          data: data as FileItem,
          scaffoldKey: scaffoldKey,
          onBottomSheetOpen: retrieveBottomSheetController,
          onMoveEntry: moveEntry
        );
      }
    );

    Future<dynamic> _showFolderDetails({
      required RepoState repo,
      required DirectoryBloc directoryBloc,
      required GlobalKey<ScaffoldState> scaffoldKey,
      required BaseItem data
    }) => showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusSmall),
          topRight: Radius.circular(Dimensions.radiusSmall),
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero
        ),
      ),
      builder: (context) {
        return FolderDetail(
          context: context,
          bloc: directoryBloc,
          repository: repo,
          data: data as FolderItem,
          scaffoldKey: scaffoldKey,
          onBottomSheetOpen: retrieveBottomSheetController,
          onMoveEntry: moveEntry
        );
      }
    );

  PersistentBottomSheetController? _showSaveSharedMedia({
    required List<SharedMediaFile> sharedMedia
  }) => _scaffoldKey.currentState?.showBottomSheet(
    (context) {
      return SaveSharedMedia(
        sharedMedia: sharedMedia,
        onBottomSheetOpen: retrieveBottomSheetController,
        onSaveFile: saveMedia
      );
    },
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero
      ),
    )
  );

  void retrieveBottomSheetController(PersistentBottomSheetController? controller, String entryPath) {
    _persistentBottomSheetController = controller;
    _pathEntryToMove = entryPath;
    _bottomPaddingWithBottomSheet.value = defaultBottomPadding;
  }

  void moveEntry(origin, path, type) async {
    final basename = getBasename(path);
    final destination = buildDestinationPath(currentFolder!.path, basename);

    _persistentBottomSheetController!.close();
    _persistentBottomSheetController = null;

    _directoryBloc.add(
      MoveEntry(
        repository: _mainState.currentRepo!,
        source: path,
        destination: destination
      )
    );
  }

    Future<void> saveMedia({ SharedMediaFile? mobileSharedMediaFile, io.File? droppedMediaFile, usesModal = false }) async {
    final currentRepo = _mainState.currentRepo;

    if (currentRepo == null) {
      showSnackBar(context, content: Text(S.current.messageNoRepo));
      return;
    }

    if (mobileSharedMediaFile == null &&
    droppedMediaFile == null) {
      showSnackBar(context, content: Text(S.current.mesageNoMediaPresent));
      return;
    }

    String? accessModeMessage = currentRepo.accessMode == AccessMode.blind
      ? S.current.messageAddingFileToLockedRepository
      : currentRepo.accessMode == AccessMode.read
        ? S.current.messageAddingFileToReadRepository
        : null;

    if (accessModeMessage != null) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (context) {
          return AlertDialog(
            title: Text(S.current.titleAddFile),
            content: SingleChildScrollView(
              child: ListBody(children: [
                Text(accessModeMessage)
              ]),
            ),
            actions: [
              TextButton(
                child: Text(S.current.actionCloseCapital),
                onPressed: () => 
                Navigator.of(context).pop(),
              )
            ],
          );
      });

      return;
    }

    final String? path = mobileSharedMediaFile?.path ?? droppedMediaFile?.path;
    if (path == null) {
      return;
    }

    loggy.app('Media path: $path');
    saveFileToOuiSync(path);

    if (usesModal) {
      Navigator.of(context).pop();
    }

  }

  void saveFileToOuiSync(String path) {
    final fileName = getBasename(path);
    final length = io.File(path).statSync().size;
    final filePath = buildDestinationPath(currentFolder!.path, fileName);
    final fileByteStream = io.File(path).openRead();
        
    _directoryBloc.add(
      SaveFile(
        repository: _mainState.currentRepo!,
        newFilePath: filePath,
        fileName: fileName,
        length: length,
        fileByteStream: fileByteStream
      )
    );
  }

  Future<dynamic> _showDirectoryActions(BuildContext context,{
    required DirectoryBloc bloc,
    required FolderState folder
  }) => showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(Dimensions.radiusSmall),
        topRight: Radius.circular(Dimensions.radiusSmall),
        bottomLeft: Radius.zero,
        bottomRight: Radius.zero
      ),
    ),
    builder: (context) {
      return DirectoryActions(
        context: context,
        bloc: bloc,
        parent: folder,
      );
    }
  );

  void createRepoDialog(cubit) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();

        return ActionsDialog(
          title: S.current.titleCreateRepository,
          body: RepositoryCreation(
            context: context,
            cubit: cubit,
            formKey: formKey,
          ),
        );
      }
    );
  }

  void addRepoWithTokenDialog(cubit, { String? initialTokenValue }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();

        return ActionsDialog(
          title: S.current.titleAddRepository,
          body: AddRepositoryWithToken(
            context: context,
            cubit: cubit,
            formKey: formKey,
            initialTokenValue: initialTokenValue,
          ),
        );
      }
    ).then((addedRepository) {
      if (addedRepository.isNotEmpty) { // If a repository is created, the new repository name is returned; otherwise, empty string.
        switchMainWidget(_repositoryContentBuilder());
      }
    });
  }

  void unlockRepositoryDialog(String repositoryName) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();

        return ActionsDialog(
          title: S.current.messageUnlockRepository,
          body: UnlockRepository(
            context: context,
            formKey: formKey,
            repositoryName:  repositoryName
          ),
        );
      }
    ).then((password) async {
      if (password.isNotEmpty) { // The password provided by the user.
        final name = _mainState.currentRepo!.name;
        await _mainState.remove(name);

        _reposCubit.unlockRepository(
          name: repositoryName,
          password: password
        );
      }
    });
  }

  void settingsAction(dhtStatus) {
    final connectivityCubit = BlocProvider.of<ConnectivityCubit>(context);
    final peerSetCubit = BlocProvider.of<PeerSetCubit>(context);
    final reposCubit = _reposCubit;
    final upgradeExistsCubit = _upgradeExistsCubit;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: connectivityCubit),
            BlocProvider.value(value: peerSetCubit),
            BlocProvider.value(value: upgradeExistsCubit),
          ],
          child: SettingsPage(
            mainState: _mainState,
            repositoriesCubit: reposCubit,
            onRepositorySelect: switchRepository,
            onShareRepository: shareRepository,
            title: S.current.titleSettings,
            dhtStatus: dhtStatus,
          )
        );
      })
    );
  }
}
