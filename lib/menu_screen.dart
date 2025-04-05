import 'package:flutter/material.dart';
import 'package:navobs/section_screen.dart';
class MenuScreen extends StatelessWidget {
  final String menuTitle;
  final bool isUnverified;
  final bool canEdit;
  
  const MenuScreen({
    super.key, 
    required this.menuTitle, 
    required this.isUnverified,
    required this.canEdit,
  });
  
  static const List<String> _itemsInMenu = ["Weather", "Traffic", "Public Safety", "Utilities"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            menuTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _itemsInMenu.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_itemsInMenu[index]),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectionScreen(
                        sectionIndex: index,
                        itemsInMenu: _itemsInMenu,
                        isUnverified: isUnverified,
                        canEdit: canEdit,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}