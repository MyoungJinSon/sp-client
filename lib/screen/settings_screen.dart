import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info/package_info.dart';
import 'package:sp_client/bloc/blocs.dart';
import 'package:sp_client/model/models.dart';
import 'package:sp_client/util/utils.dart';
import 'package:sp_client/widget/edit_text_dialog.dart';
import 'package:sp_client/widget/sub_header.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PreferenceBloc _preferenceBloc;

  @override
  void initState() {
    super.initState();
    _preferenceBloc = BlocProvider.of<PreferenceBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).actionSettings),
        elevation: 0.0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Util.isTablet(context) ? 56.0 : 0,
        ),
        child: BlocBuilder<PreferenceEvent, PreferenceState>(
          bloc: _preferenceBloc,
          builder: (context, state) {
            return ListView(
              children: _buildItems(state.preferences),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildItems(Preferences preferences) {
    return <Widget>[
      ..._buildNoteItems(preferences),
      ..._buildSecurityItems(preferences),
      if (!bool.fromEnvironment('dart.vm.product'))
        ..._buildDebugItems(preferences),
      ..._buildInfoItems(preferences),
    ];
  }

  List<Widget> _buildNoteItems(Preferences preferences) {
    return <Widget>[
      SubHeader(
        AppLocalizations.of(context).subtitleNote,
      ),
      _SwitchPreference(
        title: AppLocalizations.of(context).labelWriteNewNoteOnStartup,
        value: false,
        onChanged: (bool value) {},
      ),
      _SwitchPreference(
        title: AppLocalizations.of(context).labelQuickFolderClassification,
        subtitle:
            AppLocalizations.of(context).subtitleQuickFolderClassification,
        value: true,
        onChanged: (bool value) {},
      ),
    ];
  }

  List<Widget> _buildSecurityItems(Preferences preferences) {
    return <Widget>[
      SubHeader(
        AppLocalizations.of(context).subtitleSecurity,
      ),
      _Preference(
        title: AppLocalizations.of(context).labelChangePinCode,
        onTap: () {},
      ),
      _SwitchPreference(
        title: AppLocalizations.of(context).labelUseFingerprint,
        value: false,
        onChanged: (bool value) {},
      ),
    ];
  }

  List<Widget> _buildDebugItems(Preferences preferences) {
    return <Widget>[
      SubHeader(
        AppLocalizations.of(context).subtitleDebug,
      ),
      _EditTextPreference(
        title: AppLocalizations.of(context).labelServiceHost,
        preference: preferences.get(AppPreferences.keyServiceHost),
        validation: (value) => value.isNotEmpty,
        validationMessage: AppLocalizations.of(context).validationServiceHost,
      ),
    ];
  }

  List<Widget> _buildInfoItems(Preferences preferences) {
    return <Widget>[
      SubHeader(
        AppLocalizations.of(context).subtitleInfo,
      ),
      FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          var subtitle;
          if (snapshot.hasData) {
            subtitle =
                "ver ${snapshot.data.version} (build. ${snapshot.data.buildNumber})";
          }
          return _Preference(
            title: AppLocalizations.of(context).labelVersion,
            subtitle: subtitle,
          );
        },
      )
    ];
  }
}

class _Preference extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final Widget trailing;
  final VoidCallback onTap;
  final bool enabled;

  const _Preference({
    Key key,
    @required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    bool twoLine = subtitle != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: twoLine ? 64.0 : 48.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: <Widget>[
            if (leading != null) leading,
            if (leading != null) SizedBox(width: 32.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.subhead.copyWith(
                          fontSize: 16.0,
                        ),
                  ),
                  if (twoLine)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.caption.copyWith(
                            fontSize: 14.0,
                          ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

class _SwitchPreference extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchPreference({
    Key key,
    @required this.title,
    this.subtitle,
    this.leading,
    @required this.value,
    @required this.onChanged,
  }) : super(key: key);

  @override
  _SwitchPreferenceState createState() => _SwitchPreferenceState();
}

class _SwitchPreferenceState extends State<_SwitchPreference> {
  bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return _Preference(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      onTap: () {
        setState(() {
          _value = !_value;
        });
      },
      trailing: Switch(
        value: _value,
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _EditTextPreference extends StatelessWidget {
  final String title;
  final Preference preference;
  final ValidationCallback validation;
  final String validationMessage;
  final bool enabled;

  const _EditTextPreference({
    Key key,
    @required this.title,
    @required this.preference,
    this.validation,
    this.validationMessage,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<PreferenceBloc>(context);
    return _Preference(
      title: title,
      subtitle: preference.value,
      enabled: enabled,
      onTap: () async {
        var value = await showDialog(
          context: context,
          builder: (context) => EditTextDialog(
            title: title,
            value: preference.value,
            validation: validation,
            validationMessage: validationMessage,
          ),
        );
        if (value != null) {
          bloc.dispatch(UpdatePreference(preference..value = value));
        }
      },
    );
  }
}
