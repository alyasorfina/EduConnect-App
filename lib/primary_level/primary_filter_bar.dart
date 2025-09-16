import 'package:flutter/material.dart';

class PrimaryFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const PrimaryFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterButton(
            title: 'All',
            isSelected: selectedFilter == 'All',
            onTap: () => onFilterSelected('All'),
          ),
          FilterButton(
            title: 'English',
            isSelected: selectedFilter == 'English',
            onTap: () => onFilterSelected('English'),
          ),
          FilterButton(
            title: 'BM',
            isSelected: selectedFilter == 'BM',
            onTap: () => onFilterSelected('BM'),
          ),
          FilterButton(
            title: 'Mathematics',
            isSelected: selectedFilter == 'Mathematics',
            onTap: () => onFilterSelected('Mathematics'),
          ),
          FilterButton(
            title: 'History',
            isSelected: selectedFilter == 'History',
            onTap: () => onFilterSelected('History'),
          ),
          FilterButton(
            title: 'Geography',
            isSelected: selectedFilter == 'Geography',
            onTap: () => onFilterSelected('Geography'),
          ),
          // Add more FilterButtons if needed
        ],
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
