import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/model/places.dart' as places_model;
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';

class StoriedSightsBottomSheet extends StatefulWidget {
  @override
  _StoriedSightsBottomSheetState createState() =>
      _StoriedSightsBottomSheetState();
}

class _StoriedSightsBottomSheetState extends State<StoriedSightsBottomSheet> {
  List<places_model.Place> _storiedSights = [];
  final DraggableScrollableController _controller = DraggableScrollableController();
  final List<places_model.Place> _defaultCampusDestinations = _getDefaultCampusDestinations();
  final Set<String> _selectedFilters = {};
  places_model.Place? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _loadCampusDestinations();
  }

  Future<void> _loadCampusDestinations() async {
    PlacesService placesService = PlacesService();
    List<places_model.Place>? places = await placesService.getAllPlaces();
    if (places == null || places.isEmpty) {
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
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: [0.25, 0.5, 0.95],
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
                ? _buildPlaceListView()
                : _buildSelectedDestinationView(),
          ),
        );
      },
    );
  }

  List<Widget> _buildPlaceListView() {
    return [
      _buildBottomSheetHeader(),
      ..._storiedSights.map((place) => _buildDestinationCard(place)).toList(),
    ];
  }

  List<Widget> _buildSelectedDestinationView() {
    return [
      _buildSelectedDestinationHeader(),
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _selectedDestination?.description ?? 'No description available',
          style: TextStyle(fontSize: 16.0),
        ),
      ),
    ];
  }

  Widget _buildBottomSheetHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          _buildTitle(),
          SizedBox(height: 8),
          _buildFilterButtons(),
          SizedBox(height: 8),
          Divider(color: Styles().colors.surfaceAccent, thickness: 2),
        ],
      ),
    );
  }

  Widget _buildSelectedDestinationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _buildDragHandle()),
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Styles().colors.fillColorPrimary,
          ),
        ),
        SizedBox(height: 8),
        _buildAddressRow(_selectedDestination?.address),
        SizedBox(height: 8),
        _buildShareLocationRow(),
        SizedBox(height: 16),
        _buildCheckInButton(),
      ],
    );
  }

  Widget _buildAddressRow(String? address) {
    return Row(
      children: [
        Icon(Icons.location_pin, size: 15.0, color: Styles().colors.iconColor),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            address ?? 'No address available',
            style: TextStyle(
              fontSize: 14,
              color: Styles().colors.textSurface,
              decoration: TextDecoration.underline,
              decorationColor: Styles().colors.fillColorSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShareLocationRow() {
    return GestureDetector(
      onTap: () {
        // Placeholder for share functionality
      },
      child: Row(
        children: [
          Icon(Icons.share, size: 15.0, color: Styles().colors.iconColor),
          SizedBox(width: 4.0),
          Expanded(
            child: Text(
              'Share this location',
              style: TextStyle(
                fontSize: 14,
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
    );
  }

  Widget _buildCheckInButton() {
    return SmallRoundedButton(
      label: 'Check-in',
      textStyle: TextStyle(
        fontSize: 16,
        fontFamily: Styles().fontFamilies.bold,
        color: Styles().colors.fillColorPrimary,
      ),
      rightIcon: const SizedBox(),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 48),
      onTap: () {},
    );
  }

  Widget _buildDestinationImage() {
    return Container(
      width: 75,
      height: 75,
      child: _selectedDestination?.images?.isNotEmpty ?? false
          ? Image.network(
        _selectedDestination!.images!.first.imageUrl,
        fit: BoxFit.cover,
      )
          : Icon(Icons.image, color: Colors.grey, size: 75),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedDestination!.images!.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 12.0),
            child: Image.network(
              _selectedDestination!.images![index].imageUrl,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDestinationCard(places_model.Place place) {
    return GestureDetector(
      onTap: () => _onDestinationTap(place),
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
          place.name ?? 'Unknown Name',
          style: TextStyle(
            fontFamily: Styles().fontFamilies.bold,
            fontSize: 16,
            color: Styles().colors.fillColorPrimary,
          ),
        ),
        SizedBox(height: 4),
        _buildAddressRow(place.address),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('Open Now'),
          _buildFilterButton('Near Me'),
          _buildFilterButton('Photo Spots'),
          _buildFilterButton('Donor Gift'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final bool isSelected = _selectedFilters.contains(label);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
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
          side: BorderSide(
            color: isSelected
                ? Styles().colors.fillColorPrimary
                : Styles().colors.surfaceAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
      ),
    );
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
          'Storied Sites',
          style: TextStyle(
            fontFamily: Styles().fontFamilies.bold,
            fontSize: 22.0,
            color: Styles().colors.fillColorPrimary,
          ),
        ),
      ],
    );
  }

  void _onDestinationTap(places_model.Place place) {
    setState(() {
      _selectedDestination = place;
    });
    _controller.animateTo(
      0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  static List<places_model.Place> _getDefaultCampusDestinations() {
    return [
      places_model.Place(
        id: '123',
        name: 'Doris Kelley Christopher Illinois Extension Center',
        address: '904 W. Nevada St, Urbana, IL 61801',
        images: [
          places_model.Image(imageUrl: 'https://picsum.photos/100'),
          places_model.Image(imageUrl: 'https://picsum.photos/200'),
          places_model.Image(imageUrl: 'https://picsum.photos/300'),
        ],
        latitude: 1.0,
        longitude: 1.0,
      ),
      places_model.Place(
        id: '1234',
        name: 'Krannert Center for the Performing Arts',
        address: '500 S Goodwin Ave, Urbana, IL',
        images: [
          places_model.Image(imageUrl: 'https://picsum.photos/101'),
          places_model.Image(imageUrl: 'https://picsum.photos/201'),
          places_model.Image(imageUrl: 'https://picsum.photos/301'),
        ],
        latitude: 1.0,
        longitude: 1.0,
      ),
    ];
  }
}
