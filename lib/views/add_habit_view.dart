import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../viewmodels/habit_viewmodel.dart';
import '../models/habit_model.dart';
import '../theme/theme_ext.dart';

class AddHabitView extends ConsumerStatefulWidget {
  const AddHabitView({super.key});

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

  // Specific Frequency Configs
  String _repeatType = 'Interval'; // 'Interval' or 'Monthly Dates'
  int _repeatInterval = 2;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  String _formatStartDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
    final formatted = DateFormat('MMM d').format(date);
    return isTomorrow ? 'Tomorrow, $formatted' : formatted;
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: context.isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF22C55E),
                    onPrimary: Color(0xFF0F172A),
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF22C55E),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

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
          data: context.isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF8083FF),
                    onPrimary: Color(0xFF0F172A),
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF8083FF),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
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
      frequency: _frequency,
      selectedDays: _frequency == 'Weekly' ? _selectedDays : null,
      repeatType: _frequency == 'Specific' ? _repeatType : null,
      repeatInterval: _frequency == 'Specific' ? _repeatInterval : null,
      startDate: _frequency == 'Specific' ? _startDate.toIso8601String() : null,
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
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.secondaryTextColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create New Habit',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textColor,
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
                color: context.secondaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(color: context.textColor, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.cardColor,
                hintText: 'e.g., Read 20 pages',
                hintStyle: GoogleFonts.plusJakartaSans(color: context.secondaryTextColor.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
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
                color: context.secondaryTextColor,
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
                            : context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? themeColor
                              : (context.isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05)),
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
                        color: isSelected ? themeColor : context.secondaryTextColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // Frequency Selection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequency',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.secondaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top Segmented Control (Daily, Weekly, Specific)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.bgColor,
                      borderRadius: BorderRadius.circular(12),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF22C55E)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF22C55E).withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                freq,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected
                                      ? (context.isDark ? const Color(0xFF0F172A) : Colors.white)
                                      : const Color(0xFF94A3B8),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Conditional Weekly View (Day Chips)
                  if (_frequency == 'Weekly') ...[
                    const SizedBox(height: 20),
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
                                color: isSelected
                                    ? Colors.transparent
                                    : (context.isDark
                                        ? const Color(0xFF464554)
                                        : const Color(0xFFCBD5E1)),
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
                                color: isSelected
                                    ? (context.isDark ? const Color(0xFF0F172A) : Colors.white)
                                    : context.secondaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],

                  // Conditional Specific View (Interval controls)
                  if (_frequency == 'Specific') ...[
                    const SizedBox(height: 24),

                    // Subsection Title: Repeat Type
                    Text(
                      'Repeat Type',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.secondaryTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Interval', 'Monthly Dates'].map((type) {
                        final isSelected = _repeatType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _repeatType = type;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                right: type == 'Interval' ? 8.0 : 0.0,
                                left: type == 'Monthly Dates' ? 8.0 : 0.0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF22C55E).withOpacity(0.12)
                                    : context.bgColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF22C55E)
                                      : (context.isDark
                                          ? const Color(0xFF464554).withOpacity(0.5)
                                          : const Color(0xFFCBD5E1)),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? const Color(0xFF22C55E) : context.secondaryTextColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_repeatType == 'Interval') ...[
                      const SizedBox(height: 24),

                      // Number Input Field: Repeat every with a stepper
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Repeat every',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_repeatInterval > 1) {
                                    setState(() {
                                      _repeatInterval--;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.bgColor,
                                    border: Border.all(
                                      color: context.isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.08),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.remove,
                                    color: Color(0xFF22C55E),
                                    size: 18,
                                  ),
                                ),
                              ),
                              Container(
                                width: 50,
                                alignment: Alignment.center,
                                child: Text(
                                  '$_repeatInterval',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: context.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _repeatInterval++;
                                  });
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.bgColor,
                                    border: Border.all(
                                      color: context.isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.black.withOpacity(0.08),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.add,
                                    color: Color(0xFF22C55E),
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'days',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Date Picker Row: First instance on
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'First instance on',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: context.isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _formatStartDate(_startDate),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: context.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Subtle Helper Text
                    Builder(
                      builder: (context) {
                        final DateFormat f = DateFormat('MMM d');
                        final d1 = f.format(_startDate);
                        final d2 = f.format(_startDate.add(Duration(days: _repeatInterval)));
                        final d3 = f.format(_startDate.add(Duration(days: _repeatInterval * 2)));
                        return Text(
                          'Your next habit check-in will be scheduled for $d1, $d2, $d3...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: context.secondaryTextColor,
                            height: 1.4,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
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
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Push notifications to keep you on track',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: context.secondaryTextColor,
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
                  inactiveThumbColor: context.secondaryTextColor,
                  inactiveTrackColor: context.isDark ? const Color(0xFF34343D) : const Color(0xFFE2E8F0),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time Selector Card
            if (_reminderEnabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                  ),
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
                            color: context.textColor,
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
                          color: context.textColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.textColor.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          _reminderTime.format(context),
                          style: GoogleFonts.plusJakartaSans(
                            color: context.textColor,
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
                border: Border(
                  top: BorderSide(
                    color: context.textColor.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color Tag',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
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
                                ? Border.all(
                                    color: context.isDark ? Colors.white : Colors.black,
                                    width: 2,
                                  )
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
                    }).toList(),
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
