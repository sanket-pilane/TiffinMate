import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiffin_mate/logic/blocs/admin_bloc.dart';

class DisputeResolutionScreen extends StatelessWidget {
  const DisputeResolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger load disputes when this screen is built
    context.read<AdminBloc>().add(LoadDisputes());

    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        if (state.status == AdminStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.disputes.isEmpty) {
          return const Center(child: Text('No disputes found.'));
        }

        return ListView.builder(
          itemCount: state.disputes.length,
          itemBuilder: (context, index) {
            final disputeItem = state.disputes[index];
            final dispute = disputeItem.entry;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  'Dispute for ${dispute.date.toString().split(' ')[0]}',
                ),
                subtitle: Text(
                  'User ID: ${disputeItem.userId}\nType: ${dispute.type}\nPrice: ${dispute.price}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        // Resolve: Admin accepts user's dispute (or overrides it back to confirmed?)
                        // If user disputed saying "I didn't get it", and admin agrees, we should probably DELETE the entry or mark as skipped.
                        // If admin insists "You got it", they might mark it confirmed again.

                        // Let's assume "Check" means "Accept User's Claim" -> Delete Entry or mark 'skipped'
                        // But wait, if user says "No", they want it gone.
                        // So resolving in favor of user = Delete.

                        // Actually, let's keep it simple:
                        // Green Check = Confirm (Admin insists it's valid)
                        // Red Cross = Delete (Admin agrees it was mistake)

                        // But the UI icon colors might be confusing.
                        // Let's use explicit dialog or better icons.

                        // For now:
                        // Check = Confirm (Override dispute)
                        // Close = Delete (Accept dispute)

                        final updatedEntry = dispute.copyWith(
                          status: 'confirmed',
                          lastEditedBy: 'admin',
                          adminModified: true,
                          updatedAt: DateTime.now(),
                        );
                        context.read<AdminBloc>().add(
                          ResolveDispute(
                            userId: disputeItem.userId,
                            entry: updatedEntry,
                          ),
                        );
                        // Wait, we need userId. TiffinEntry doesn't have userId.
                        // Dispute list in AdminRepositoryImpl fetches from collectionGroup.
                        // The doc reference has the parent.
                        // But TiffinEntry model doesn't store owner ID.
                        // We need to fetch owner ID or store it in TiffinEntry for easier admin management.
                        // Or AdminRepositoryImpl.getDisputedEntries should return a wrapper object (DisputeItem) containing userId and entry.

                        // I need to refactor AdminRepository to return a wrapper.
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        // Delete entry - we can use a special status or delete logic
                        // For now, let's mark it as 'skipped' or deleted.
                        // AdminRepository.resolveDispute uses set(), so we can't delete easily unless we add a delete method.
                        // Or we can set status to 'skipped' which hides it from billing.

                        final updatedEntry = dispute.copyWith(
                          status: 'skipped',
                          lastEditedBy: 'admin',
                          adminModified: true,
                          updatedAt: DateTime.now(),
                        );
                        context.read<AdminBloc>().add(
                          ResolveDispute(
                            userId: disputeItem.userId,
                            entry: updatedEntry,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
