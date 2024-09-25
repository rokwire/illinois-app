import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';

class CampusDestinationBottomSheet extends StatefulWidget {
  @override
  _CampusDestinationBottomSheetState createState() =>
      _CampusDestinationBottomSheetState();
}

class _CampusDestinationBottomSheetState
    extends State<CampusDestinationBottomSheet> {
  List<Place> _campusDestinations = [];
  final DraggableScrollableController _controller = DraggableScrollableController();

  // Fallback default campus destinations in the `Place` model
  final List<Place> _defaultCampusDestinations = [
    Place(
      name: 'Doris Kelley Christopher Illinois Extension Center Building Fund',
      address: '123 Main St, Urbana, IL',
      imageUrls: ['https://picsum.photos/75'],
      id: '123',
      latitude: 1.0,
      longitude: 1.0,
    ),
    Place(
      name: 'Krannert Center for the Performing Arts',
      address: '500 S Goodwin Ave, Urbana, IL',
      imageUrls: ['https://picsum.photos/75'],
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
        _campusDestinations = _defaultCampusDestinations;
      });
    } else {
      setState(() {
        _campusDestinations = places;
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
              ..._campusDestinations.map((place) {
                return _buildDestinationCard(place);
              }).toList(),
            ]
                : [
              _buildSelectedDestinationHeader(),
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  _selectedDestination?.description ?? 'No description available',
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
            height: 4.0,
            margin: EdgeInsets.only(bottom: 8.0, top: 8.0),
            decoration: BoxDecoration(
              color: Color(0xFFA6A6A6),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campus Contributions',
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.bold,
                    fontSize: 22.0,
                    color: Styles().colors.fillColorPrimary
                ),
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
          SizedBox(height: 8,),
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
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 80.0,
              height: 4.0,
              margin: EdgeInsets.only(bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          // Back Button at Top Left
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedDestination = null;
                });
              },
            ),
          ),
          // Name and Image Side by Side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination Name
              Expanded(
                child: Text(
                  _selectedDestination?.name ?? '',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Destination Image
              SizedBox(width: 8.0),
              Container(
                width: 100.0,
                height: 100.0,
                child: _selectedDestination?.imageUrls?.isNotEmpty ?? false
                    ? Image.network(
                  _selectedDestination!.imageUrls!.first,
                  fit: BoxFit.cover,
                )
                    : Icon(Icons.image, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 8.0),
          // Destination Address
          Row(
            children: [
              Icon(Icons.location_pin, size: 15.0, color: Styles().colors.iconColor),
              SizedBox(width: 4.0),
              Text(
                _selectedDestination?.address ?? 'No address available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
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
        child: Text(label, selectionColor: Styles().colors.fillColorPrimary,
          style: TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies.regular,),),
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Styles().colors.fillColorPrimary,
          backgroundColor: isSelected ? Styles().colors.fillColorPrimary : Colors.white,
          side: BorderSide(color: Styles().colors.surfaceAccent),
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
              height: 75.0, // Set a fixed height for the content
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
                            Icon(Icons.location_pin, size: 15.0, color: Styles().colors.iconColor),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                place.address ?? 'No address available',
                                style: TextStyle(fontSize: 14, fontFamily: Styles().fontFamilies.medium),
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
    _controller.animateTo(0.5, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
}