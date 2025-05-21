import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:illinois/ui/widgets/WebNetworkImage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/places.dart' as places_model;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_header_image.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ExploreStoriedSightsBottomSheet extends StatefulWidget {
  final List<places_model.Place> places;
  final Function(places_model.Place) onPlaceSelected;
  final void Function(List<places_model.Place>? filteredPlaces)? onFilteredPlacesChanged;
  final VoidCallback? onBackPressed;

  ExploreStoriedSightsBottomSheet({Key? key, required this.places, required this.onPlaceSelected, this.onFilteredPlacesChanged, this.onBackPressed}) : super(key: key);

  @override
  ExploreStoriedSightsBottomSheetState createState() => ExploreStoriedSightsBottomSheetState();
}


class ExploreStoriedSightsBottomSheetState extends State<ExploreStoriedSightsBottomSheet> {
  List<places_model.Place> _storiedSights = [];
  final DraggableScrollableController _controller = DraggableScrollableController();
  Set<String> _selectedFilters = {};
  places_model.Place? _selectedDestination;
  List<places_model.Place> _allPlaces = [];
  ScrollController? _scrollController;
  final FocusNode _searchFocusNode = FocusNode();

  Map<String, Set<String>> _mainFilters = {};
  Set<String> _regularFilters = {};
  Set<String> _expandedMainTags = {};
  List<places_model.Place>? _customPlaces;
  TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  static final String _customSelectionFilterKey = 'CustomSelection';


  @override
  void initState() {
    super.initState();
    _allPlaces = widget.places;
    _collectAvailableTags();
    _storiedSights = List.from(_allPlaces);

    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _controller.animateTo(
          0.95,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _applyFilters();
  }

  void _collectAvailableTags() {
    _mainFilters.clear();
    _regularFilters.clear();
    for (places_model.Place place in _allPlaces) {
      if (place.tags != null) {
        for (String tag in place.tags!) {
          if (tag.contains('.')) {
            // Process hierarchical tags
            List<String> parts = tag.split('.');
            String mainTag = parts[0];
            String? subTag = parts.length > 1 ? parts.sublist(1).join('.') : null;

            _mainFilters.putIfAbsent(mainTag, () => <String>{});
            if (subTag != null) {
              _mainFilters[mainTag]!.add(subTag);
            }
          } else {
            // Regular tag
            _regularFilters.add(tag);
          }
        }
      }
    }
    // Add the "Visited" tag to the regular filters
    _regularFilters.add('Visited');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.25,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: [0.25, 0.65, 0.95],
          controller: _controller,
          builder: (BuildContext context, ScrollController scrollController) {
            _scrollController = scrollController;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // **Fixed Drag Handle**
                  _buildDragHandle(),

                  // **Scrollable Content**
                  Expanded(
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_selectedDestination == null)
                          SliverAppBar(
                            pinned: true,
                            surfaceTintColor: Colors.transparent,
                            backgroundColor: Colors.white,
                            automaticallyImplyLeading: false,
                            title: _buildTitle(),
                            bottom: PreferredSize(
                              preferredSize: Size.fromHeight(_calculateFilterButtonsHeight()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: _buildFilterButtons(),
                                  ),
                                  SizedBox(height: 8),
                                  Divider(color: Styles().colors.surfaceAccent, thickness: 2),
                                ],
                              ),
                            ),
                          ),

                        SliverList(
                          delegate: SliverChildListDelegate(_buildSheetListContent()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildSheetListContent() => _selectedDestination == null ?
    _buildPlaceListView() :
    [ExploreStoriedSightWidget(place: _selectedDestination!, onTapBack: () => setState(() {
        _selectedDestination = null;
        _controller.animateTo(
          0.65,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        widget.onBackPressed?.call();
    }))];

  double _calculateFilterButtonsHeight() {
    double height = 60.0; // Base height
    if (_expandedMainTags.isNotEmpty) {
      height += 60.0; // Additional height for subfilters
    }
    if (_isSearchExpanded) {
      height += 70.0; // Additional height for the search field
    }
    return height;
  }

  List<Widget> _buildPlaceListView() {
    return [
      ..._storiedSights.map((place) => _buildDestinationCard(place)).toList(),
    ];
  }






  Widget _buildTypeChips(List<String> types) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: types.map((type) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Styles().colors.fillColorPrimary,
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: Text(
            type,
            style: Styles().textStyles.getTextStyle("widget.button.title.small")?.copyWith(color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDestinationCard(places_model.Place place) {

    List<String> typesToShow = List<String>.from(place.types ?? []);
    if (place.userData?.visited != null && place.userData!.visited!.isNotEmpty) {
      typesToShow.add('Visited');
    }

    return InkWell(
      onTap: () => _onTapDestinationCard(place),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (typesToShow.isNotEmpty)
              _buildTypeChips(typesToShow),
            SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDestinationDetailsCard(place)),
                SizedBox(width: 16),
                _buildDestinationThumbnail(place),
              ],
            ),
            SizedBox(height: 8),
            Divider(color: Styles().colors.surfaceAccent, thickness: 2),
          ],
        ),
      ),
    );
  }

  void _onTapDestinationCard(places_model.Place place) {
    Analytics().logSelect(target: 'Place Card: ${place.name}');
    _selectPlace(place);
  }

  Widget _buildAddressRow(places_model.Place? place) =>
    (place?.address == null || place!.address!.trim().isEmpty) ?
      SizedBox.shrink() :
      InkWell(
        onTap: () => _onTapAddress(place),
        child: Padding(padding: EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Styles().images.getImage('location', size: 15.0) ?? const SizedBox(),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.address!,
                      style: Styles().textStyles.getTextStyle("widget.card.detail.small.regular")?.apply(
                        decoration: TextDecoration.underline,
                        decorationColor: Styles().colors.fillColorSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _onTapAddress(places_model.Place place) {
    Analytics().logSelect(target: "Directions: ${place.name}");
    place.launchDirections();
  }

  Widget _buildDestinationDetailsCard(places_model.Place place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
            children: [
              TextSpan(
                text: place.name ?? Localization().getStringEx('panel.explore.storied_sites.default.name', 'Unknown Name'),
              ),
              WidgetSpan(
                child: SizedBox(width: 0),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Styles().images.getImage('chevron-right-bold', size: 24.0) ?? const SizedBox(),
              ),
            ],
          ),
        ),
        _buildAddressRow(place),
      ],
    );
  }

  Widget _buildDestinationThumbnail(places_model.Place place) {
    return Container(
      width: 75,
      height: 75,
      child: place.images?.isNotEmpty ?? false
          ? WebNetworkImage(imageUrl: place.images!.first.imageUrl,
        fit: BoxFit.cover,
      )
          : Styles().images.getImage('missing-building-photo', fit: BoxFit.cover) ??
          SizedBox(width: 75, height: 75),
    );
  }

  Widget _buildFilterButtons() {
    List<Widget> filterButtons = [];

    filterButtons.add(_buildSearchButton());
    // Add Custom Selection Filter Button
    if (_customPlaces != null) {
      String label = '${_customPlaces!.length} Places';
      bool isSelected = _selectedFilters.contains(_customSelectionFilterKey);
      filterButtons.add(_buildCustomFilterButton(label, isSelected));
    }

    filterButtons.addAll(_regularFilters.map((tag) => _buildRegularFilterButton(tag)));

    for (String mainTag in _mainFilters.keys) {
      bool isExpanded = _expandedMainTags.contains(mainTag);
      Widget mainTagButton = _buildMainFilterButton(mainTag, isExpanded);
      filterButtons.add(mainTagButton);
    }

    List<Widget> filterWidgets = [];

    filterWidgets.add(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filterButtons,
        ),
      ),
    );

    // Subfilter buttons
    for (String mainTag in _mainFilters.keys) {
      if (_expandedMainTags.contains(mainTag)) {
        List<Widget> subFilterButtons = _mainFilters[mainTag]!.map((subTag) {
          String fullTag = '$mainTag.$subTag';
          return _buildSubFilterButton(fullTag, subTag);
        }).toList();

        Widget subFilterRow = Container(
          margin: EdgeInsets.only(top: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subFilterButtons,
            ),
          ),
        );

        filterWidgets.add(subFilterRow);
      }
    }

    if (_isSearchExpanded) {
      filterWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search places',
              prefixIcon: Styles().images.getImage("search") ?? const SizedBox(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _applyFilters();
                  });
                },
                child: Styles().images.getImage("close") ?? const SizedBox(),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: BorderSide(
                  color: Styles().colors.fillColorSecondary,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: BorderSide(
                  color: Styles().colors.fillColorPrimary,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: BorderSide(
                  color: Styles().colors.fillColorPrimary,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.0),
            ),
            onChanged: (text) {
              setState(() {
                _applyFilters();
              });
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filterWidgets,
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isSearchExpanded = !_isSearchExpanded;
            if (!_isSearchExpanded) {
              // Clear the search text when collapsing the search field
              _searchController.clear();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Styles().colors.fillColorPrimary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: Styles().colors.surfaceAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Styles().images.getImage('search', color: Styles().colors.fillColorPrimary, excludeFromSemantics: true, size: 16.0) ??
                Icon(Icons.search, color: Styles().colors.fillColorPrimary),
            SizedBox(width: 4),
            Text(
              'Search',
              style: Styles().textStyles.getTextStyle("widget.button.title.small")?.apply(
                color: Styles().colors.fillColorPrimary,
              ),
            ),
            SizedBox(width: 4,),
            (_isSearchExpanded
                ? Styles().images.getImage("chevron-down-dark-blue")
                : Styles().images.getImage("chevron-up-dark-blue")) ?? const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomFilterButton(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              // Deselect custom filter
              _selectedFilters.remove(_customSelectionFilterKey);
              _customPlaces = null;
            } else {
              // Select custom filter
              _selectedFilters.clear();
              _selectedFilters.add(_customSelectionFilterKey);
            }
            _applyFilters();
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          backgroundColor: isSelected ? Styles().colors.fillColorPrimary : Colors.white,
          side: BorderSide(
            color: isSelected ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        child: Text(
          label,
          style: Styles()
              .textStyles
              .getTextStyle("widget.button.title.small")
              ?.apply(color: isSelected ? Colors.white : Styles().colors.fillColorPrimary),
        ),
      ),
    );
  }


  Widget _buildMainFilterButton(String mainTag, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (isExpanded) {
              _expandedMainTags.remove(mainTag);
            } else {
              _expandedMainTags.add(mainTag);
            }
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Styles().colors.fillColorPrimary,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: Styles().colors.surfaceAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mainTag,
              style: Styles().textStyles.getTextStyle("widget.button.title.small")?.apply(
                color: Styles().colors.fillColorPrimary,
              ),
            ),
            SizedBox(width: 4,),
            (isExpanded ? Styles().images.getImage("chevron-down-dark-blue") : Styles().images.getImage("chevron-up-dark-blue")) ?? const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubFilterButton(String fullTag, String subTag) {
    bool isSelected = _selectedFilters.contains(fullTag);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              _selectedFilters.remove(fullTag);
            } else {
              _selectedFilters.add(fullTag);
            }
            _applyFilters();
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          backgroundColor: isSelected ? Styles().colors.fillColorPrimary : Colors.white,
          side: BorderSide(
            color: isSelected ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        child: Text(
          subTag,
          style: Styles().textStyles.getTextStyle("widget.button.title.small")?.apply(
            color: isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRegularFilterButton(String tag) {
    bool isSelected = _selectedFilters.contains(tag);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              _selectedFilters.remove(tag);
            } else {
              _selectedFilters.add(tag);
            }
            _applyFilters();
          });
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          backgroundColor: isSelected ? Styles().colors.fillColorPrimary : Colors.white,
          side: BorderSide(
            color: isSelected ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
        child: Text(
          tag,
          style: Styles().textStyles.getTextStyle("widget.button.title.small")?.apply(
            color: isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    List<places_model.Place> filteredPlaces = List.from(_allPlaces);

    // Apply search text filter first
    String searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      filteredPlaces = filteredPlaces.where((place) {
        return place.name?.toLowerCase().contains(searchText) ?? false;
      }).toList();
    }

    // Apply custom places filter if selected
    if (_selectedFilters.contains(_customSelectionFilterKey)) {
      filteredPlaces = filteredPlaces.where((place) => _customPlaces!.contains(place)).toList();
    }

    // Prepare other filters excluding 'Visited' and custom selection
    Set<String> filtersToApply = Set.from(_selectedFilters);
    filtersToApply.remove(_customSelectionFilterKey);
    bool isVisitedFilterSelected = filtersToApply.contains('Visited');
    if (isVisitedFilterSelected) {
      // Filter to only visited places
      filteredPlaces = filteredPlaces.where((place) => place.userData?.visited != null && place.userData!.visited!.isNotEmpty).toList();
      // Remove 'Visited' from filters to apply remaining filters
      filtersToApply.remove('Visited');
    }

    // Apply remaining filters
    if (filtersToApply.isNotEmpty) {
      filteredPlaces = filteredPlaces.where((place) {
        if (place.tags == null || place.tags!.isEmpty) return false;
        return place.tags!.any((tag) => filtersToApply.contains(tag));
      }).toList();
    }

    setState(() {
      _storiedSights = filteredPlaces;
    });

    widget.onFilteredPlacesChanged?.call((_storiedSights.length < _allPlaces.length) ? _storiedSights : null);
  }

  Widget _buildDragHandle() {
    return Container(
      width: 88.0,
      height: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Styles().colors.mediumGray2,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          Localization().getStringEx('panel.explore.storied_sites.title', 'Storied Sites'),
          style: Styles().textStyles.getTextStyle("widget.title.medium_large.fat"),
        ),
      ],
    );
  }

  void selectPlace(places_model.Place place) {
    _selectPlace(place, places: _allPlaces, filters: {});
  }

  void _selectPlace(places_model.Place place, { List<places_model.Place>? places, Set<String>? filters }) {
    setState(() {
      _selectedDestination = place;
      if (places != null) {
        _storiedSights = List.from(places);
      }
      if (filters != null) {
        _selectedFilters = Set.from(filters);
      }
    });
    _controller.animateTo(
      0.65,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null) {
        _scrollController!.jumpTo(0.0);
      }
    });

    widget.onPlaceSelected(place);
  }

  void selectPlaces(List<places_model.Place> places) {
    setState(() {
      _storiedSights = places;
      _customPlaces = places;
      _selectedDestination = null;
      _selectedFilters.clear();
      _selectedFilters.add(_customSelectionFilterKey);
    });
    _controller.animateTo(
      0.65,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void resetSelection() {
    setState(() {
      _storiedSights = _allPlaces;
      _selectedDestination = null;
      _selectedFilters.clear();
    });
  }
}

class ExploreStoriedSightWidget extends StatefulWidget {
  final places_model.Place place;
  final void Function()? onTapBack;
  final bool showDetailImage;

  ExploreStoriedSightWidget({super.key, required this.place, this.onTapBack, this.showDetailImage = true});

  @override
  State<StatefulWidget> createState() => _ExploreStoriedSightWidgetState();
}

class _ExploreStoriedSightWidgetState extends State<ExploreStoriedSightWidget> {

  List<DateTime> _placeCheckInDates = [];
  bool? _isHistoryExpanded;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) =>
    Column(mainAxisAlignment: MainAxisAlignment.start, children: _buildSelectedDestinationView(),);

  List<Widget> _buildSelectedDestinationView() {
    return [
      _buildSelectedDestinationHeader(),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: MarkdownBody(
          data: widget.place.description ?? Localization().getStringEx('panel.explore.storied_sites.default.description', 'No description available'),
          onTapLink: (text, href, title) {
            AppLaunchUrl.launch(url: href, context: context);
          },
          styleSheet: MarkdownStyleSheet(
            p: Styles().textStyles.getTextStyle("widget.description.regular"),
            h1: Styles().textStyles.getTextStyle("widget.title.huge.extra_fat"),
            h2: Styles().textStyles.getTextStyle("widget.title.large.extra_fat"),
            h3: Styles().textStyles.getTextStyle("widget.label.small.fat"),
            h4: Styles().textStyles.getTextStyle("widget.message.light.variant.small"),
            a: TextStyle(decoration: TextDecoration.underline, color: Styles().colors.fillColorSecondary),
            listBulletPadding: const EdgeInsets.only(right: 4.0, bottom: 16.0),
            strong: const TextStyle(fontWeight: FontWeight.bold),
            em: const TextStyle(fontStyle: FontStyle.italic),
          )
        ),
      ),
    ];
  }

  Widget _buildSelectedDestinationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onTapBack != null)
          InkWell(
            onTap: widget.onTapBack,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12, left: 8, right: 8),
              child: Styles().images.getImage('chevron-left-bold', size: 24.0) ?? const SizedBox(),
            ),
          ),
        if (widget.place.types != null && widget.place.types!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTypeChips(widget.place.types!),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSelectedDestinationContent(),
        ),
      ],
    );
  }

  Widget _buildTypeChips(List<String> types) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: types.map((type) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Styles().colors.fillColorPrimary,
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: Text(
            type,
            style: Styles().textStyles.getTextStyle("widget.button.title.small")?.copyWith(color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedDestinationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDestinationHeader(),
        SizedBox(height: 16),
        _buildCheckInHistory(),
        SizedBox(height: 16),
        Divider(color: Styles().colors.mediumGray2, thickness: 2),
        SizedBox(height: 16),
        if (widget.place.images?.isNotEmpty ?? false)
          _buildImageGallery(),
      ],
    );
  }

  Widget _buildDestinationHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _buildDestinationDetails()),
      if (widget.showDetailImage)
        _buildDestinationImage(),
    ],);
  }

  Widget _buildDestinationDetails() {
    return Padding(padding: EdgeInsets.only(left: 8), child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.place.name ?? '', style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),),
          _buildAddressRow(),
          _buildShareLocationRow(),
          SizedBox(height: 8),
          _buildCheckInButton(),
        ],
      ),
    );
  }

  Widget _buildAddressRow() =>
    (widget.place.address?.trim().isNotEmpty != true) ?
      SizedBox.shrink() :
      InkWell(
        onTap: _onTapAddress,
        child: Padding(padding: EdgeInsets.only(top: 8, bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.0),
                    child: Styles().images.getImage('location', size: 15.0) ?? const SizedBox(),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.place.address ?? '',
                      style: Styles().textStyles.getTextStyle("widget.card.detail.small.regular.underline"),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _onTapAddress() {
    Analytics().logSelect(target: "Directions: ${widget.place.name}");
    widget.place.launchDirections();
  }

  Widget _buildShareLocationRow() =>
    InkWell(
      onTap: _onTapShareLocation,
      child: Padding(padding: EdgeInsets.only(top: 2, bottom: 8),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Styles().images.getImage('share-nodes', excludeFromSemantics: true) ?? const SizedBox(),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  Localization().getStringEx('panel.explore.storied_sites.share.location', 'Share this location'), //Localization().getStringEx("panel.explore.storied_sites.") manavmodi
                  style: Styles().textStyles.getTextStyle('widget.card.detail.small.regular.underline'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _onTapShareLocation() {
    Analytics().logSelect(target: "Share Location");
    Navigator.push(context, CupertinoPageRoute(builder: (context) =>
      QrCodePanel.fromPlace(widget.place)
    ));
  }

  Widget _buildDestinationImage() {
    return Container(
      width: 75,
      height: 75,
      child: widget.place.images?.isNotEmpty ?? false
          ? WebNetworkImage(imageUrl: widget.place.images!.first.imageUrl,
        fit: BoxFit.cover,
      ) : Styles().images.getImage('missing-building-photo', fit: BoxFit.cover) ??
          SizedBox(width: 75, height: 75),
    );
  }

  Widget _buildImageGallery() {
    if ((widget.place.images?.length ?? 0) == 1) {
      return ModalImageHolder(
        child: SizedBox(
          height: 200,
          child: TriangleHeaderImage(
            flexBackColor: Styles().colors.background,
            flexImageUrl: widget.place.images!.first.imageUrl,
            flexLeftToRightTriangleColor: Styles().colors.fillColorSecondaryTransparent05,
            flexLeftToRightTriangleHeight: 53,
            flexRightToLeftTriangleColor: Styles().colors.background,
            flexRightToLeftTriangleHeight: 30,
          ),
        ),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.place.images?.length ?? 0,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 12.0),
            child: ModalImageHolder(
              child: WebNetworkImage(imageUrl: widget.place.images![index].imageUrl,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckInButton() {
    List<DateTime>? visitedDates = widget.place.userData?.visited?.whereType<DateTime>().toList();
    bool isCheckedInToday = false;

    if (visitedDates != null && visitedDates.isNotEmpty) {
      visitedDates.sort((a, b) => b.compareTo(a));
      DateTime lastCheckInDate = visitedDates.first;

      DateTime now = DateTime.now();
      isCheckedInToday = lastCheckInDate.year == now.year &&
          lastCheckInDate.month == now.month &&
          lastCheckInDate.day == now.day;
    }

    return Row(
      children: [
        SmallRoundedButton(
          label: isCheckedInToday ? Localization().getStringEx('panel.explore.storied_sites.checked.in', 'Checked in') : Localization().getStringEx('panel.explore.storied_sites.check.in', 'Check In'),
          textStyle: isCheckedInToday ?  Styles().textStyles.getTextStyle("widget.button.title.disabled") : Styles().textStyles.getTextStyle("widget.button.title.enabled"),
          borderColor: isCheckedInToday ? Styles().colors.surfaceAccent : Styles().colors.fillColorSecondary,
          rightIcon: const SizedBox(),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 48),
          onTap: isCheckedInToday ? _handleCheckedIn : _handleCheckIn,
        ),
        InkWell(
          onTap: _onTapInfo,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Styles().images.getImage('info', size: 16.0) ?? const SizedBox(),
          ),
        ),
      ],
    );
  }

  void _onTapInfo() {
    Analytics().logSelect(target: 'Info');
    showDialog(context: context, builder: (BuildContext context) =>
      _buildInfoDialog(context)
    );
  }

  void _handleCheckIn() async {
    String placeId = widget.place.id;
    DateTime now = DateTime.now();

    setState(() {
      if (widget.place.userData == null) {
        widget.place.userData = places_model.UserPlace(
          id: placeId,
          visited: [now],
        );
      } else {
        widget.place.userData!.visited ??= [];
        widget.place.userData!.visited!.add(now);
      }


      _placeCheckInDates.add(now);
      _placeCheckInDates.sort((a, b) => b.compareTo(a));
    });

    Places placesService = Places();
    try {
      places_model.UserPlace? updatedPlace = await placesService.updatePlaceVisited(placeId, true);
      if (mounted && (updatedPlace == null)) {

        setState(() {
          widget.place.userData!.visited!.remove(now);
          _placeCheckInDates.remove(now);
        });

        AppToast.showMessage(Localization().getStringEx('panel.explore.storied_sites.check_in.try_again', 'Check-in failed. Please sign in and try again.'));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          widget.place.userData!.visited!.remove(now);
          _placeCheckInDates.remove(now);
        });

        AppToast.showMessage(Localization().getStringEx('panel.explore.storied_sites.check_in.failed', 'Check-in failed due to an error.'));
      }
    }
  }

  void _handleCheckedIn() async {
    AppToast.showMessage(Localization().getStringEx('panel.explore.storied_sites.one.day', 'You can only check in once per day.'));
  }

  Widget _buildInfoDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(16.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _onTapInfoClose,
            child: Align(
              alignment: Alignment.topRight,
              child: Styles().images.getImage("close-circle", size: 28.0) ?? const SizedBox(),
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 16),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Your check-in history is not shared with other users.",
                style: Styles().textStyles.getTextStyle("widget.message.regular"),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTapInfoClose() {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop();
  }

  Widget _buildCheckInHistory() {

    List<DateTime>? visitedDates = widget.place.userData?.visited?.whereType<DateTime>().toList();
    if (visitedDates == null || visitedDates.isEmpty) return Container();

    visitedDates.sort((a, b) => b.compareTo(a));
    DateTime lastCheckInDate = visitedDates.first;
    String formattedLastDate = DateFormat('MMMM d, yyyy').format(lastCheckInDate);

    bool isExpanded = _isHistoryExpanded ?? false;

    String headerText = isExpanded
        ? Localization().getStringEx('panel.explore.storied_sites.check.in.title', 'You checked in on...')
        : Localization().getStringEx('panel.explore.storied_sites.last.check.in.title', 'You last checked in on $formattedLastDate');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _onTapExpandHistory,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Styles().images.getImage('location', excludeFromSemantics: true, size: 16.0) ?? const SizedBox(),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerText,
                  style: isExpanded ? Styles().textStyles.getTextStyle("widget.label.small.fat") : Styles().textStyles.getTextStyle("widget.button.title.small.fat"),
                ),
              ),
              (isExpanded ? Styles().images.getImage("chevron-down", size: 25) : Styles().images.getImage("chevron-up", size: 25)) ?? const SizedBox(),
            ],
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.only(left: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: visitedDates.map((date) {
                String formattedDate = DateFormat('MMMM d, yyyy').format(date);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: Styles().textStyles.getTextStyle("widget.card.detail.small.medium"),
                    ),
                    TextButton(
                      onPressed: () => _clearCheckInDate(date),
                      child: Text(
                        'Clear',
                        style: Styles().textStyles.getTextStyle("widget.title.small.semi_fat")?.apply(
                            decoration: TextDecoration.underline,
                            decorationColor: Styles().colors.fillColorSecondary),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _onTapExpandHistory() {
    Analytics().logSelect(target: (_isHistoryExpanded == true) ? 'Colapse History' : 'Expand History');
    setState(() {
      _isHistoryExpanded = (_isHistoryExpanded != true);
    });
  }

  void _clearCheckInDate(DateTime date) async {
    String placeId = widget.place.id;


    setState(() {
      _placeCheckInDates.remove(date);
      widget.place.userData?.visited?.remove(date);

      if (_placeCheckInDates.isEmpty) {
        _isHistoryExpanded = false;
      } else {
        _placeCheckInDates.sort((a, b) => b.compareTo(a));
      }
    });

    Places placesService = Places();
    try {
      bool success = await placesService.deleteVisitedPlace(placeId, date.toUtc());
      if (mounted && !success) {
        setState(() {
          _placeCheckInDates.add(date);
          widget.place.userData?.visited?.add(date);
          _placeCheckInDates.sort((a, b) => b.compareTo(a));
        });

        AppToast.showMessage(Localization().getStringEx('panel.explore.storied_sites.failed.clear', 'Failed to clear check-in date. Please try again.'));
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _placeCheckInDates.add(date);
          widget.place.userData?.visited?.add(date);
          _placeCheckInDates.sort((a, b) => b.compareTo(a));
        });

        AppToast.showMessage(Localization().getStringEx('panel.explore.storied_sites.clear.error', 'An error occurred while clearing the check-in date.'));
      }
    }
  }
}
