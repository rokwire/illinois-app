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
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugStudentsGuideSectionsPanel(entries: entries,)));
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
      { "text": "(217) 333-3806", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-phone.png", "url": "tel:+1-217-333-3806" },
      { "text": "campusrec@illinois.edu", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-mail.png", "url": "mailto:campusrec@illinois.edu" },
      { "text": "https://campusrec.illinois.edu", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-web.png", "url": "https://campusrec.illinois.edu/"}
    ],

    "buttons":[
      { "text": "Visit website", "url": "https://campusrec.illinois.edu/" },
      { "text": "Visit website2", "url": "https://campusrec.illinois.edu/" },
      { "text": "Visit website3", "url": "https://campusrec.illinois.edu/" }
    ],

    "image": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/image-placeholder-1.png",

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

    "title": "Join an intramural sports team",
    "description": "Intramurals are easy to join and easy to play. There are activities offered to fit everyone’s needs and abilities."
  },
  {
    "id": "students.club",
    "category": "Involvement",
    "section": "Socializing",

    "title": "Join a student club or organization",
    "description": "Illinois is home to many student clubs and organizations. Get involved today!"
  },
  {
    "id": "fraternity",
    "category": "Involvement",
    "section": "Socializing",

    "title": "Join a fraternity or sorority",
    "description": "Fraternities and sororities provide support, housing, mentorship and more to over 7,000 students on campus."
  },
  {
    "id": "civic.engagement",
    "category": "Involvement",
    "section": "Community engagement",

    "title": "Participate in civic engagement",
    "description": "Illinois offers many opportunities to become engaged citizens through student voter initiatives."
  },
  {
    "id": "union.board",
    "category": "Involvement",
    "section": "Community engagement",

    "title": "Join the Illini Union Board",
    "description": "Illinois offers many opportunities to become engaged citizens through student voter initiatives."
  },
  {
    "id": "volunteer",
    "category": "Involvement",
    "section": "Community engagement",

    "title": "Volunteer",
    "description": "The Office of Volunteer Programs provides students with opportunities to give back to their community."
  },
  {
    "id": "call.safewalk",
    "category": "Safety",
    "section": "Safety",

    "title": "Call for a SafeWalk",
    "description": "You don’t have to walk alone. By traveling together, we significantly reduce our chances of being targeted.",

    "links":[
      { "text": "(217) 333-31216", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-phone.png", "url": "tel:+1-217-333-31216" }
    ],

    "sub_details_description": "<p>SafeWalks is a courtesy service provided to University of Illinois students, faculty, and staff.</p><p>To request a SafeWalks escort, call <a href='tel:+1-217-333-1216'>(217) 333-1216</a>. You can also use an emergency phone to contact a dispatcher.</p><p>Please give at least 15 minutes notice.</p>",
    "sub_details": [
      {
        "section": "Hours of Operation",
        "entries": [
          { "heading": "9 pm to 2:30 am, Sunday through Wednesday (calls taken until 2:15 am)" },
          { "heading": "9 pm to 3 am, Thursday, Friday and Saturday (calls taken until 2:45 am)" }
        ]
      }
    ],

    "related": [ "call.saferide", "sexual.assault", "prepared.emergency" ]
  },
  {
    "id": "call.saferide",
    "category": "Safety",
    "section": "Safety",

    "title": "Call for a SafeRide",
    "description": "Limited SafeRides are offered at night for individuals traveling alone when there are no other safe means of transportation."
  },
  {
    "id": "sexual.assault",
    "category": "Safety",
    "section": "Safety",

    "title": "Find resources for sexual assault or abuse",
    "description": "The University of Illinois at Urbana-Champaign provides prevention and awareness education, resources and reporting options."
  },
  {
    "id": "prepared.emergency",
    "category": "Safety",
    "section": "Safety",

    "title": "Be prepared for an emergency",
    "description": "Take a moment to think about what you should do in a situation where your ability to react quickly may save your life."
  },
  {
    "id": "write.workshop",
    "category": "Academic support",
    "section": "Academic support",

    "title": "Take advantage of the Writer’s Workshop",
    "description": "The Writers Workshop supports all writers in the campus community across all forms of academic and professional writing, at any stage of the writing process.",

    "links":[
      { "text": "(217) 333-8796", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-phone.png", "url": "tel:+1-217-333-8796" },
      { "text": "251 Undergraduate Library\\n 1402 W Gregory Dr\\n Urbana, IL 61801", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-location.png", "location": { "location": { "latitude": 40.104736462133886, "longitude": -88.22751314035212}, "title": "251 Undergraduate Library" } },
      { "text": "wow@illinois.edu", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-mail.png", "url": "mailto:wow@illinois.edu" },
      { "text": "https://writersworkshop.illinois.edu/", "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-web.png", "url": "https://writersworkshop.illinois.edu/"}
    ],

    "buttons":[
      { "text": "Visit website", "url": "https://writersworkshop.illinois.edu/" }
    ],
  
    "image": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/image-placeholder-2.png",

    "sub_details_title": null,
    "sub_details_description": "<p>The Writer’s Workshop provides support for all types of writing. There are multiple options for students to receive feedback, such as in-person consultations by appointment, drop-in consultations, or written feedback appointments.</p><p>The Workshop also hosts presentations about common academic writing concerns like citing sources, avoiding plagiarism, and polishing final drafts.</p><p>Visit the website for more information and instruction on how to sign up.</p>",
    "related": [ "online.classses", "assistent.center", "union.bookstore" ]
  },
  {
    "id": "online.classses",
    "category": "Academic support",
    "section": "Academic support",

    "title": "Take online classes",
    "description": "Illinois Online offers online classes for students who need to be away from campus or want to get ahead for graduation."
  },
  {
    "id": "assistent.center",
    "category": "Academic support",
    "section": "Academic support",

    "title": "Get help from the Student Assistance Center",
    "description": "The Student Assistance Center promotes the holistic growth and development of Illinois students."
  },
  {
    "id": "union.bookstore",
    "category": "Academic support",
    "section": "Academic support",

    "title": "The Illini Union Bookstore",
    "description": "The premiere place for students to rent or purchase textbooks."
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