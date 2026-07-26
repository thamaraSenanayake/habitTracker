import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../models/habit_model.dart';

class AddHabitView extends ConsumerStatefulWidget {
  const AddHabitView({Key? key}) : super(key: key);

  @override
  ConsumerState<AddHabitView> createState() => _AddHabitViewState();
}

class _AddHabitViewState extends ConsumerState<AddHabitView> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'book';
  String _selectedCategory = 'reading';
  String _frequency = 'Daily';
  final List<bool> _selectedDays = List.generate(7, (_) => true);
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  int _selectedColorIndex = 0;

  final List<Map<String, dynamic>> _iconsList = [
    {"name": "water_drop", "icon": Icons.water_drop_rounded, "label": "Hydration"},
    {"name": "book", "icon": Icons.menu_book_rounded, "label": "Reading"},
    {"name": "fitness_center", "icon": Icons.fitness_center_rounded, "label": "Fitness"},
    {"name": "psychology", "icon": Icons.self_improvement_rounded, "label": "Mindfulness"},
    {"name": "directions_run", "icon": Icons.directions_run_rounded, "label": "Running"},
    {"name": "restaurant", "icon": Icons.restaurant_rounded, "label": "Nutrition"},
  ];

  final List<Map<String, dynamic>> _colorsList = [
    {"name": "Emerald", "bg": "0x3310B981", "text": "0xFF10B981", "color": const Color(0xFF10B981)},
    {"name": "Blue", "bg": "0x3360A5FA", "text": "0xFF60A5FA", "color": const Color(0xFF60A5FA)},
    {"name": "Purple", "bg": "0x338083FF", "text": "0xFFC0C1FF", "color": const Color(0xFF8083FF)},
    {"name": "Orange", "bg": "0x33D97721", "text": "0xFFFFB783", "color": const Color(0xFFF97316)},
    {"name": "Red", "bg": "0x33EF4444", "text": "0xFFFFB690", "color": const Color(0xFFEF4444)},
  ];

  String _getCategoryFromIcon(String icon) {
    switch (icon) {
      case 'water_drop':
        return 'hydration';
      case 'book':
        return 'reading';
      case 'fitness_center':
      case 'directions_run':
        return 'fitness';
      case 'psychology':
        return 'mindfulness';
      case 'restaurant':
        return 'nutrition';
      default:
        return 'general';
    }
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8083FF),
              onPrimary: Color(0xFF0F172A),
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _saveHabit() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a habit name',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String formatTime = _reminderEnabled
        ? "${_reminderTime.hourOfPeriod.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')} ${_reminderTime.period == DayPeriod.am ? 'AM' : 'PM'}"
        : "";

    final newHabit = HabitModel(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: _selectedCategory[0].toUpperCase() + _selectedCategory.substring(1),
      icon: _selectedIcon,
      category: _selectedCategory,
      targetCount: 1,
      unit: 'session',
      currentCount: 0,
      colorBg: _colorsList[_selectedColorIndex]['bg'] as String,
      colorText: _colorsList[_selectedColorIndex]['text'] as String,
      streakDays: 0,
      completedDates: [],
      logs: {},
      createdAt: DateTime.now().toIso8601String(),
      reminderTime: _reminderEnabled ? formatTime : null,
    );

    final vm = ref.read(habitViewModelProvider.notifier);
    await vm.addHabit(newHabit);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _colorsList[_selectedColorIndex]['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFFC7C4D7), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create New Habit',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE4E1ED),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveHabit,
            child: Text(
              'Save',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF22C55E),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit Name Input
            Text(
              'Habit Name',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC7C4D7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: 'e.g., Read 20 pages',
                hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF908FA0).withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8083FF), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 28),

            // Icon Picker
            Text(
              'Choose Icon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC7C4D7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            GridPaper(
              color: Colors.transparent,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _iconsList.length,
                itemBuilder: (context, index) {
                  final iconItem = _iconsList[index];
                  final isSelected = _selectedIcon == iconItem['name'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconItem['name'] as String;
                        _selectedCategory = _getCategoryFromIcon(_selectedIcon);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? themeColor.withOpacity(0.15)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? themeColor : Colors.white.withOpacity(0.05),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withOpacity(0.25),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        iconItem['icon'] as IconData,
                        color: isSelected ? themeColor : const Color(0xFFC7C4D7),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Frequency Selection
            Text(
              'Frequency',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC7C4D7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: ['Daily', 'Weekly', 'Specific'].map((freq) {
                  final isSelected = _frequency == freq;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _frequency = freq;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          freq,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? Colors.white : const Color(0xFFC7C4D7),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Day Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final isSelected = _selectedDays[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDays[index] = !_selectedDays[index];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? themeColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFF464554),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: themeColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      days[index],
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFC7C4D7),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Daily Reminder Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Daily Reminder',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Push notifications to keep you on track',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFFC7C4D7),
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _reminderEnabled,
                  onChanged: (val) {
                    setState(() {
                      _reminderEnabled = val;
                    });
                  },
                  activeColor: themeColor,
                  activeTrackColor: themeColor.withOpacity(0.3),
                  inactiveThumbColor: const Color(0xFFC7C4D7),
                  inactiveTrackColor: const Color(0xFF34343D),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time Selector Card
            if (_reminderEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: themeColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Time',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _selectTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          _reminderTime.format(context),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // Color Tag Selection
            Container(
              padding: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color Tag',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: List.generate(_colorsList.length, (index) {
                      final item = _colorsList[index];
                      final color = item['color'] as Color;
                      final isSelected = _selectedColorIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
