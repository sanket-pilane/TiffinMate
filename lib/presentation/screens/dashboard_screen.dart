import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:tiffin_mate/logic/blocs/bloc/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/bloc/tiffin_state.dart';

import 'package:tiffin_mate/presentation/widgets/add_tiffin_sheet.dart';
import 'package:tiffin_mate/presentation/widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("TiffinMate"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to Settings
            },
          ),
        ],
      ),
      body: BlocBuilder<TiffinBloc, TiffinState>(
        builder: (context, state) {
          if (state.status == TiffinStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate totals
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
                SummaryCard(
                  totalCost: weekTotal,
                  tiffinCount: state.tiffins.length,
                ),
                const SizedBox(height: 30),
                Text(
                  "Recent Entries",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.tiffins.isEmpty
                      ? _buildEmptyState()
                      : _buildTiffinList(state.tiffins),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const AddTiffinSheet(),
          );
        },
        label: const Text("Add Tiffin"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ensure you have an empty_state.json in assets/animations/
          Lottie.asset(
            'assets/animations/empty_state.json',
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
      ),
    );
  }

  Widget _buildTiffinList(List<dynamic> tiffins) {
    return ListView.builder(
      itemCount: tiffins.length,
      itemBuilder: (context, index) {
        final tiffin = tiffins[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: Colors.white,
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
                tiffin.type == 'Lunch' ? Icons.sunny : Icons.nightlight_round,
                color: tiffin.type == 'Lunch' ? Colors.orange : Colors.indigo,
                size: 20,
              ),
            ),
            title: Text(
              tiffin.type,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormat('MMM d, h:mm a').format(tiffin.date)),
            trailing: Text(
              "₹${tiffin.price.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
