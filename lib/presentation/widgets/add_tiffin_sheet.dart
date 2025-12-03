import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_event.dart';

class AddTiffinSheet extends StatefulWidget {
  const AddTiffinSheet({super.key});

  @override
  State<AddTiffinSheet> createState() => _AddTiffinSheetState();
}

class _AddTiffinSheetState extends State<AddTiffinSheet> {
  late String _selectedType;
  late TextEditingController _priceController;
  late TextEditingController _menuController;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Auto-detect meal type
    final hour = DateTime.now().hour;
    _selectedType = (hour >= 10 && hour < 17) ? 'Lunch' : 'Dinner';

    // Get default price from Bloc state (if available) or use 0
    final state = context.read<TiffinBloc>().state;
    final defaultPrice = state.userProfile?.defaultTiffinPrice ?? 0.0;

    _priceController = TextEditingController(text: defaultPrice.toString());
    _menuController = TextEditingController();
  }

  void _saveEntry() {
    final price = double.tryParse(_priceController.text) ?? 0.0;

    final entry = TiffinEntry(
      date: _selectedDate,
      type: _selectedType,
      price: price,
      menu: _menuController.text,
    );

    context.read<TiffinBloc>().add(AddTiffinEntryEvent(entry));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Add Tiffin Entry",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTypeSelector('Lunch', Icons.sunny)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTypeSelector('Dinner', Icons.nightlight_round),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Price",
              prefixText: "₹ ",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _menuController,
            decoration: const InputDecoration(
              labelText: "Menu (Optional)",
              hintText: "e.g., Paneer, Roti",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saveEntry,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Save Entry"),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(String type, IconData icon) {
    final isSelected = _selectedType == type;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[200];
    final textColor = isSelected ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
