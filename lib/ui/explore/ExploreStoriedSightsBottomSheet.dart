import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:intl/intl.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/places.dart' as places_model;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_header_image.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreStoriedSightsBottomSheet extends StatefulWidget {
  final List<places_model.Place> places;
  final Function(places_model.Place) onPlaceSelected;

  ExploreStoriedSightsBottomSheet({Key? key, required this.places, required this.onPlaceSelected}) : super(key: key);

  @override
  ExploreStoriedSightsBottomSheetState createState() => ExploreStoriedSightsBottomSheetState();
}


class ExploreStoriedSightsBottomSheetState extends State<ExploreStoriedSightsBottomSheet> {
  List<places_model.Place> _storiedSights = [];
  final DraggableScrollableController _controller = DraggableScrollableController();
  final Set<String> _selectedFilters = {};
  places_model.Place? _selectedDestination;
  List<places_model.Place> _allPlaces = [];
  ScrollController? _scrollController;

  Map<String, List<DateTime>> _placeCheckInDates = {};
  Map<String, bool> _isHistoryExpanded = {};
  Map<String, DateTime?> _lastCheckInDate = {};
  Map<String, Set<String>> _mainFilters = {};
  Set<String> _regularFilters = {};
  Set<String> _expandedMainTags = {};
  bool _isLightboxVisible = false;
  places_model.Image? _selectedImage;



  @override
  void initState() {
    super.initState();
    _allPlaces = widget.places;
    _collectAvailableTags();
    _storiedSights = List.from(_allPlaces);
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
          snapSizes: [0.25, 0.5, 0.95],
          controller: _controller,
          builder: (BuildContext context, ScrollController scrollController) {
            List<Widget> slivers = [];
            _scrollController = scrollController;

            slivers.add(SliverToBoxAdapter(
              child: Center(child: _buildDragHandle()),
            ));

            if (_selectedDestination == null) {
              slivers.add(
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
              );
            }

            slivers.add(
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    List<Widget> contentWidgets = _selectedDestination == null
                        ? _buildPlaceListView()
                        : _buildSelectedDestinationView();
                    if (index < contentWidgets.length) {
                      return contentWidgets[index];
                    }
                    return null;
                  },
                  childCount: _selectedDestination == null
                      ? _buildPlaceListView().length
                      : _buildSelectedDestinationView().length,
                ),
              ),
            );

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
                  //Center(child: _buildDragHandle()),
                  Expanded(
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: AlwaysScrollableScrollPhysics(),
                      slivers: slivers,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_isLightboxVisible) _buildLightbox(),
      ]
    );
  }

  double _calculateFilterButtonsHeight() {
    return _expandedMainTags.isNotEmpty ? 120.0 : 60.0;
  }

  List<Widget> _buildPlaceListView() {
    return [
      ..._storiedSights.map((place) => _buildDestinationCard(place)).toList(),
    ];
  }

  Widget _buildLightbox() {
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isLightboxVisible = false;
              });
            },
            child: Container(
              color: Colors.black54,
            ),
          ),
          // Centered image and caption
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Image
                      GestureDetector(
                        onTap: () {
                          // Prevent closing when tapping on the image
                        },
                        child: Image.network(
                          _selectedImage!.imageUrl,
                          fit: BoxFit.contain,
                          // Limit the image width to 90% of the screen width
                          width: constraints.maxWidth * 0.9,
                        ),
                      ),
                      // Close icon positioned above the top-right corner
                      Positioned(
                        top: -28.0, // Adjusted for 4 pixels padding above
                        right: 0.0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isLightboxVisible = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  // Caption below the image with width matching the image
                  if (_selectedImage!.caption != null)
                    Container(
                      color: Colors.white,
                      width: constraints.maxWidth * 0.9, // Match image width
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        _selectedImage!.caption!,
                        style: Styles()
                            .textStyles
                            .getTextStyle("widget.description.regular"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }



  // Method to handle check-in action
  void _handleCheckIn() async {
    if (_selectedDestination != null) {
      String placeId = _selectedDestination!.id;
      DateTime now = DateTime.now();

      setState(() {
        if (_selectedDestination!.userData == null) {
          _selectedDestination!.userData = places_model.UserPlace(
            id: placeId,
            visited: [now],
          );
        } else {
          _selectedDestination!.userData!.visited ??= [];
          _selectedDestination!.userData!.visited!.add(now);
        }


        _placeCheckInDates[placeId] ??= [];
        _placeCheckInDates[placeId]!.add(now);
        _placeCheckInDates[placeId]!.sort((a, b) => b.compareTo(a));
        _lastCheckInDate[placeId] = _placeCheckInDates[placeId]!.first;
      });

      Places placesService = Places();
      try {
        places_model.UserPlace? updatedPlace = await placesService.updatePlaceVisited(placeId, true);
        if (mounted && (updatedPlace == null)) {

          setState(() {
            _selectedDestination!.userData!.visited!.remove(now);
            _placeCheckInDates[placeId]!.remove(now);
            if (_placeCheckInDates[placeId]!.isEmpty) {
              _lastCheckInDate[placeId] = null;
            } else {
              _lastCheckInDate[placeId] = _placeCheckInDates[placeId]!.first;
            }
          });

          AppToast.showMessage(Localization().getStringEx('', 'Check-in failed. Please try again.'));
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _selectedDestination!.userData!.visited!.remove(now);
            _placeCheckInDates[placeId]!.remove(now);
            if (_placeCheckInDates[placeId]!.isEmpty) {
              _lastCheckInDate[placeId] = null;
            } else {
              _lastCheckInDate[placeId] = _placeCheckInDates[placeId]!.first;
            }
          });

          AppToast.showMessage(Localization().getStringEx('', 'Check-in failed due to an error.'));
        }
      }
    }
  }

  void _handleCheckedIn() async {
    AppToast.showMessage(Localization().getStringEx('', 'You can only check in once per day.'));
  }

  void _clearCheckInDate(DateTime date) async {
    if (_selectedDestination != null) {
      String placeId = _selectedDestination!.id;


      setState(() {
        _placeCheckInDates[placeId]?.remove(date);
        _selectedDestination!.userData?.visited?.remove(date);

        if (_placeCheckInDates[placeId]?.isEmpty ?? true) {
          _lastCheckInDate[placeId] = null;
          _isHistoryExpanded[placeId] = false;
        } else {
          _placeCheckInDates[placeId]?.sort((a, b) => b.compareTo(a));
          _lastCheckInDate[placeId] = _placeCheckInDates[placeId]?.first;
        }
      });

      Places placesService = Places();
      try {
        bool success = await placesService.deleteVisitedPlace(placeId, date.toUtc());
        if (mounted && !success) {
          setState(() {
            _placeCheckInDates[placeId]?.add(date);
            _selectedDestination!.userData?.visited?.add(date);
            _placeCheckInDates[placeId]?.sort((a, b) => b.compareTo(a));
            _lastCheckInDate[placeId] = _placeCheckInDates[placeId]?.first;
          });

          AppToast.showMessage(Localization().getStringEx('', 'Failed to clear check-in date. Please try again.'));
        }
      } catch (e) {

        if (mounted) {
          setState(() {
            _placeCheckInDates[placeId]?.add(date);
            _selectedDestination!.userData?.visited?.add(date);
            _placeCheckInDates[placeId]?.sort((a, b) => b.compareTo(a));
            _lastCheckInDate[placeId] = _placeCheckInDates[placeId]?.first;
          });

          AppToast.showMessage(Localization().getStringEx('', 'An error occurred while clearing the check-in date.'));
        }
      }
    }
  }

  Widget _buildCheckInButton() {
    if (_selectedDestination == null) return Container();

    List<DateTime>? visitedDates = _selectedDestination!.userData?.visited?.whereType<DateTime>().toList();
    bool isCheckedInToday = false;

    if (visitedDates != null && visitedDates.isNotEmpty) {
      visitedDates.sort((a, b) => b.compareTo(a));
      DateTime lastCheckInDate = visitedDates.first;

      DateTime now = DateTime.now();
      isCheckedInToday = lastCheckInDate.year == now.year &&
          lastCheckInDate.month == now.month &&
          lastCheckInDate.day == now.day;
    }

    return SmallRoundedButton(
      label: isCheckedInToday ? Localization().getStringEx('', 'Checked in') : Localization().getStringEx('', 'Check In'),
      textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
      rightIcon: const SizedBox(),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 48),
      onTap: isCheckedInToday ? _handleCheckedIn : _handleCheckIn,
    );
  }

  Widget _buildCheckInHistory() {
    if (_selectedDestination == null) return Container();

    String placeId = _selectedDestination!.id;
    List<DateTime>? visitedDates = _selectedDestination!.userData?.visited?.whereType<DateTime>().toList();
    if (visitedDates == null || visitedDates.isEmpty) return Container();

    visitedDates.sort((a, b) => b.compareTo(a));
    DateTime lastCheckInDate = visitedDates.first;
    String formattedLastDate = DateFormat('MMMM d, yyyy').format(lastCheckInDate);

    bool isExpanded = _isHistoryExpanded[placeId] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isHistoryExpanded[placeId] = !isExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Localization().getStringEx('', 'You last checked in on $formattedLastDate'),
                style: Styles().textStyles.getTextStyle("widget.label.small.fat"),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Styles().colors.fillColorSecondary,
              ),
            ],
          ),
        ),
        if (isExpanded)
          Column(
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
      ],
    );
  }

  List<Widget> _buildSelectedDestinationView() {
    return [
      _buildSelectedDestinationHeader(),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _selectedDestination?.description ?? Localization().getStringEx('', 'No description available'),
          style: Styles().textStyles.getTextStyle("widget.description.regular"),
        ),
      ),
    ];
  }

  // Widget _buildBottomSheetHeader() {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         _buildDragHandle(),
  //         Align(
  //           alignment: Alignment.centerLeft,
  //           child: _buildTitle(),
  //         ),
  //         SizedBox(height: 8),
  //         Align(
  //           alignment: Alignment.centerLeft,
  //           child: _buildFilterButtons(),
  //         ),
  //         SizedBox(height: 8),
  //         Divider(color: Styles().colors.surfaceAccent, thickness: 2),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSelectedDestinationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(Icons.chevron_left, color: Styles().colors.iconColor),
            onPressed: () => setState(() => _selectedDestination = null),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildSelectedDestinationContent(),
        ),
      ],
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
        if (_selectedDestination?.images?.isNotEmpty ?? false)
          _buildImageGallery(),
      ],
    );
  }

  Widget _buildDestinationHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDestinationDetails()),
        SizedBox(width: 8),
        _buildDestinationImage(),
      ],
    );
  }

  Widget _buildDestinationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedDestination?.name ?? '',
          style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
        ),
        SizedBox(height: 8),
        _buildAddressRow(_selectedDestination),
        SizedBox(height: 8),
        _buildShareLocationRow(),
        SizedBox(height: 16),
        _buildCheckInButton(),
      ],
    );
  }

  Widget _buildAddressRow(places_model.Place? place) {
    return GestureDetector(
      onTap: () => place?.launchDirections(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.0), // Adjust this value as needed
            child: Styles().images.getImage('location', size: 15.0) ?? const SizedBox(),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              place?.address ?? Localization().getStringEx('', 'No address available'),
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
    );
  }

  Widget _buildShareLocationRow() {
    return GestureDetector(
      onTap: () {
        // TODO: impment
      },
      child: Row(
        children: [
          Styles().images.getImage('share', excludeFromSemantics: true) ?? const SizedBox(),
          SizedBox(width: 4.0),
          Expanded(
            child: Text(
              Localization().getStringEx('', 'Share this location'),
              style: Styles().textStyles.getTextStyle("widget.card.detail.small.regular")?.apply(
                  decoration: TextDecoration.underline,
                  decorationColor: Styles().colors.fillColorSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDestinationImage() {
    return Container(
      width: 75,
      height: 75,
      child: _selectedDestination?.images?.isNotEmpty ?? false ? Image.network(
        _selectedDestination!.images!.first.imageUrl,
        fit: BoxFit.cover,
      ) : Icon(Icons.image, color: Colors.grey, size: 75),
    );
  }

  Widget _buildImageGallery() {
    if ((_selectedDestination?.images?.length ?? 0) == 1) {
      return TriangleHeaderImage(
        flexBackColor: Styles().colors.background,
        flexImageUrl: _selectedDestination!.images!.first.imageUrl,
        flexLeftToRightTriangleColor: Styles().colors.fillColorSecondaryTransparent05,
        flexLeftToRightTriangleHeight: 53,
        flexRightToLeftTriangleColor: Styles().colors.background,
        flexRightToLeftTriangleHeight: 30,
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedDestination!.images!.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImage = _selectedDestination!.images![index];
                  _isLightboxVisible = true;
                });
              },
              child: Image.network(
                _selectedDestination!.images![index].imageUrl,
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

  Widget _buildDestinationCard(places_model.Place place) {
    return InkWell(
      onTap: () => selectPlace(place),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
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

  Widget _buildDestinationDetailsCard(places_model.Place place) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          place.name ?? Localization().getStringEx('', 'Unknown Name'),
          style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
        ),
        SizedBox(height: 4),
        _buildAddressRow(place),
      ],
    );
  }

  Widget _buildDestinationThumbnail(places_model.Place place) {
    return Container(
      width: 75,
      height: 75,
      child: place.images?.isNotEmpty ?? false
          ? Image.network(place.images!.first.imageUrl, fit: BoxFit.cover)
          : Icon(Icons.image, color: Colors.grey, size: 75),
    );
  }

  Widget _buildFilterButtons() {
    List<Widget> filterButtons = [];

    // Build regular filter buttons
    filterButtons.addAll(_regularFilters.map((tag) => _buildRegularFilterButton(tag)));

    // Build main filter buttons
    for (String mainTag in _mainFilters.keys) {
      bool isExpanded = _expandedMainTags.contains(mainTag);
      Widget mainTagButton = _buildMainFilterButton(mainTag, isExpanded);
      filterButtons.add(mainTagButton);
    }

    // Now, filterButtons contains both regular and main filter buttons.

    List<Widget> filterWidgets = [];

    // Add the combined filter buttons in a single row
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filterWidgets,
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
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Styles().colors.fillColorPrimary,
            ),
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
    if (_selectedFilters.isEmpty) {
      // No filters selected; show all places
      setState(() {
        _storiedSights = List.from(_allPlaces);
      });
    } else {
      setState(() {
        _storiedSights = _allPlaces.where((place) {
          if (place.tags == null || place.tags!.isEmpty) {
            return false;
          }
          // Check if any of the place's tags match any of the selected filters
          return place.tags!.any((tag) => _selectedFilters.contains(tag));
        }).toList();
      });
    }
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
          Localization().getStringEx('', 'Storied Sites'),
          style: Styles().textStyles.getTextStyle("widget.title.medium_large.fat"),
        ),
      ],
    );
  }

  void selectPlace(places_model.Place place) {
    setState(() {
      _selectedDestination = place;
    });
    _controller.animateTo(
      0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (_scrollController != null) {
      _scrollController?.jumpTo(0.0);
    }
    widget.onPlaceSelected(place);
  }

//For testing
// static List<places_model.Place> _getDefaultCampusDestinations() {
//   return [
//     places_model.Place(
//       id: '123',
//       name: 'Doris Kelley Christopher Illinois Extension Center',
//       address: '904 W. Nevada St, Urbana, IL 61801',
//       images: [
//         places_model.Image(imageUrl: 'https://picsum.photos/100'),
//         places_model.Image(imageUrl: 'https://picsum.photos/200'),
//         places_model.Image(imageUrl: 'https://picsum.photos/300'),
//       ],
//       latitude: 1.0,
//       longitude: 1.0,
//     ),
//     places_model.Place(
//       id: '1234',
//       name: 'Krannert Center for the Performing Arts',
//       address: '500 S Goodwin Ave, Urbana, IL',
//       images: [
//         places_model.Image(imageUrl: 'https://picsum.photos/101'),
//         places_model.Image(imageUrl: 'https://picsum.photos/201'),
//         places_model.Image(imageUrl: 'https://picsum.photos/301'),
//       ],
//       latitude: 1.0,
//       longitude: 1.0,
//     ),
//   ];
// }
}
