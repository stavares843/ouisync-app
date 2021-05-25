import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ouisync_plugin/ouisync_plugin.dart';
import 'package:styled_text/styled_text.dart';

import '../bloc/blocs.dart';
import '../controls/controls.dart';
import '../data/data.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'pages.dart';

class FolderPage extends StatefulWidget {
  FolderPage({
    Key key, 
    @required this.repository,
    @required this.foldersRepository,
    @required this.path,
    @required this.title
  }) : super(key: key);

  final Repository repository;
  final DirectoryRepository foldersRepository;
  final String path;
  final String title;

  @override
  _FolderPageState createState() => _FolderPageState();

}

class _FolderPageState extends State<FolderPage>
  with TickerProviderStateMixin {

  AnimationController _controller;
  
  Color backgroundColor;
  Color foregroundColor;

  @override
  void initState() {
    super.initState();

    initAnimationController();

    getFolderContents();    
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  initAnimationController() => _controller = new AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: actionsFloatingActionButtonAnimationDuration),
  );

  getFolderContents() => BlocProvider.of<DirectoryBloc>(context)
  .add(RequestContent(
    repository: widget.repository,
    path: widget.path,
    recursive: false
  ));

  @override
  Widget build(BuildContext context) {
    backgroundColor = Theme.of(context).cardColor;
    foregroundColor = Theme.of(context).accentColor;

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget> [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () async {

              },
            )
          ]
      ),
      body: _folderContentsBlocBuilder(),
      floatingActionButton: Dialogs.floatingActionsButtonMenu(
        BlocProvider. of<DirectoryBloc>(context),
        widget.repository,
        context,
        _controller,
        widget.path,
        folderActions,
        flagFolderActionsDialog,
        backgroundColor,
        foregroundColor
      )
    );
  }

  Widget _folderContentsBlocBuilder() {
    return Center(
        child: BlocBuilder<DirectoryBloc, DirectoryState>(
            builder: (context, state) {
              if (state is DirectoryInitial) {
                return Center(child: Text('Loading ${widget.path} contents...'));
              }

              if (state is DirectoryLoadInProgress){
                return Center(child: CircularProgressIndicator());
              }

              if (state is DirectoryLoadSuccess) {
                final contents = state.contents;

                return contents.isEmpty 
                ? _noContents()
                : _contentsList(contents);
              }

              if (state is DirectoryLoadFailure) {
                return Text(
                  'Something went wrong!',
                  style: TextStyle(color: Colors.red),
                );
              }

              return Center(child: Text('root'));
            }
        )
    );
  }

  _noContents() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Align(
        alignment: Alignment.center,
        child: Text(
          widget.path.isEmpty
          ? messageEmptyRepo
          : messageEmptyFolder,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      SizedBox(height: 20.0),
      Align(
        alignment: Alignment.center,
        child: StyledText(
          text: messageCreateAddNewObjectStyled,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.normal
          ),
          styles: {
            'bold': TextStyle(fontWeight: FontWeight.bold),
            'arrow_down': IconStyle(Icons.south),
          },
        ),
      ),
    ],
  );

  _contentsList(List<BaseItem> contents) {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.transparent
        ),
        itemCount: contents.length,
        itemBuilder: (context, index) {
          final item = contents[index];
          return ListItem (
              itemData: item,
              action: () {
                _actionByType(widget.foldersRepository, widget.path, item); 
              }
          );
        }
    );
  }

  void _actionByType(DirectoryRepository folderRespository, String folderPath, BaseItem data) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return BlocProvider(
          create: (context) => DirectoryBloc(
            repository: widget.foldersRepository
          ),
          child: _pageByType(
            folderRespository,
            folderPath,
            data
          ),
        );
      })
    );
  }

  _pageByType(DirectoryRepository folderRepository, String folderPath, BaseItem data) { 
    String destinationPath = folderPath == '/'
      ? '/${data.name}'
      : '$folderPath/${data.name}';

    return data.itemType == ItemType.folder
    ? FolderPage(
      repository: widget.repository,
      foldersRepository: folderRepository,
      path: destinationPath,
      title: destinationPath,
    )
    : FilePage(
      repository: widget.repository,
      foldersRepository: folderRepository,
      folderPath: folderPath,
      data: data,
      title: '$folderPath/${data.name}'
    );
  }
}