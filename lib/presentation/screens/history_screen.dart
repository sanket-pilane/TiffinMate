import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:tiffin_mate/core/services/pdf_generate.dart';
import 'package:tiffin_mate/data/models/tiffin_entry.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_bloc.dart';
import 'package:tiffin_mate/logic/blocs/tiffin_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  final PdfService _pdfService = PdfService(); // Initialize Service

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TiffinEntry> _getTiffinsForDay(
    DateTime day,
    List<TiffinEntry> allTiffins,
  ) {
    return allTiffins.where((tiffin) {
      return isSameDay(tiffin.date, day);
    }).toList();
  }

  List<TiffinEntry> _getTiffinsForRange(
    DateTime start,
    DateTime end,
    List<TiffinEntry> allTiffins,
  ) {
    return allTiffins.where((tiffin) {
      return tiffin.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          tiffin.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History & Bill")),
      body: BlocBuilder<TiffinBloc, TiffinState>(
        builder: (context, state) {
          final tiffins = state.tiffins;

          List<TiffinEntry> selectedTiffins = [];
          if (_rangeStart != null && _rangeEnd != null) {
            selectedTiffins = _getTiffinsForRange(
              _rangeStart!,
              _rangeEnd!,
              tiffins,
            );
          } else if (_selectedDay != null) {
            selectedTiffins = _getTiffinsForDay(_selectedDay!, tiffins);
          } else {
            // Default to showing all if nothing specific selected (or handle as empty)
            selectedTiffins = tiffins;
          }

          double totalBill = selectedTiffins.fold(
            0,
            (sum, item) => sum + item.price,
          );

          return Column(
            children: [
              _buildCalendar(tiffins),
              const SizedBox(height: 8),
              _buildBillHeader(
                totalBill,
                selectedTiffins,
                state.userProfile?.name ?? 'User',
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedTiffins.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final tiffin = selectedTiffins[index];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        DateFormat('dd MMM').format(tiffin.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      title: Text(
                        "${tiffin.type} ${tiffin.menu.isNotEmpty ? '(${tiffin.menu})' : ''}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Text(
                        "₹${tiffin.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(List<TiffinEntry> tiffins) {
    return TableCalendar(
      firstDay: DateTime.utc(2023, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      rangeSelectionMode: _rangeSelectionMode,
      eventLoader: (day) => _getTiffinsForDay(day, tiffins),
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _rangeStart = null;
            _rangeEnd = null;
            _rangeSelectionMode = RangeSelectionMode.toggledOff;
          });
        }
      },
      onRangeSelected: (start, end, focusedDay) {
        setState(() {
          _selectedDay = null;
          _focusedDay = focusedDay;
          _rangeStart = start;
          _rangeEnd = end;
          _rangeSelectionMode = RangeSelectionMode.toggledOn;
        });
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() => _calendarFormat = format);
        }
      },
    );
  }

  Widget _buildBillHeader(
    double total,
    List<TiffinEntry> selectedTiffins,
    String userName,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Bill",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
              Text(
                "₹${total.toStringAsFixed(0)}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${selectedTiffins.length} Meals",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (selectedTiffins.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    // Trigger PDF Share
                    await _pdfService.generateAndShareInvoice(
                      selectedTiffins,
                      userName,
                      _rangeStart ?? _selectedDay,
                      _rangeEnd ?? _selectedDay,
                    );
                  },
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
