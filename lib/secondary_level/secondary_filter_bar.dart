import 'package:flutter/material.dart';

class SecondaryFilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const SecondaryFilterBar({
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
            title: 'Science',
            isSelected: selectedFilter == 'Science',
            onTap: () => onFilterSelected('Science'),
          ),
          FilterButton(
            title: 'AddMaths',
            isSelected: selectedFilter == 'AddMaths',
            onTap: () => onFilterSelected('AddMaths'),
          ),
          FilterButton(
            title: 'Chemistry',
            isSelected: selectedFilter == 'Chemistry',
            onTap: () => onFilterSelected('Chemistry'),
          ),
          FilterButton(
            title: 'Biology',
            isSelected: selectedFilter == 'Biology',
            onTap: () => onFilterSelected('Biology'),
          ),
          FilterButton(
            title: 'Physics',
            isSelected: selectedFilter == 'Physics',
            onTap: () => onFilterSelected('Physics'),
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
