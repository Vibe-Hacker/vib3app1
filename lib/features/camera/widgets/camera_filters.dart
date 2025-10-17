import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class CameraFilterOverlay extends StatelessWidget {
  final String filter;
  
  const CameraFilterOverlay({
    Key? key,
    required this.filter,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: _getFilterOverlay(),
      ),
    );
  }
  
  Widget _getFilterOverlay() {
    switch (filter) {
      case 'vintage':
        return Container(
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.1),
            backgroundBlendMode: BlendMode.overlay,
          ),
        );
      case 'black_white':
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.grey,
            BlendMode.saturation,
          ),
          child: Container(),
        );
      case 'warm':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        );
      case 'cool':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        );
      case 'sunset':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.withOpacity(0.2),
                Colors.pink.withOpacity(0.1),
              ],
            ),
          ),
        );
      case 'neon':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.1),
                AppTheme.secondaryColor.withOpacity(0.1),
              ],
            ),
          ),
        );
      default:
        return Container();
    }
  }
}

class FilterSelectionSheet extends StatelessWidget {
  final String? selectedFilter;
  final Function(String?) onFilterSelected;
  
  const FilterSelectionSheet({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final filters = [
      FilterOption(id: null, name: 'Normal', icon: Icons.clear),
      FilterOption(id: 'vibrant', name: 'Vibrant', icon: Icons.wb_sunny),
      FilterOption(id: 'vintage', name: 'Vintage', icon: Icons.photo_filter),
      FilterOption(id: 'black_white', name: 'B&W', icon: Icons.filter_b_and_w),
      FilterOption(id: 'warm', name: 'Warm', icon: Icons.wb_incandescent),
      FilterOption(id: 'cool', name: 'Cool', icon: Icons.ac_unit),
      FilterOption(id: 'sunset', name: 'Sunset', icon: Icons.wb_twilight),
      FilterOption(id: 'neon', name: 'Neon', icon: Icons.lightbulb),
    ];
    
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter.id;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => onFilterSelected(filter.id),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white24,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            filter.icon,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filter.name,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterOption {
  final String? id;
  final String name;
  final IconData icon;
  
  FilterOption({
    required this.id,
    required this.name,
    required this.icon,
  });
}