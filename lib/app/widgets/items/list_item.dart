import 'package:flutter/material.dart';

import '../../cubits/cubits.dart';
import '../../models/models.dart';
import '../../utils/utils.dart';
import '../widgets.dart';

class ListItem extends StatelessWidget {
  const ListItem({
    required this.repository,
    required this.itemData,
    required this.mainAction,
    required this.verticalDotsAction,
  });

  final RepoCubit repository;
  final BaseItem itemData;
  final Function mainAction;
  final Function verticalDotsAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
          onTap: () => mainAction.call(),
          splashColor: Colors.blue,
          child: Container(
            padding: Dimensions.paddingListItem,
            child: _buildItem(),
          )),
      color: Colors.white,
    );
  }

  Widget _buildItem() {
    final data = itemData;

    if (data is RepoItem) {
      return _buildRepoItem(data);
    }

    if (data is FileItem) {
      return _buildFileItem(data);
    }

    if (data is FolderItem) {
      return _buildFolderItem(data);
    }

    assert(false, "Item must be either FileItem or FolderItem");
    return SizedBox.shrink();
  }

  Widget _buildRepoItem(RepoItem repoItem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
            flex: 1,
            child: Icon(Fields.accessModeIcon(repoItem.accessMode),
                size: Dimensions.sizeIconAverage,
                color: Constants.folderIconColor)),
        Expanded(
            flex: 9,
            child: Padding(
                padding: Dimensions.paddingItem,
                child: RepoDescription(repoData: repoItem))),
        _getVerticalMenuAction(false)
      ],
    );
  }

  Widget _buildFileItem(FileItem fileData) {
    final uploadJob = repository.state.uploads[fileData.path];
    final downloadJob = repository.state.downloads[fileData.path];

    final isUploading = uploadJob != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(flex: 1, child: FileIconAnimated(downloadJob)),
        Expanded(
            flex: 9,
            child: Padding(
                padding: Dimensions.paddingItem,
                child: FileDescription(repository, fileData, uploadJob))),
        _getVerticalMenuAction(isUploading)
      ],
    );
  }

  Widget _buildFolderItem(FolderItem folderItem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Expanded(
            flex: 1,
            child: Icon(Icons.folder_rounded,
                size: Dimensions.sizeIconAverage,
                color: Constants.folderIconColor)),
        Expanded(
            flex: 9,
            child: Padding(
                padding: Dimensions.paddingItem,
                child: FolderDescription(folderData: itemData))),
        _getVerticalMenuAction(false)
      ],
    );
  }

  Widget _getVerticalMenuAction(bool isUploading) {
    return IconButton(
        icon:
            const Icon(Icons.more_vert_rounded, size: Dimensions.sizeIconSmall),
        onPressed: isUploading ? null : () async => await verticalDotsAction());
  }
}
