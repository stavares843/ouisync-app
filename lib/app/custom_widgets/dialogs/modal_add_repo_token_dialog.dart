import 'package:flutter/material.dart';

import '../../cubit/cubits.dart';
import '../../utils/utils.dart';

class AddRepositoryWithToken extends StatefulWidget {
  const AddRepositoryWithToken({
    Key? key,
    required this.context,
    required this.cubit,
    required this.formKey
  }) : super(key: key);

  final BuildContext context;
  final RepositoriesCubit cubit;
  final GlobalKey<FormState> formKey;

  @override
  State<AddRepositoryWithToken> createState() => _AddRepositoryWithTokenState();
}

class _AddRepositoryWithTokenState extends State<AddRepositoryWithToken> {

  final TextEditingController _nameController = TextEditingController(text: null);
  final TextEditingController _passwordController = new TextEditingController(text: null);
  final TextEditingController _retypedPasswordController = new TextEditingController(text: null);

  String _suggestedName = '';
  bool _showSuggestedName = false;

  String? _repoName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: this.widget.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(16.0))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCreateFolderWidget(this.widget.context),
          ],
        ),
      )
    );
  }

  Widget _buildCreateFolderWidget(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Fields.formTextField(
            context: context,
            label: 'Repository token: ',
            hint: 'Paste the token here',
            onSaved: (value) {},
            validator: _repositoryTokenValidator,
            autofocus: true,
            onChanged: _onTokenChanged
          ),
          SizedBox(height: 20.0,),
          Fields.formTextField(
            context: context,
            textEditingController: _nameController,
            label: 'Repository name: ',
            hint: 'Give the repo a name',
            onSaved: (_) {},
            validator: formNameValidator,
            autovalidateMode: AutovalidateMode.disabled
          ),
          Visibility(
            visible: _showSuggestedName,
            child: GestureDetector(
              onTap: () => _updateNameController(_suggestedName),
              child: Fields.constrainedText(
                'Suggested: $_repoName\n(tap for using this name)',
                size: 15.0,
                fontWeight: FontWeight.normal,
                color: Colors.black54
              ),
            )
          ),
          Fields.formTextField(
            context: context,
            textEditingController: _passwordController,
            obscureText: true,
            label: 'Create a password: ',
            hint: 'Repository password',
            onSaved: (_) {},
            validator: (password, { error = 'Please enter a password' }) 
              => formNameValidator(password, error: error),
            autovalidateMode: AutovalidateMode.disabled
          ),
          Fields.formTextField(
            context: context,
            textEditingController: _retypedPasswordController,
            obscureText: true,
            label: 'Retype the password: ',
            hint: 'Repository password',
            onSaved: (_) {},
            validator: (retypedPassword, { error = 'The password and retyped password doesn\'t match' })
              => retypedPasswordValidator(
                password: _passwordController.text,
                retypedPassword: retypedPassword!,
                error: error
              ),
            autovalidateMode: AutovalidateMode.disabled
          ),
          Fields.actionsSection(
            context,
            buttons: _actions(context)
          ),
        ]
      )
    );
  }

  _updateNameController(String? value) => _nameController.text = value ?? '';

  String? retypedPasswordValidator({
    required String password,
    required String retypedPassword,
    required String error
  }) {
    if (password != retypedPassword) {
      return error;
    }

    return null;
  }

  _onTokenChanged(value) {
    if (value.isEmpty) {
      return;
    }

    bool showSuggestedNameSection = false;

    try {
      _suggestedName = this.widget.cubit.session
      .extractSuggestedNameFromShareToken(value);  

      if (_suggestedName.isNotEmpty) {
        _repoName = _suggestedName;
        showSuggestedNameSection = true;  
      }
    } catch (e) {
      print('Error extracting the repository token:\n${e.toString()}');                
      showToast('The token seems to be invalid.');

      _suggestedName = '';
      _repoName = '';

      _updateNameController(null);
      showSuggestedNameSection = false;
    }

    setState(() { _showSuggestedName = showSuggestedNameSection; });
  }

  String? _repositoryTokenValidator(String? value, { String error = 'Please enter a valid token'}) {
    if ((value ?? '').isEmpty) {
      return 'Please enter a token';
    }

    try {
      _suggestedName = this.widget.cubit.session.extractSuggestedNameFromShareToken(value!);
    } catch (e) {
      _suggestedName = '';
      return error;
    }

    return null;
  }

  void _onSaved(RepositoriesCubit cubit, String name, String password) async {
    if (!widget.formKey.currentState!.validate()) {
      return;
    }

    widget.formKey.currentState!.save();
    Auth.setPassword(name, password);
    
    cubit.openRepository(name: name, password: password);
    Navigator.of(this.widget.context).pop(name);
  }

  List<Widget> _actions(context) => [
    ElevatedButton(
      onPressed: () {
        final newRepositoryName = _nameController.text;
        final password = _passwordController.text;

        _onSaved(widget.cubit, newRepositoryName, password);
      },
      child: Text('Create')
    ),
    SizedBox(width: 20.0,),
    OutlinedButton(
      onPressed: () => Navigator.of(context).pop(''),
      child: Text('Cancel')
    ),
  ];
}