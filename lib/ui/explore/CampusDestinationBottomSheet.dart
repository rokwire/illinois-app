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
  List<Place> _campusDestinations = [];  // Updated to use Place model

  // Fallback default campus destinations in the `Place` model
  final List<Place> _defaultCampusDestinations = [
    Place(
      name: 'Doris Kelley Christopher Illinois Extension Center Building Fund',
      address: '123 Main St, Urbana, IL',
      imageUrls: ['https://picsum.photos/200'], // Placeholder image
    ),
    Place(
      name: 'Krannert Center for the Performing Arts',
      address: '500 S Goodwin Ave, Urbana, IL',
      imageUrls: ['https://picsum.photos/200'], // Placeholder image
    ),
    // Add more default destinations if needed
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
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(16.0)),
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
              // Blurb placeholder
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
            width: 80.0,
            height: 4.0,
            margin: EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Campus Destinations',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
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
              Icon(Icons.location_on, size: 16.0, color: Colors.grey),
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
        child: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: isSelected ? Colors.white : Colors.blue,
          backgroundColor: isSelected ? Colors.blue : Colors.white,
          side: BorderSide(color: Colors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Place place) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(place.name ?? 'Unknown Name'),
            subtitle: Row(
              children: [
                Icon(Icons.location_pin),
                Text(place.address ?? 'No address available'),
              ],
            ),
            trailing: Container(
              width: 50.0,
              height: 50.0,
              child: place.imageUrls?.isNotEmpty ?? false
                  ? Image.network(
                place.imageUrls!.first,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.image, color: Colors.grey),
            ),
            onTap: () {
              _onDestinationTap(place);
            },
          ),
          SizedBox(
            height: 4,
          ),
          Divider()
        ],
      ),
    );
  }

  void _onDestinationTap(Place place) {
    setState(() {
      _selectedDestination = place;
    });
  }
}
