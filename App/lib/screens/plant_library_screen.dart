import 'package:flutter/material.dart';
import 'plant_category_screen.dart';
import '../models/plant_data.dart';

class PlantLibraryScreen extends StatelessWidget {
  const PlantLibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pflanzenbibliothek'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Obst'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantCategoryScreen(
                    category: 'Obst',
                    plants: PlantData.fruits,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Gemüse'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantCategoryScreen(
                    category: 'Gemüse',
                    plants: PlantData.vegetables,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Blumen'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlantCategoryScreen(
                    category: 'Blumen',
                    plants: PlantData.flowers,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
