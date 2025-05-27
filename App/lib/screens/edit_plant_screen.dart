// screens/edit_plant_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plant.dart';
import '../providers/plant_provider.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;

  const EditPlantScreen({super.key, required this.plant});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _category;
  late double _ph;
  late int _waterNeed;
  late String _zone;
  late String _imageUrl;
  late String _description;

  @override
  void initState() {
    super.initState();
    _name = widget.plant.name;
    _category = widget.plant.category;
    _ph = widget.plant.idealPH;
    _waterNeed = widget.plant.waterNeed;
    _zone = widget.plant.zone;
    _imageUrl = widget.plant.imageUrl;
    _description = widget.plant.description;
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updated = Plant(
        id: widget.plant.id,
        name: _name,
        category: _category,
        idealPH: _ph,
        waterNeed: _waterNeed,
        imageUrl: _imageUrl,
        description: _description,
        zone: _zone,
      );

      Provider.of<PlantProvider>(context, listen: false).updatePlant(updated);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pflanze bearbeiten"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      backgroundColor: Colors.green[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Name", _name, (v) => _name = v!),
              _buildTextField("Kategorie", _category, (v) => _category = v!),
              _buildTextField(
                  "pH-Wert", _ph.toString(), (v) => _ph = double.parse(v!),
                  keyboardType: TextInputType.number),
              _buildTextField("Wasserbedarf (ml)", _waterNeed.toString(),
                  (v) => _waterNeed = int.parse(v!),
                  keyboardType: TextInputType.number),
              _buildTextField("Zone", _zone, (v) => _zone = v!),
              _buildTextField("Bild-URL", _imageUrl, (v) => _imageUrl = v!),
              _buildTextField(
                  "Beschreibung", _description, (v) => _description = v!,
                  maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text("Speichern"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, Function(String?) onSaved,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) =>
            (value == null || value.isEmpty) ? "Bitte angeben" : null,
        onSaved: onSaved,
      ),
    );
  }
}
