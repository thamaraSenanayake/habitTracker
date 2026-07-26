import 'package:habit_flow/models/user_profile_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habitflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE habits (
id TEXT PRIMARY KEY,
title TEXT NOT NULL,
subtitle TEXT NOT NULL,
icon TEXT NOT NULL,
category TEXT NOT NULL,
targetCount INTEGER NOT NULL,
unit TEXT NOT NULL,
currentCount INTEGER NOT NULL,
colorBg TEXT NOT NULL,
colorText TEXT NOT NULL,
streakDays INTEGER NOT NULL,
completedDates TEXT NOT NULL,
logs TEXT NOT NULL,
createdAt TEXT NOT NULL,
reminderTime TEXT
)
''');

    await db.execute('''
  CREATE TABLE user_profile (
    id INTEGER PRIMARY KEY DEFAULT 1,
    name TEXT NOT NULL,
    avatarUrl TEXT NOT NULL,
    overallStreak INTEGER NOT NULL,
    joinedDate TEXT NOT NULL
  )
''');

    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    isLoggedIn INTEGER NOT NULL DEFAULT 0
  )
''');

    // Seed default initial data
    await _seedInitialData(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    isLoggedIn INTEGER NOT NULL DEFAULT 0
  )
''');
    }
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final initialHabits = [
      HabitModel(
        id: 'habit_1',
        title: 'Morning Hydration',
        subtitle: '1/2L completed',
        icon: 'water_drop',
        category: 'hydration',
        targetCount: 2,
        unit: 'L',
        currentCount: 1,
        colorBg: '0x338083FF',
        colorText: '0xFFC0C1FF',
        streakDays: 12,
        completedDates: [todayStr],
        logs: {todayStr: 1},
        createdAt: now.toIso8601String(),
        reminderTime: '08:00 AM',
      ),
      HabitModel(
        id: 'habit_2',
        title: 'Read 20 Pages',
        subtitle: 'Daily Knowledge',
        icon: 'menu_book',
        category: 'reading',
        targetCount: 20,
        unit: 'pages',
        currentCount: 0,
        colorBg: '0x33D97721',
        colorText: '0xFFFFB783',
        streakDays: 8,
        completedDates: [],
        logs: {},
        createdAt: now.toIso8601String(),
        reminderTime: '09:30 PM',
      ),
      HabitModel(
        id: 'habit_3',
        title: '30-Min Workout',
        subtitle: 'Strength Training',
        icon: 'fitness_center',
        category: 'fitness',
        targetCount: 30,
        unit: 'min',
        currentCount: 0,
        colorBg: '0x33EC6A06',
        colorText: '0xFFFFB690',
        streakDays: 5,
        completedDates: [],
        logs: {},
        createdAt: now.toIso8601String(),
        reminderTime: '06:00 PM',
      ),
      HabitModel(
        id: 'habit_4',
        title: 'Meditation',
        subtitle: 'Focus & Calm',
        icon: 'self_improvement',
        category: 'mindfulness',
        targetCount: 1,
        unit: 'session',
        currentCount: 1,
        colorBg: '0x9934343D',
        colorText: '0xFFFFDCC5',
        streakDays: 14,
        completedDates: [todayStr],
        logs: {todayStr: 1},
        createdAt: now.toIso8601String(),
        reminderTime: '07:30 AM',
      ),
    ];

    for (var habit in initialHabits) {
      await db.insert('habits', habit.toMap());
    }

    await db.insert('user_profile', {
      'id': 1,
      'name': 'Alex',
      'avatarUrl':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDKlvm_A9K0_F8V6M5ORmr7r6LIbFgEuGO0PPhz2MnxOxDF3wrsTg4ta89sWAyWjxlzrw8GQ3LqLBgPSz3UhWv3ONRhs4bXt4rWH3W87Zv_nkk6VvXrunY30IEHDnL9IN92E8LlToct5ftLDXwHte0FD_Lw8sx78FQ_duB4IVwmBqjylDb1TsMKw4EBqqonG2urYYABa_GoHm90tqklwMlldvERKmtRUOwneF_3X5TVfAo7s19p7sm1830vxd0YuhjbMHGR-VGLV1_S',
      'overallStreak': 12,
      'joinedDate': 'October 2024',
    });
  }

  // CRUD Operations
  Future<List<HabitModel>> getAllHabits() async {
    final db = await instance.database;
    final result = await db.query('habits', orderBy: 'createdAt DESC');
    return result.map((json) => HabitModel.fromMap(json)).toList();
  }

  Future<int> insertHabit(HabitModel habit) async {
    final db = await instance.database;
    return await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateHabit(HabitModel habit) async {
    final db = await instance.database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabit(String id) async {
    final db = await instance.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<UserProfileModel> getUserProfile() async {
    final db = await instance.database;
    final maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isNotEmpty) {
      return UserProfileModel.fromMap(maps.first);
    }
    return UserProfileModel(
      name: 'Alex',
      avatarUrl: '',
      overallStreak: 12,
      joinedDate: 'October 2024',
    );
  }

  Future<int> updateUserProfile(UserProfileModel profile) async {
    final db = await instance.database;
    return await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // User Authentication Helper Methods
  Future<void> registerUser(String email, String password) async {
    final db = await instance.database;
    await db.insert(
      'users',
      {
        'email': email,
        'password': password,
        'isLoggedIn': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update user profile name based on email prefix
    final profileName = email.split('@')[0];
    final defaultProfile = {
      'id': 1,
      'name': profileName[0].toUpperCase() + profileName.substring(1),
      'avatarUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKlvm_A9K0_F8V6M5ORmr7r6LIbFgEuGO0PPhz2MnxOxDF3wrsTg4ta89sWAyWjxlzrw8GQ3LqLBgPSz3UhWv3ONRhs4bXt4rWH3W87Zv_nkk6VvXrunY30IEHDnL9IN92E8LlToct5ftLDXwHte0FD_Lw8sx78FQ_duB4IVwmBqjylDb1TsMKw4EBqqonG2urYYABa_GoHm90tqklwMlldvERKmtRUOwneF_3X5TVfAo7s19p7sm1830vxd0YuhjbMHGR-VGLV1_S',
      'overallStreak': 12,
      'joinedDate': 'October 2024',
    };
    await db.insert('user_profile', defaultProfile, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> verifyAndLoginUser(String email, String password) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      // Set all other users to logged out first
      await db.update('users', {'isLoggedIn': 0});
      
      // Set isLoggedIn to 1 for this user
      await db.update(
        'users',
        {'isLoggedIn': 1},
        where: 'email = ?',
        whereArgs: [email],
      );

      // Load/Restore user profile name based on email
      final profileName = email.split('@')[0];
      final defaultProfile = {
        'id': 1,
        'name': profileName[0].toUpperCase() + profileName.substring(1),
        'avatarUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKlvm_A9K0_F8V6M5ORmr7r6LIbFgEuGO0PPhz2MnxOxDF3wrsTg4ta89sWAyWjxlzrw8GQ3LqLBgPSz3UhWv3ONRhs4bXt4rWH3W87Zv_nkk6VvXrunY30IEHDnL9IN92E8LlToct5ftLDXwHte0FD_Lw8sx78FQ_duB4IVwmBqjylDb1TsMKw4EBqqonG2urYYABa_GoHm90tqklwMlldvERKmtRUOwneF_3X5TVfAo7s19p7sm1830vxd0YuhjbMHGR-VGLV1_S',
        'overallStreak': 12,
        'joinedDate': 'October 2024',
      };
      await db.insert('user_profile', defaultProfile, conflictAlgorithm: ConflictAlgorithm.replace);
      
      return true;
    }
    return false;
  }

  Future<bool> checkAutoLogin() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'isLoggedIn = 1',
    );
    return maps.isNotEmpty;
  }

  Future<void> logoutUsers() async {
    final db = await instance.database;
    await db.update(
      'users',
      {'isLoggedIn': 0},
    );
  }

  Future<String?> getLoggedInUserEmail() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'isLoggedIn = 1',
    );
    if (maps.isNotEmpty) {
      return maps.first['email'] as String?;
    }
    return null;
  }
}
