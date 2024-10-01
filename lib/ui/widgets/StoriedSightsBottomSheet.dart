import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class StoriedSightsBottomSheet extends StatefulWidget {
  @override
  _StoriedSightsBottomSheetState createState() =>
      _StoriedSightsBottomSheetState();
}

class _StoriedSightsBottomSheetState extends State<StoriedSightsBottomSheet> {
  List<Place> _storiedSights = [];
  final DraggableScrollableController _controller = DraggableScrollableController();

  // Fallback default campus destinations in the `Place` model
  final List<Place> _defaultCampusDestinations = [
    Place(
      name: 'Doris Kelley Christopher Illinois Extension Center',
      address: '904 W. Nevada St, Urbana, IL 61801',
      imageUrls: [
        'https://picsum.photos/100',
        'https://picsum.photos/200',
        'https://picsum.photos/300'
      ],
      id: '123',
      latitude: 1.0,
      longitude: 1.0,
    ),
    Place(
      name: 'Krannert Center for the Performing Arts',
      address: '500 S Goodwin Ave, Urbana, IL',
      imageUrls: ['https://picsum.photos/203', 'https://picsum.photos/204'],
      id: '1234',
      latitude: 1.0,
      longitude: 1.0,
    ),
  ];

  // List of selected filters
  final Set<String> _selectedFilters = {};

  // Currently selected destination
  Place? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _loadCampusDestinations();
  }

  Future<void> _loadCampusDestinations() async {
    PlacesService placesService = PlacesService();

    List<Place>? places = await placesService.getAllPlaces();

    if (places == null || places.isEmpty) {
      print("No places retrieved from service, using default destinations.");
      setState(() {
        _storiedSights = _defaultCampusDestinations;
      });
    } else {
      setState(() {
        _storiedSights = places;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.2,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: [0.2, 0.5, 0.95],
      controller: _controller,
      builder: (BuildContext context, ScrollController scrollController) {
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
          child: ListView(
            controller: scrollController,
            children: _selectedDestination == null
                ? [
              _buildBottomSheetHeader(),
              ..._storiedSights.map((place) {
                return _buildDestinationCard(place);
              }).toList(),
            ]
                : [
              _buildSelectedDestinationHeader(),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  _selectedDestination?.description ??
                      'No description available',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 88.0,
            height: 3.0,
            margin: EdgeInsets.only(bottom: 8.0, top: 8.0),
            decoration: BoxDecoration(
              color: Styles().colors.mediumGray2,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storied Sights',
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 22.0,
                    color: Styles().colors.fillColorPrimary),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('Open Now'),
                _buildFilterButton('Near Me'),
                _buildFilterButton('Photo Spots'),
                _buildFilterButton('Donor Gift'),
              ],
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Divider(
            color: Styles().colors.surfaceAccent,
            thickness: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDestinationHeader() {
    return Container(
      padding: EdgeInsets.only(top: 8.0, bottom: 8.0), // Removed horizontal padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 88.0,
              height: 3.0,
              margin: EdgeInsets.only(bottom: 0.0, top: 8.0),
              decoration: BoxDecoration(
                color: Styles().colors.mediumGray2,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          // Back Button at Top Left
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: Styles().colors.iconColor,
              ),
              onPressed: () {
                setState(() {
                  _selectedDestination = null;
                });
              },
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
          // Content with restored horizontal padding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Main Image Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expanded Title and Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Name
                          Text(
                            _selectedDestination?.name ?? '',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Styles().colors.fillColorPrimary,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          // Address
                          Row(
                            children: [
                              Icon(Icons.location_pin,
                                  size: 15.0, color: Styles().colors.iconColor),
                              SizedBox(width: 4.0),
                              Expanded(
                                child: Text(
                                  _selectedDestination?.address ??
                                      'No address available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: Styles().fontFamilies.medium,
                                    color: Styles().colors.textSurface,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                    Styles().colors.fillColorSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          // "Share this location" text
                          GestureDetector(
                            onTap: () {
                              // Placeholder for share functionality
                            },
                            child: Row(
                              children: [
                                Icon(Icons.share,
                                    size: 15.0, color: Styles().colors.iconColor),
                                SizedBox(width: 4.0),
                                Expanded(
                                  child: Text(
                                    'Share this location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: Styles().fontFamilies.medium,
                                      color: Styles().colors.textSurface,
                                      decoration: TextDecoration.underline,
                                      decorationColor:
                                      Styles().colors.fillColorSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.0),
                          // Check-in Button
                          SmallRoundedButton(
                            label: 'Check-in',
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontFamily: Styles().fontFamilies.bold,
                              color: Styles().colors.fillColorPrimary,
                            ),
                            rightIcon: const SizedBox(),
                            padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 48),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.0),
                    // Main Image
                    Container(
                      width: 75.0,
                      height: 75.0,
                      child: _selectedDestination?.imageUrls?.isNotEmpty ?? false
                          ? Image.network(
                        _selectedDestination!.imageUrls!.first,
                        fit: BoxFit.cover,
                      )
                          : Icon(Icons.image, color: Colors.grey, size: 75.0),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Divider(
                  color: Styles().colors.mediumGray2,
                  thickness: 2,
                ),
                SizedBox(height: 16.0),
                // Image Gallery
                if ((_selectedDestination?.imageUrls?.isNotEmpty ?? false))
                  SizedBox(
                    height: 140.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedDestination!.imageUrls!.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(right: 12.0),
                          child: Image.network(
                            _selectedDestination!.imageUrls![index],
                            width: 140.0,
                            height: 140.0,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final bool isSelected = _selectedFilters.contains(label);
    return Padding(
      padding: EdgeInsets.only(right: 8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              _selectedFilters.remove(label);
            } else {
              _selectedFilters.add(label);
            }
          });
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: Styles().fontFamilies.regular,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor:
          isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          backgroundColor:
          isSelected ? Styles().colors.fillColorPrimary : Colors.white,
          side: isSelected
              ? BorderSide(color: Styles().colors.fillColorPrimary)
              : BorderSide(color: Styles().colors.surfaceAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Place place) {
    return GestureDetector(
      onTap: () => _onDestinationTap(place),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            SizedBox(
              height: 75.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          place.name ?? 'Unknown Name',
                          style: TextStyle(
                            fontFamily: Styles().fontFamilies.bold,
                            fontSize: 16,
                            color: Styles().colors.fillColorPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_pin,
                                size: 15.0, color: Styles().colors.iconColor),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address ?? 'No address available',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: Styles().fontFamilies.medium,
                                  color: Styles().colors.textSurface,
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
                  SizedBox(width: 16),
                  Container(
                    width: 75.0,
                    height: 75.0,
                    child: place.imageUrls?.isNotEmpty ?? false
                        ? Image.network(
                      place.imageUrls!.first,
                      fit: BoxFit.cover,
                      width: 75.0,
                      height: 75.0,
                    )
                        : Icon(Icons.image, color: Colors.grey, size: 75.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            Divider(
              color: Styles().colors.surfaceAccent,
              thickness: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _onDestinationTap(Place place) {
    setState(() {
      _selectedDestination = place;
    });
    _controller.animateTo(0.5,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
}
