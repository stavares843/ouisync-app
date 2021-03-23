import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ouisync_app/app/data/data.dart';
import 'package:styled_text/styled_text.dart';

import '../bloc/blocs.dart';
import '../controls/controls.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class FolderPage extends StatefulWidget {
  FolderPage({
    Key key, 
    @required this.repoPath,
    @required this.folderPath,
    @required this.foldersRepository,
    this.title
  }) : 
  assert(repoPath != null),
  assert(repoPath != ''),
  assert(folderPath != null),
  assert(foldersRepository != null),
  super(key: key);

  final String repoPath;
  final String folderPath;
  final DirectoryRepository foldersRepository;
  final String title;

  @override
  _FolderPageState createState() => _FolderPageState();

}

class _FolderPageState extends State<FolderPage> {
  final _createFolderFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    BlocProvider.of<DirectoryBloc>(context).add(
      ContentRequest(
        repoPath: widget.repoPath, 
        folderRelativePath: widget.folderPath,
      )
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: FloatingActionButton.extended(
        label: Text('Actions'),
        backgroundColor: Colors.blue,
        onPressed: () {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return ActionsDialog(
                title: 'Actions',
                body: _folderActions(),
              );
            }
          );
        },
      ),
    );
  }

  _folderActions() => Column(
    children: [
      _createFolder(),
    ],
  );

  _createFolder() => Form(
    key: _createFolderFormKey,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      children: [
        TextFormField(
          decoration: InputDecoration (
            icon: const Icon(Icons.folder),
            hintText: 'Folder name',
            labelText: 'Create a new folder',
            contentPadding: EdgeInsets.all(10.0),
          ),
          validator: (value) {
            return value.isEmpty
            ? 'Please enter some text'
            : null;
          },
          onSaved: (newFolderName) {
            String newPath = widget.folderPath.isEmpty
            ? newFolderName
            : '${widget.folderPath}/$newFolderName';

            BlocProvider.of<DirectoryBloc>(context)
            .add(
              FolderCreate(
                repoPath: widget.repoPath,
                parentPath: widget.folderPath,
                newFolderRelativePath: newPath
              )
            );

            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: () {
            if (_createFolderFormKey.currentState.validate()) {
              _createFolderFormKey.currentState.save();
            }
          },
          child: const Text('create'),
        ),
      ],
    )
  );

  Widget _folderContentsBlocBuilder() {
    return Center(
        child: BlocBuilder<DirectoryBloc, DirectoryState>(
            builder: (context, state) {
              if (state is DirectoryInitial) {
                return Center(child: Text('Loading ${widget.folderPath} contents...'));
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
          widget.folderPath.isEmpty
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
                String path = widget.folderPath.isEmpty
                ? item.name
                : '${widget.folderPath}/${item.name}';

                _actionByType(widget.repoPath, path, widget.foldersRepository, item.name); 
              }
          );
        }
    );
  }

  void _actionByType(String repoPath, String folderPath, DirectoryRepository repository, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return BlocProvider(
          create: (context) => DirectoryBloc(
            repository: widget.foldersRepository
          ),
          child: FolderPage(
            repoPath: repoPath,
            folderPath: folderPath,
            foldersRepository: repository,
            title: title,
          )
        );
      })
    );
  }

}
        // return new ;
        // return item.itemType == ItemType.folder
        //    FolderPage(title: item.name, repoPath: widget.repoPath, folder: item.name)
        // : FilePage(title: item.name, data: item)