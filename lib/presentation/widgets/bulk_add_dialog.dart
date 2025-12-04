import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';
import 'package:tiffin_mate/logic/blocs/admin_bloc.dart';

class BulkAddDialog extends StatefulWidget {
  final List<UserProfile> users;

  const BulkAddDialog({super.key, required this.users});

  @override
  State<BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<BulkAddDialog> {
  final Set<String> _selectedUserIds = {};
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Lunch'; // Lunch or Dinner
  double _price = 0.0;
  String _menu = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bulk Add Entries'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date Picker
            ListTile(
              title: Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            // Price Field
            TextFormField(
              initialValue: _price.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
              onChanged: (value) {
                _price = double.tryParse(value) ?? 0.0;
              },
            ),
            // Menu Field
            TextFormField(
              decoration: const InputDecoration(labelText: 'Menu (Optional)'),
              onChanged: (value) {
                _menu = value;
              },
            ),
            const SizedBox(height: 16),
            const Text('Select Users:'),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.users.length,
                itemBuilder: (context, index) {
                  final user = widget.users[index];
                  // Assuming name is unique enough for ID for now, but we need actual ID.
                  // Wait, UserProfile doesn't have ID in the model I saw earlier?
                  // Let's check UserProfile again. It extends HiveObject, so it has a key?
                  // But we need the Firestore ID (uid).
                  // AdminRepositoryImpl.getAllUsers() returns List<UserProfile>.
                  // UserProfile needs an ID field to be useful here.
                  // I should update UserProfile to include ID or return a wrapper.

                  // For now, let's assume we can't select users properly without ID.
                  // I need to fix UserProfile or AdminRepository to return IDs.

                  return CheckboxListTile(
                    title: Text(user.name),
                    value: _selectedUserIds.contains(user.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserIds.add(user.id);
                        } else {
                          _selectedUserIds.remove(user.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedUserIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select at least one user'),
                ),
              );
              return;
            }

            final entryTemplate = TiffinEntry(
              date: _selectedDate,
              type: _selectedType,
              price: _price,
              menu: _menu,
              lastEditedBy: 'admin',
              status: 'pending_approval',
              adminModified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            context.read<AdminBloc>().add(
              BulkAddEntry(
                userIds: _selectedUserIds.toList(),
                entryTemplate: entryTemplate,
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
