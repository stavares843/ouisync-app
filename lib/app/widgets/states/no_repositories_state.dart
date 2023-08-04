import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../utils/utils.dart';

class NoRepositoriesState extends StatelessWidget {
  const NoRepositoriesState(
      {required this.onNewRepositoryPressed,
      required this.onImportRepositoryPressed});

  final Future<String?> Function() onNewRepositoryPressed;
  final Future<String?> Function() onImportRepositoryPressed;

  @override
  Widget build(BuildContext context) {
    final nothingHereYetImageHeight = MediaQuery.of(context).size.height *
        Constants.statePlaceholderImageHeightFactor;

    final mainMessageStyle = Theme.of(context).textTheme.titleLarge;
    final secondaryMessageStyle = Theme.of(context).textTheme.bodyMedium;

    return Center(
        child: SingleChildScrollView(
      reverse: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
              alignment: Alignment.center,
              child: Fields.placeholderWidget(
                  assetName: Constants.assetPathNothingHereYet,
                  assetHeight: nothingHereYetImageHeight)),
          Dimensions.spacingVerticalDouble,
          Align(
            alignment: Alignment.center,
            child: Fields.inPageMainMessage(S.current.messageNoRepos,
                style: mainMessageStyle),
          ),
          Dimensions.spacingVertical,
          Align(
              alignment: Alignment.center,
              child: Fields.inPageSecondaryMessage(
                  S.current.messageCreateNewRepo,
                  style: secondaryMessageStyle,
                  tags: {Constants.inlineTextBold: InlineTextStyles.bold})),
          Dimensions.spacingVerticalDouble,
          Dimensions.spacingVerticalDouble,
          Fields.inPageButton(
              onPressed: () async => await onNewRepositoryPressed.call(),
              text: S.current.actionCreateRepository,
              size: Dimensions.sizeInPageButtonRegular,
              autofocus: true),
          Dimensions.spacingVertical,
          Fields.inPageButton(
              onPressed: () async => await onImportRepositoryPressed.call(),
              text: S.current.actionAddRepositoryWithToken,
              size: Dimensions.sizeInPageButtonRegular),
        ],
      ),
    ));
  }
}
