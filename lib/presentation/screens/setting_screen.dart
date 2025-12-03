import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/core/services/notification_service.dart';
import 'package:tiffin_mate/data/models/user_profile.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_event.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<TiffinBloc>().state;
    if (state.userProfile != null) {
      _nameController.text = state.userProfile!.name;
      _priceController.text = state.userProfile!.defaultTiffinPrice.toString();
    }
    // In a real app, save this preference to Hive/SharedPreferences
  }

  void _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final service = context.read<NotificationService>();

    if (value) {
      bool granted = await service.requestPermissions();
      if (granted) {
        await service.scheduleDailyReminders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminders scheduled for 2 PM & 9 PM'),
            ),
          );
        }
      } else {
        setState(() => _notificationsEnabled = false); // Revert if denied
      }
    } else {
      await service.disableNotifications();
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final newProfile = UserProfile(
        name: _nameController.text,
        defaultTiffinPrice: double.parse(_priceController.text),
        hasSetDefaultPrice: true,
      );

      context.read<TiffinBloc>().add(UpdateUserProfileEvent(newProfile));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings Saved!')));
      Navigator.pop(context);
    }
  }

  void _logout() async {
    await context.read<TiffinRepository>().signOut();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: BlocListener<TiffinBloc, TiffinState>(
        listener: (context, state) {
          if (state.status == TiffinStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${state.errorMessage}")),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "User Profile",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Your Name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Billing Defaults",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Default Tiffin Price",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter a price' : null,
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Daily Reminders"),
                  subtitle: const Text("Get notified at 2 PM & 9 PM"),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Settings"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Correct Way: Use the service provided by main.dart
                    await context
                        .read<NotificationService>()
                        .showInstantNotification();

                    // Debug helper: Show a snackbar so you know you clicked it
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scheduled! Wait 5 seconds...'),
                      ),
                    );
                  },
                  child: const Text("Test Notification"),
                ),

                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
