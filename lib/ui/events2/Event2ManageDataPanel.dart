import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2ManageDataPanel extends StatefulWidget{
  final Event2? event;

  const Event2ManageDataPanel({super.key, this.event});

  @override
  State<StatefulWidget> createState() => _Event2ManageDataState();

  static bool get canManage => canUploadCsv;
  static bool get canUploadCsv => PlatformUtils.isWeb;
  bool get _canUploadCsv => canUploadCsv;
}

class _Event2ManageDataState extends State<Event2ManageDataPanel>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.manage.data.header.title', 'Manage Event Data')),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                  title: 'DOWNLOAD REGISTRANTS.csv',
                  onTap: _onDownloadRegistrants)
              ),
              SizedBox(height: 16.0,),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                    title: 'UPLOAD REGISTRANTS.csv',
                    onTap: _onUploadRegistrants),
              ),
              SizedBox(height: 16.0,),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                      title: 'DOWNLOAD ATTENDANCE.csv',
                      onTap: _onDownloadAttendance),
              ),
              SizedBox(height: 16.0,),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                    title: 'UPLOAD ATTENDANCE.csv',
                    onTap: _onUploadAttendance),
              ),
              SizedBox(height: 16.0,),
              Visibility(visible: widget._canUploadCsv,
                child: Event2SettingsButton(
                    title: 'DOWNLOAD SURVEY RESULTS',
                    onTap: _onDownloadSurveyResults),
              ),
              SizedBox(height: 16.0,),
              _buildDownloadResultsDescription(),
          ]),
        )
    );

  Widget _buildDownloadResultsDescription() {
    TextStyle? mainStyle = Styles().textStyles.getTextStyle('widget.item.small.light.thin.italic');
    final Color defaultStyleColor = Colors.red;
    final String? eventAttendanceUrl = Config().eventAttendanceUrl;
    final String? displayAttendanceUrl = (eventAttendanceUrl != null) ? (UrlUtils.stripUrlScheme(eventAttendanceUrl) ?? eventAttendanceUrl) : null;
    final String eventAttendanceUrlMacro = '{{event_attendance_url}}';
    String contentHtml = Localization().getStringEx('panel.event2.detail.survey.download.results.description',
      "Download survey results at {{event_attendance_url}}.");
    contentHtml = contentHtml.replaceAll(eventAttendanceUrlMacro, displayAttendanceUrl ?? '');
    return Visibility(visible: PlatformUtils.isMobile && StringUtils.isNotEmpty(displayAttendanceUrl), child:
      Padding(padding: EdgeInsets.zero, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Styles().images.getImage('info') ?? Container(),
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 6), child:
              HtmlWidget(contentHtml, onTapUrl: _onTapHtmlLink, textStyle: mainStyle,
                customStylesBuilder: (element) => (element.localName == "a") ? { "color": ColorUtils.toHex(mainStyle?.color ?? defaultStyleColor), "text-decoration-color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
              )
            ),
          ),
        ])
      ),
    );
  }

  bool _onTapHtmlLink(String? url) {
    Analytics().logSelect(target: '($url)');
    UrlUtils.launchExternal(url, mode: LaunchMode.externalApplication);
    return true;
  }

  void _onDownloadRegistrants() {
    Analytics().logSelect(target: "Download Registrants");
   AppToast.showMessage("TBD");
  }

  void _onUploadRegistrants() {
    Analytics().logSelect(target: "Upload Registrants");
   AppToast.showMessage("TBD");
  }

  void _onDownloadAttendance() {
    Analytics().logSelect(target: "Download Attendance");
    AppToast.showMessage("TBD");
  }

  void _onUploadAttendance() {
    Analytics().logSelect(target: "Upload Attendance");
    AppToast.showMessage("TBD");
  }

  void _onDownloadSurveyResults() {
    Analytics().logSelect(target: "Download Survey Results");
    AppToast.showMessage("TBD");
  }
}
