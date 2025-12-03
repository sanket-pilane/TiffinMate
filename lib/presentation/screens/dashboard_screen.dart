import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_event.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_state.dart';
import 'package:tiffin_mate/presentation/screens/setting_screen.dart';
import 'package:tiffin_mate/presentation/widgets/add_tiffin_sheet.dart';
import 'package:tiffin_mate/presentation/widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: BlocBuilder<TiffinBloc, TiffinState>(
          builder: (context, state) {
            final name = state.userProfile?.name ?? "User";
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TiffinMate", style: TextStyle(fontSize: 20)),
                Text("Hello, $name 👋", style: const TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<TiffinBloc>(),
                    child: const SettingsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TiffinBloc, TiffinState>(
        builder: (context, state) {
          if (state.status == TiffinStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          double weekTotal = 0;
          for (var tiffin in state.tiffins) {
            weekTotal += tiffin.price;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Animate Summary Card: Slide in from top + Shimmer
                SummaryCard(
                      totalCost: weekTotal,
                      tiffinCount: state.tiffins.length,
                    )
                    .animate()
                    .slideY(
                      begin: -0.2,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(duration: 500.ms)
                    .shimmer(delay: 1000.ms, duration: 1500.ms),

                const SizedBox(height: 30),
                Text(
                  "Recent Entries",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),
                Expanded(
                  child: state.tiffins.isEmpty
                      ? _buildEmptyState()
                      : _buildTiffinList(context, state.tiffins),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final tiffinBloc = context.read<TiffinBloc>();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => BlocProvider.value(
              value: tiffinBloc,
              child: const AddTiffinSheet(),
            ),
          );
        },
        label: const Text("Add Tiffin"),
        icon: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms, duration: 300.ms),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty.json',
            height: 200,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.fastfood, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            "No tiffins added yet!",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildTiffinList(BuildContext context, List<dynamic> tiffins) {
    return ListView.builder(
      itemCount: tiffins.length,
      itemBuilder: (context, index) {
        final tiffin = tiffins[index];

        // List Item Animation: Staggered Slide In
        return Dismissible(
              key: Key(tiffin.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                context.read<TiffinBloc>().add(
                  DeleteTiffinEntryEvent(tiffin.id),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Entry deleted")));
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tiffin.type == 'Lunch'
                        ? Colors.orange.shade100
                        : Colors.indigo.shade100,
                    child: Icon(
                      tiffin.type == 'Lunch'
                          ? Icons.sunny
                          : Icons.nightlight_round,
                      color: tiffin.type == 'Lunch'
                          ? Colors.orange
                          : Colors.indigo,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tiffin.type,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat('MMM d, h:mm a').format(tiffin.date)} ${tiffin.menu.isNotEmpty ? '• ${tiffin.menu}' : ''}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    "₹${tiffin.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .slideX(
              begin: 0.2, // Slide from right
              end: 0,
              duration: 400.ms,
              delay: (index * 50).ms, // Stagger effect
              curve: Curves.easeOutQuad,
            )
            .fadeIn(duration: 400.ms);
      },
    );
  }
}
