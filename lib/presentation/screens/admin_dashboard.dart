import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/logic/blocs/admin_bloc.dart';
import 'package:tiffin_mate/data/repositories/tiffin_repository.dart';
import 'package:tiffin_mate/presentation/screens/dispute_resolution_screen.dart';
import 'package:tiffin_mate/presentation/widgets/bulk_add_dialog.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<TiffinRepository>().signOut();
              if (context.mounted) {
                // Navigate to root (AuthScreen is home when not authenticated)
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Force rebuild of main to show AuthScreen?
                // StreamBuilder in main should handle it automatically.
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Distribution'),
            Tab(text: 'Disputes'),
            Tab(text: 'Audit Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyDistribution(),
          const DisputeResolutionScreen(),
          const Center(child: Text('Audit Logs (Coming Soon)')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final state = context.read<AdminBloc>().state;
          if (state.users.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) => BulkAddDialog(users: state.users),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No users available to add entries for.'),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDailyDistribution() {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.status == AdminStatus.loading && state.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == AdminStatus.failure) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        } else if (state.users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final deliveredCount = state.dailyDistribution.values
            .where((v) => v)
            .length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${state.users.length}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const Text('Total Customers'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$deliveredCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Delivered Today'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.users.length,
                itemBuilder: (context, index) {
                  final user = state.users[index];
                  final isDelivered = state.dailyDistribution[user.id] ?? false;

                  return ListTile(
                    title: Text(user.name),
                    subtitle: Text('Role: ${user.role}'),
                    trailing: Checkbox(
                      value: isDelivered,
                      onChanged: (value) {
                        if (value == true) {
                          context.read<AdminBloc>().add(
                            MarkDailyTiffin(
                              userId: user.id,
                              date: DateTime.now(),
                            ),
                          );
                        } else {
                          context.read<AdminBloc>().add(
                            UnmarkDailyTiffin(
                              userId: user.id,
                              date: DateTime.now(),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
