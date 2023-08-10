import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Occupation.dart';
import 'package:illinois/service/Occupations.dart';
import 'package:illinois/ui/academics/SkillsSelfEvaluationOccupationDetails.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class SkillSelfEvaluationOccupationListPanel extends StatefulWidget {
  final Map<String, num> percentages;

  SkillSelfEvaluationOccupationListPanel({Key? key, required this.percentages}) : super(key: key);

  @override
  _SkillSelfEvaluationOccupationListState createState() => _SkillSelfEvaluationOccupationListState();
}

class _SkillSelfEvaluationOccupationListState extends State<SkillSelfEvaluationOccupationListPanel> {

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, num> _percentages = {};
  bool _sortMatchAsc = false;
  String? _searchTerm;
  List<OccupationMatch>? _occupationMatches = [];
  List<OccupationMatch> _occupationMatchesFiltered = [];

  @override
  void initState() {
    super.initState();
    _percentages = widget.percentages;
    _loadOccupationMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.occupation_list.header.title', 'Skills Self-Evaluation')),
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: Stack(
            children: [
              CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.gradientColorPrimary, horzDir: TriangleHorzDirection.leftToRight, vertDir: TriangleVertDirection.bottomToTop), child:
                Container(height: 64),
              ),
              Connectivity().isOffline ? _buildOfflineMessage() : _buildOccupationList(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 40, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Localization().getStringEx('panel.skills_self_evaluation.occupation_list.section.title', 'Career Explorer'),
            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.header'),
            textAlign: TextAlign.center,
          ),
          _buildOccupationsHeader(),
        ],
      ),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildOccupationsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 28, right: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Styles().colors?.surface, thickness: 2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                    flex: 5,
                    fit: FlexFit.tight,
                    child: Text(
                      Localization().getStringEx('panel.skills_self_evaluation.occupation_list.occupation.title', 'OCCUPATION'),
                      style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),
                    )),
                Flexible(
                    flex: 5,
                    fit: FlexFit.tight,
                    child: InkWell(
                      onTap: _onTapToggleSortMatchPercentage,
                      child: Row(
                        children: [
                          Text(
                            Localization().getStringEx('panel.skills_self_evaluation.occupation_list.match.title', 'MATCH PERCENTAGE'),
                            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),
                          ),
                          SizedBox(width: 8,),
                          (_sortMatchAsc ? Styles().images?.getImage('chevron-up', excludeFromSemantics: true)
                              : Styles().images?.getImage('chevron-down', excludeFromSemantics: true)) ?? Container(),
                        ],
                      ),
                    ))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineMessage() {
    return Padding(
      padding: EdgeInsets.all(28),
      child: Center(
          child: Text(
              Localization().getStringEx('panel.skills_self_evaluation.occupation_list.offline.error.msg', 'Career Explorer not available while offline.'),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'))),
    );
  }

  Widget _buildSearchBar() {
    return Semantics(
      textField: true,
      excludeSemantics: true,
      value: _searchController.text,
      child: TextField(
        controller: _searchController,
        // focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        autofocus: false,
        autocorrect: false,
        style: Styles().textStyles?.getTextStyle("widget.input_field.text.regular"),
        onChanged: (str) {
          setState(() {
            _searchTerm = str;
            _filterOccupationList();
          });
        },
        onSubmitted: (str) {
          setState(() {
            _searchTerm = str;
            _filterOccupationList();
          });
        },
        decoration: InputDecoration(
          suffixIcon: Row(mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: _searchController.text.isNotEmpty,
                child: IconButton(onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchTerm = null;
                    _filterOccupationList();
                  });
                }, icon: Styles().images?.getImage('close', excludeFromSemantics: true) ?? Container()),
              ),
              IconButton(onPressed: () => setState(() {
                _searchTerm = _searchController.text;
                _filterOccupationList();
              }),
              icon: Styles().images?.getImage('search', excludeFromSemantics: true) ?? Container()),
            ],
          ),
          labelStyle: Styles().textStyles?.getTextStyle("widget.input_field.text.regular"),
          labelText: Localization().getStringEx('panel.skills_self_evaluation.search.title', 'Search'),
          filled: true,
          fillColor: Styles().colors?.getColor('surface'),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors?.getColor('surface') ?? Colors.white, width: 2.0, style: BorderStyle.solid)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors?.getColor('fillColorSecondary') ?? Colors.black, width: 2.0))),
      ),);
  }

  Widget _buildOccupationList() {
    if (_occupationMatches == null) {// Displayed after loading error
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 32.0, right: 32.0),
          child: Text(
            Localization().getStringEx('panel.skills_self_evaluation.occupation_list.unavailable.message',
                'You do not have any matched occupations currently. Please take the survey first and wait for results to be processed.'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_occupationMatchesFiltered.isEmpty) {// Displayed when loading occupations
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
    // physics: const NeverScrollableScrollPhysics(),
      controller: _scrollController,
      // shrinkWrap: true,
      itemCount: _occupationMatchesFiltered.length,
      itemBuilder: (BuildContext context, int index) {
        return OccupationListTile(occupationMatch: _occupationMatchesFiltered[index], percentages: _percentages,);
      }
    );
  }

  void _filterOccupationList() {
    if (_searchTerm != null) {// use regex to filter based on search
      RegExp pattern = RegExp('$_searchTerm', caseSensitive: false);
      _occupationMatchesFiltered = _occupationMatches?.where((item) => pattern.hasMatch(item.occupation?.name ?? '')).toList() ?? [];
    } else {
      _occupationMatchesFiltered = _occupationMatches ?? [];
    }

    if (_sortMatchAsc) {// ascending
      _occupationMatchesFiltered.sort((a, b) => (a.matchPercent ?? 0).compareTo(b.matchPercent ?? 0));
    } else {// descending
      _occupationMatchesFiltered.sort((a, b) => (b.matchPercent ?? 0).compareTo(a.matchPercent ?? 0));
    }
  }

  void _onTapToggleSortMatchPercentage() {
    setState(() {
      _sortMatchAsc = !_sortMatchAsc;
      _filterOccupationList();
    });
  }

  void _loadOccupationMatches() async {
    _occupationMatches = await Occupations().getAllOccupationMatches();
    setState(() {
      _filterOccupationList();
    });
  }
}

class OccupationListTile extends StatelessWidget {
  const OccupationListTile({Key? key, required this.occupationMatch, required this.percentages}) : super(key: key);

  final OccupationMatch occupationMatch;
  final Map<String, num> percentages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
                context, CupertinoPageRoute(builder: (context) => SkillsSelfEvaluationOccupationDetails(percentages: percentages, occupationMatch: occupationMatch)));
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
            child: Row(
              children: [
                Flexible(
                  flex: 5,
                  fit: FlexFit.tight,
                  child: Text(
                    occupationMatch.occupation?.name.toString() ?? "",
                    style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
                  ),
                ),
                Spacer(),
                Flexible(
                    flex: 2,
                    fit: FlexFit.tight,
                    child: Text(occupationMatch.matchPercent?.toInt().toString() ?? '--', style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.current'), textAlign: TextAlign.center,)
                ),
                Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: SizedBox(
                        height: 16.0,
                        child: Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}