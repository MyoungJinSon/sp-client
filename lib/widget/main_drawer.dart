import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:sp_client/bloc/blocs.dart';
import 'package:sp_client/model/models.dart';
import 'package:sp_client/screen/folder_manage_screen.dart';
import 'package:sp_client/screen/settings_screen.dart';
import 'package:sp_client/util/utils.dart';
import 'package:sp_client/widget/loading_progress.dart';

import 'edit_text_dialog.dart';

class MainDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            SessionInfoHeader(),
            Expanded(
              child: ListView(
                children: <Widget>[
                  MainDrawerMenu(),
                  if (MediaQuery.of(context).platformBrightness ==
                      Brightness.light)
                    ThemeSwitchItem(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class MainDrawerMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var drawerBloc = BlocProvider.of<MainDrawerBloc>(context);
    return BlocBuilder<MainDrawerEvent, MainDrawerState>(
      bloc: drawerBloc,
      builder: (context, state) {
        return Column(
          children: <Widget>[
            _DrawerSelectableItem(
              icon: (state.selectedMenu == 0)
                  ? Icons.description
                  : OMIcons.description,
              title: AppLocalizations.of(context).actionNotes,
              selected: state.selectedMenu == 0,
              onTap: () {
                drawerBloc.dispatch(SelectMenu(0));
                Navigator.pop(context);
              },
            ),
            _FolderExpansionTile(
              initiallyExpanded: state.folderId != null,
              selectedFolder: state.folderId,
            ),
            _DrawerSelectableItem(
              icon: (state.selectedMenu == 2) ? Icons.lock : OMIcons.lock,
              title: AppLocalizations.of(context).actionSecretFolder,
              selected: false,
              onTap: () {},
            ),
            Divider(),
            _DrawerItem(
              icon: OMIcons.phonelink,
              title: Text(AppLocalizations.of(context).actionConnection),
              onTap: () {},
            ),
            _DrawerItem(
              icon: OMIcons.settings,
              title: Text(AppLocalizations.of(context).actionSettings),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class SessionInfoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      currentAccountPicture: CircleAvatar(
        child: Icon(Util.isTablet(context)
            ? Icons.tablet_android
            : Icons.phone_android),
      ),
      accountName: Text("Name"),
      accountEmail: FutureBuilder<String>(
        future: _getDeviceName(),
        builder: (context, snapshot) => Text(snapshot.data ?? "Unknown"),
      ),
    );
  }

  Future<String> _getDeviceName() async {
    if (Platform.isAndroid) {
      var info = await DeviceInfoPlugin().androidInfo;
      return info.model;
    } else if (Platform.isIOS) {
      var info = await DeviceInfoPlugin().iosInfo;
      return info.utsname.machine;
    } else {
      return null;
    }
  }
}

class ThemeSwitchItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferenceEvent, PreferenceState>(
      bloc: BlocProvider.of<PreferenceBloc>(context),
      builder: (BuildContext context, PreferenceState state) {
        var darkModePref = state.preferences.get(AppPreferences.keyDarkMode);
        var themeBloc = BlocProvider.of<ThemeBloc>(context);
        return ListTileTheme(
          style: ListTileStyle.drawer,
          contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
          child: SwitchListTile(
            title: Text(AppLocalizations.of(context).actionDarkMode),
            secondary: Icon(
              Icons.brightness_2,
              color: Theme.of(context).accentColor,
            ),
            value: darkModePref.value,
            onChanged: (bool value) {
              BlocProvider.of<PreferenceBloc>(context)
                  .dispatch(UpdatePreference(darkModePref..value = value));
              themeBloc.dispatch(
                value ? AppThemes.darkTheme : AppThemes.lightTheme,
              );
            },
          ),
        );
      },
    );
  }
}

class _DrawerSelectableItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final EdgeInsets padding;
  final EdgeInsets contentPadding;

  const _DrawerSelectableItem({
    @required this.icon,
    @required this.title,
    this.selected = false,
    this.onTap,
    this.padding,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding != null
          ? padding
          : const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color:
              selected ? Theme.of(context).accentColor.withOpacity(0.2) : null,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: selected ? Theme.of(context).accentColor : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: selected ? Theme.of(context).accentColor : null,
            ),
          ),
          contentPadding: contentPadding != null
              ? contentPadding
              : EdgeInsets.symmetric(horizontal: 16.0),
          onTap: onTap,
          selected: selected,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Widget title;
  final VoidCallback onTap;

  const _DrawerItem({
    @required this.icon,
    @required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24.0),
      leading: Icon(
        icon,
        color: Theme.of(context).accentColor,
      ),
      title: title,
      onTap: onTap,
    );
  }
}

class _FolderExpansionTile extends StatefulWidget {
  final bool initiallyExpanded;
  final String selectedFolder;

  _FolderExpansionTile({
    Key key,
    this.initiallyExpanded = false,
    this.selectedFolder,
  }) : super(key: key);

  @override
  _FolderExpansionTileState createState() => _FolderExpansionTileState();
}

class _FolderExpansionTileState extends State<_FolderExpansionTile> {
  FolderBloc _folderBloc;
  MemoBloc _memoBloc;

  @override
  void initState() {
    super.initState();
    _folderBloc = BlocProvider.of<FolderBloc>(context);
    _memoBloc = BlocProvider.of<MemoBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: BlocBuilder<FolderEvent, FolderState>(
        bloc: _folderBloc,
        builder: (context, folderState) {
          return BlocBuilder<MemoEvent, MemoState>(
            bloc: _memoBloc,
            builder: (context, snapshot) {
              return ExpansionTile(
                title: Text(AppLocalizations.of(context).actionFolder),
                leading: Icon(OMIcons.folder),
                initiallyExpanded: widget.initiallyExpanded,
                children: <Widget>[
                  if (folderState is FolderLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LoadingProgress(),
                    ),
                  if (folderState is FolderLoaded)
                    ..._buildFolderItems(
                      folderState.folders,
                      widget.selectedFolder,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildFolderItems(
    List<Folder> folders,
    String selectedFolderId,
  ) {
    return <Widget>[
      _buildFolderItem(
        Folder(
          id: kDefaultFolderId,
          name: AppLocalizations.of(context).folderDefault,
        ),
        selectedFolderId,
      ),
      ...folders
          .map((folder) => _buildFolderItem(folder, selectedFolderId))
          .toList(),
      ListTile(
        leading: Icon(OMIcons.createNewFolder),
        title: Text(AppLocalizations.of(context).actionCreateNewFolder),
        onTap: _createNewFolder,
      ),
      if (folders.isNotEmpty)
        ListTile(
          leading: Icon(OMIcons.settings),
          title: Text(AppLocalizations.of(context).actionManageFolder),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderManageScreen(),
              ),
            );
          },
        ),
    ];
  }

  Widget _buildFolderItem(Folder folder, String selectedFolderId) {
    var selected = folder.id == selectedFolderId;
    return _DrawerSelectableItem(
      selected: selected,
      icon: selected ? Icons.folder : OMIcons.folder,
      title: folder.name,
      padding: EdgeInsets.only(bottom: 4.0),
      onTap: () {
        BlocProvider.of<MainDrawerBloc>(context).dispatch(
          SelectMenu(1, folderId: folder.id),
        );
        BlocProvider.of<ListBloc>(context).dispatch(UnSelectable());
        Navigator.pop(context);
      },
    );
  }

  void _createNewFolder() async {
    var folderName = await showDialog(
      context: context,
      builder: (context) => EditTextDialog(
        title: AppLocalizations.of(context).actionAddFolder,
        positiveText: AppLocalizations.of(context).actionAdd,
        validation: (value) => value.isNotEmpty,
        validationMessage: AppLocalizations.of(context).errorEmptyName,
      ),
    );
    if (folderName != null) {
      _folderBloc.createFolder(Folder(name: folderName));
    }
  }
}
