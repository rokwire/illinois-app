import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/debug/DebugStudentsGuideSectionsPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';

class DebugStudentsGuidePanel extends StatefulWidget {
  DebugStudentsGuidePanel();

  _DebugStudentsGuidePanelState createState() => _DebugStudentsGuidePanelState();
}

class _DebugStudentsGuidePanelState extends State<DebugStudentsGuidePanel> {

  TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: this._sampleJson);
  }

  @override
  void dispose() {
    super.dispose();
    _jsonController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text("Students Guide", style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: SafeArea(child:
        Column(children: <Widget>[
          Expanded(child: 
            Padding(padding: EdgeInsets.all(16), child:
              _buildContent()
            ,),
          ),
        ],),
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(bottom: 4),
        child: Text("JSON", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 12, color: Styles().colors.fillColorPrimary),),
      ),
      Expanded(child:
        Stack(children: <Widget>[
          TextField(
            maxLines: 256,
            controller: _jsonController,
            decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
            style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,),
          ),
          /*Align(alignment: Alignment.topRight,
            child: GestureDetector(onTap: () {  },
              child: Container(width: 36, height: 36,
                child: Align(alignment: Alignment.center,
                  child: Image.asset('images/icon-copy.png'),
                ),
              ),
            ),
          ),*/
        ]),
      ),
      _buildPreview(),
    ],);
  }

  Widget _buildPreview() {
    return Padding(padding: EdgeInsets.only(top: 16), child: 
      Row(children: <Widget>[
        Expanded(child: Container(),),
        RoundedButton(label: "Preview",
          textColor: Styles().colors.fillColorPrimary,
          borderColor: Styles().colors.fillColorSecondary,
          backgroundColor: Styles().colors.white,
          fontFamily: Styles().fontFamilies.bold,
          fontSize: 16,
          padding: EdgeInsets.symmetric(horizontal: 32, ),
          borderWidth: 2,
          height: 42,
          onTap:() { _onPreview();  }
        ),
        Expanded(child: Container(),),
      ],),
    );
  }

  void _onPreview() {
    List<dynamic> jsonList = AppJson.decodeList(_jsonController.text);
    List<Map<String, dynamic>> entries;
    try {entries = jsonList?.cast<Map<String, dynamic>>(); }
    catch(e) {}
    if (entries != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStudentsGuideSectionsPanel(entries: entries, category: "Involvement",)));
    }
    else {
      AppAlert.showDialogResult(context, "Failed to parse JSON");
    }
    
  }

  String get _sampleJson {
    return '''[
  {
    "id": "campus.recreation",
    "category": "Involvement",
    "section": "Socializing",
    
    "list_title": "Participate in campus recreation",
    "list_description": "Campus Recreation offers active learning and self-discovery opportunities to students, faculty, staff, and community members.",

    "detail_title": "Participate in campus recreation",
    "detail_description": "<b><span style='color: #008000'>Campus Recreation</span></b> offers active <u><span style='color: #008000'>learning</span></u> and self-discovery <i><span style='color: #008000'>opportunities</span></i> to students, faculty, staff, and community members. <a href='https://illinois.edu'>Campus Recreation</a> is a place for everyone!",

    "links":[
      { "text": "(217) 333-1900", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-phone.png", "url": "tel:+1-217-333-1900" },
      { "text": "campusrec@illinois.edu", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-mail.png", "url": "mailto:campusrec@illinois.edu" },
      { "text": "campusrec.illinois.edu", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-web.png", "url": "https://campusrec.illinois.edu/"}
    ],

    "buttons":[
      { "text": "Visit website", "url": "https://campusrec.illinois.edu/" },
      { "text": "Visit website2", "url": "https://campusrec.illinois.edu/" },
      { "text": "Visit website3", "url": "https://campusrec.illinois.edu/" }
    ],

    "sub_details_title": null,
    "sub_details_description": "<b><span style='color: #008000'>Campus Recreation</span></b> has a variety of <u><span style='color: #008000'>facilities</span></u> and <i><span style='color: #008000'>programs</span></i>. Visit the <a href='https://illinois.edu'>website</a> to view a complete list.",
    "sub_details": [
      {
        "section": "State of the <u>Art Facilities</u>",
        "entries": [
          {
            "heading": "Our <b><u>indoor</u></b> facilities include:",
            "bullets": [
              "Activities and Recreation Center (<b>ARC</b>)",
              "Campus Recreation Center East (<a href='https://illinois.edu'>CRCE</a>)",
              "Campus Bike Center",
              "Ice Arena"
          ]},
          {
            "heading": "Our <b><u>outdoor</u></b> facilities include:",
            "bullets": [
              "Activities and Recreation Center (ARC)",
              "Campus Recreation Center East (CRCE)",
              "Campus Bike Center",
              "Ice Arena"
          ]}
      ]},
      {
        "section": "Programs for </u>All</u>",
        "entries": [
          {
            "heading": "Campus Recreation also offers <span style='color: #008000'><b>unique programs</b></span> designed for patrons of diverse interests, including:",
            "bullets": [
              "A variety of group fitness and personal training offerings",
              "Dozens of intramural activities",
              "Instructional cooking demonstrations",
              "Wellness workshops",
              "Rock climbing clinics",
              "Swimming programs",
              "Bicycle demonstrations",
              "Ice skating classes",
              "A variety of club sports."
          ]}
      ]}
    ],
    "related": [ "fraternity", "students.club", "civic.engagement" ]
  },
  {
    "id": "intramural.sports",
    "category": "Involvement",
    "section": "Socializing",

    "list_title": "Join an intramural sports team",
    "list_description": "Intramurals are easy to join and easy to play. There are activities offered to fit everyone’s needs and abilities."
  },
  {
    "id": "students.club",
    "category": "Involvement",
    "section": "Socializing",

    "list_title": "Join a student club or organization",
    "list_description": "Illinois is home to many student clubs and organizations. Get involved today!"
  },
  {
    "id": "fraternity",
    "category": "Involvement",
    "section": "Socializing",

    "list_title": "Join a fraternity or sorority",
    "list_description": "Fraternities and sororities provide support, housing, mentorship and more to over 7,000 students on campus."
  },
  {
    "id": "civic.engagement",
    "category": "Involvement",
    "section": "Community engagement",

    "list_title": "Participate in civic engagement",
    "list_description": "Illinois offers many opportunities to become engaged citizens through student voter initiatives."
  },
  {
    "id": "union.board",
    "category": "Involvement",
    "section": "Community engagement",

    "list_title": "Join the Illini Union Board",
    "list_description": "Illinois offers many opportunities to become engaged citizens through student voter initiatives."
  },
  {
    "id": "volunteer",
    "category": "Involvement",
    "section": "Community engagement",

    "list_title": "Volunteer",
    "list_description": "The Office of Volunteer Programs provides students with opportunities to give back to their community."
  }
]''';
  }

}

Map<String, dynamic> studentGuideEntryById(String id, {List<Map<String, dynamic>> entries}) {
  if (entries != null) {
    for (dynamic entry in entries) {
      if ((entry is Map) && (AppJson.stringValue(entry['id']) == id)) {
        return entry;  
      }
    }
  }
  return null;
}