
import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/directory/DirectoryAccounts2List.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPanel.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/profile/ProfileInfoPage.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DirectoryAccounts2Panel extends StatefulWidget {
  DirectoryAccounts2Panel({super.key});

  @override
  State<StatefulWidget> createState() => _DirectoryAccounts2PanelState();
}

class _DirectoryAccounts2PanelState extends State<DirectoryAccounts2Panel> with NotificationsListener {

  String _searchText = '';
  Map<String, dynamic> _filterAttributes = <String, dynamic>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: RootHeaderBar(
        title: Localization().getStringEx('panel.profile.info_and_directory.tab.accounts.directory.title', 'Directory of Users'),
        leading: RootHeaderBarLeading.Back,
      ),
      body: _scaffoldContent,
      backgroundColor: Styles().colors.background,
      //bottomNavigationBar: uiuc.TabBar(),
    );

  Widget get _scaffoldContent => Auth2().isOidcLoggedIn ?
    DirectoryAccounts2List(
      listHeader: _listHeader,
      searchText: _searchText,
      filterAttributes: _filterAttributes,
    ) :
    DirectoryAccountsSignedOutDescription(
      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      onSignIn: _onSignIn,
    );

  Widget get _listHeader =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        DirectoryAccountsEditOrShareDescription(onEditProfile: _onEditProfile, onShareProfile: _onShareProfile,),
        DirectoryFilterBar(
          key: ValueKey(DirectoryFilter(searchText: _searchText, attributes: _filterAttributes)),
          searchText: _searchText,
          onSearchText: _onSearchText,
          // [#4474] filterAttributes: _filterAttributes,
          // [#4474] onFilterAttributes: _onFilterAttributes,
        ),
      ],),
    );

  void _onSearchText(String text) {
    setStateIfMounted((){
      _searchText = text;
    });
  }

  void _onEditProfile() {
    ProfileHomePanel.present(context,
      contentType: ProfileContentType.profile,
      contentParams: {
        ProfileInfoPage.editParamKey : true,
      }
    );
  }

  void _onShareProfile() {
    /*ProfileBusinessCardPanel.present(context,
      profile: Auth2().account?.previewProfile(permitted: contentType.profileInfo.permitedVisibility),
    );*/
    ProfileHomePanel.present(context,
      contentType: ProfileContentType.businessCard,
    );
  }

  void _onSignIn() {
    ProfileHomePanel.present(context,
      contentType: ProfileContentType.login,
    );
  }
}