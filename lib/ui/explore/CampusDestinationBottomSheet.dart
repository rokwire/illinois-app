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
  final List<Map<String, String>> _campusDestinations = [
    {
      'name':
      'Doris Kelley Christopher Illinois Extension Center Building Fund',
      'address': '123 Main St, Urbana, IL',
      'image':
      'images/appointment-detail-inperson-tout.png', // Placeholder image path
    },
    {
      'name': 'Krannert Center for the Performing Arts',
      'address': '500 S Goodwin Ave, Urbana, IL',
      'image': 'images/appointment-detail-inperson-tout.png',
    },
    {
      'name': 'Krannert Center for the Performing Arts',
      'address': '500 S Goodwin Ave, Urbana, IL',
      'image': 'images/appointment-detail-inperson-tout.png',
    },
    // Add more destinations as needed
  ];

  // List of selected filters
  final Set<String> _selectedFilters = {};

  // Currently selected destination
  Map<String, String>? _selectedDestination;

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
              ..._campusDestinations.map((destination) {
                return _buildDestinationCard(destination);
              }).toList(),
            ]
                : [
              _buildSelectedDestinationHeader(),
              // Blurb placeholder
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'This is a placeholder blurb about the destination.',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, String>> _filteredDestinations() {
    if (_selectedFilters.isEmpty) {
      return _campusDestinations;
    }
    return _campusDestinations.where((destination) {
      // Implement your filter logic here
      // For example, if 'Open Now' is selected, filter destinations that are open now
      // Since we don't have actual data, we'll return all destinations
      return true;
    }).toList();
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      padding:
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                  _selectedDestination?['name'] ?? '',
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
                child: _selectedDestination?['image'] != null
                    ? Image.asset(
                  _selectedDestination!['image']!,
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
                _selectedDestination?['address'] ?? '',
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

  Widget _buildDestinationCard(Map<String, String> destination) {
    return Container(
      margin:
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(destination['name'] ?? ''),
            subtitle: Row(
              children: [
                Icon(Icons.location_pin),
                Text(destination['address'] ?? ''),
              ],
            ),
            trailing: Container(
              width: 50.0,
              height: 50.0,
              child: destination['image'] != null
                  ? Image.asset(
                destination['image']!,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.image, color: Colors.grey),
            ),
            onTap: () {
              _onDestinationTap(destination);
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

  void _onDestinationTap(Map<String, String> destination) async {
    PlacesService placesService = PlacesService();

    List<Place>? places = await placesService.getAllPlaces();
    await placesService.updatePlaceVisited("a6f2a3d5-2ce6-4fbe-a3f6-bf3c7696da3d", true);

    // Print out the data you get back from getAllPlaces()
    print(places);

    setState(() {
      _selectedDestination = destination;
    });
  }
}
