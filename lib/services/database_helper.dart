import 'package:habit_flow/models/user_profile_model.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/habit_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habitflow3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 8,
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
reminderTime TEXT,
frequency TEXT NOT NULL DEFAULT 'Daily',
selectedDays TEXT,
repeatType TEXT,
repeatInterval INTEGER,
startDate TEXT,
isSynced INTEGER NOT NULL DEFAULT 1,
userId TEXT NOT NULL DEFAULT '1'
)
''');

    await db.execute('''
  CREATE TABLE user_profile (
    userId TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    avatarUrl TEXT NOT NULL,
    avatarData BLOB,
    overallStreak INTEGER NOT NULL,
    joinedDate TEXT NOT NULL
  )
''');

    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    uid TEXT NOT NULL,
    isLoggedIn INTEGER NOT NULL DEFAULT 0,
    isCloudSyncEnabled INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
  CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
''');

    // Seed default settings
    await db.insert('app_settings', {'key': 'theme_mode', 'value': 'dark'});
    await db.insert('app_settings', {'key': 'notifications_enabled', 'value': 'true'});
    await db.insert('app_settings', {'key': 'sound_enabled', 'value': 'true'});

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
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE habits ADD COLUMN frequency TEXT NOT NULL DEFAULT 'Daily'");
      await db.execute("ALTER TABLE habits ADD COLUMN selectedDays TEXT");
      await db.execute("ALTER TABLE habits ADD COLUMN repeatType TEXT");
      await db.execute("ALTER TABLE habits ADD COLUMN repeatInterval INTEGER");
      await db.execute("ALTER TABLE habits ADD COLUMN startDate TEXT");
    }
    if (oldVersion < 4) {
      // Recreate users table to remove password field and add uid and isCloudSyncEnabled
      await db.execute("DROP TABLE IF EXISTS users");
      await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    uid TEXT NOT NULL,
    isLoggedIn INTEGER NOT NULL DEFAULT 0,
    isCloudSyncEnabled INTEGER NOT NULL DEFAULT 0
  )
''');
      // Add isSynced column to habits
      await db.execute("ALTER TABLE habits ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 1");
    }
    if (oldVersion < 5) {
      // Add avatarData to user_profile if not exists
      try {
        await db.execute("ALTER TABLE user_profile ADD COLUMN avatarData BLOB");
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      await db.insert('app_settings', {'key': 'theme_mode', 'value': 'dark'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_settings', {'key': 'notifications_enabled', 'value': 'true'}, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('app_settings', {'key': 'sound_enabled', 'value': 'true'}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE habits ADD COLUMN userId TEXT DEFAULT '1'");
      } catch (_) {}
      
      // Upgrade user_profile id column by recreating the table
      try {
        await db.execute("ALTER TABLE user_profile RENAME TO user_profile_old");
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            avatarUrl TEXT NOT NULL,
            avatarData BLOB,
            overallStreak INTEGER NOT NULL,
            joinedDate TEXT NOT NULL
          )
        ''');
        await db.execute('''
          INSERT INTO user_profile (id, name, avatarUrl, avatarData, overallStreak, joinedDate)
          SELECT id, name, avatarUrl, avatarData, overallStreak, joinedDate FROM user_profile_old
        ''');
        await db.execute("DROP TABLE IF EXISTS user_profile_old");
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute("ALTER TABLE user_profile RENAME TO user_profile_old");
        await db.execute('''
          CREATE TABLE user_profile (
            userId TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            avatarUrl TEXT NOT NULL,
            avatarData BLOB,
            overallStreak INTEGER NOT NULL,
            joinedDate TEXT NOT NULL
          )
        ''');
        await db.execute('''
          INSERT INTO user_profile (userId, name, avatarUrl, avatarData, overallStreak, joinedDate)
          SELECT CAST(id AS TEXT), name, avatarUrl, avatarData, overallStreak, joinedDate FROM user_profile_old
        ''');
        await db.execute("DROP TABLE IF EXISTS user_profile_old");
      } catch (_) {}
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

    // await db.insert('user_profile', {
    //   'id': 1,
    //   'name': 'Alex',
    //   'avatarUrl':
    //       'https://lh3.googleusercontent.com/aida-public/AB6AXuDKlvm_A9K0_F8V6M5ORmr7r6LIbFgEuGO0PPhz2MnxOxDF3wrsTg4ta89sWAyWjxlzrw8GQ3LqLBgPSz3UhWv3ONRhs4bXt4rWH3W87Zv_nkk6VvXrunY30IEHDnL9IN92E8LlToct5ftLDXwHte0FD_Lw8sx78FQ_duB4IVwmBqjylDb1TsMKw4EBqqonG2urYYABa_GoHm90tqklwMlldvERKmtRUOwneF_3X5TVfAo7s19p7sm1830vxd0YuhjbMHGR-VGLV1_S',
    //   'overallStreak': 12,
    //   'joinedDate': 'October 2024',
    // });
  }

  // CRUD Operations
  Future<List<HabitModel>> getAllHabits(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'habits',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => HabitModel.fromMap(json)).toList();
  }

  Future<HabitModel?> getHabit(String id, String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'habits',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    if (maps.isNotEmpty) {
      return HabitModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertHabit(HabitModel habit, String userId) async {
    final db = await instance.database;
    final map = habit.toMap();
    map['userId'] = userId;
    return await db.insert(
      'habits',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateHabit(HabitModel habit, String userId) async {
    final db = await instance.database;
    final map = habit.toMap();
    map['userId'] = userId;
    return await db.update(
      'habits',
      map,
      where: 'id = ? AND userId = ?',
      whereArgs: [habit.id, userId],
    );
  }

  Future<int> deleteHabit(String id, String userId) async {
    final db = await instance.database;
    return await db.delete(
      'habits',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<UserProfileModel> getUserProfile(String userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_profile',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return UserProfileModel.fromMap(maps.first);
    }
    return UserProfileModel(
      userId: userId,
      name: 'Alex',
      avatarUrl: '',
      overallStreak: 12,
      joinedDate: 'October 2024',
    );
  }

  Future<int> insertUserProfile(UserProfileModel profile) async {
    final db = await instance.database;
    return await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateUserProfile(UserProfileModel profile) async {
    final db = await instance.database;
    return await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserProfileModel>> getAllLocalProfiles() async {
    final db = await instance.database;
    final maps = await db.query('user_profile');
    return maps.map((m) => UserProfileModel.fromMap(m)).toList();
  }

  Future<String?> getEmailForUid(String uid) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['email'],
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (maps.isNotEmpty) {
      return maps.first['email'] as String?;
    }
    return null;
  }

  Future<void> migrateUserData(String oldUserId, String newUserId) async {
    final db = await instance.database;

    // 1. Copy habits of oldUserId to newUserId with unique IDs
    final habits = await db.query(
      'habits',
      where: 'userId = ?',
      whereArgs: [oldUserId],
    );
    for (int i = 0; i < habits.length; i++) {
      final copy = Map<String, dynamic>.from(habits[i]);
      copy['userId'] = newUserId;
      copy['isSynced'] = 0;
      copy['id'] = 'habit_${DateTime.now().millisecondsSinceEpoch}_${newUserId}_$i';
      await db.insert(
        'habits',
        copy,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // 2. Migrate user profile if the destination doesn't have one yet
    final oldProfileMaps = await db.query(
      'user_profile',
      where: 'userId = ?',
      whereArgs: [oldUserId],
    );
    if (oldProfileMaps.isNotEmpty) {
      final oldProfileData = Map<String, dynamic>.from(oldProfileMaps.first);
      oldProfileData['userId'] = newUserId;
      await db.insert(
        'user_profile',
        oldProfileData,
        conflictAlgorithm: ConflictAlgorithm.ignore, // Keep existing cloud profile if synced before
      );
    }

    // 3. Delete original local profile and habits of oldUserId to prevent duplicates
    await db.delete(
      'user_profile',
      where: 'userId = ?',
      whereArgs: [oldUserId],
    );
    await db.delete(
      'habits',
      where: 'userId = ?',
      whereArgs: [oldUserId],
    );
  }

  // User Authentication Helper Methods
  Future<void> registerUser(String email, String uid) async {
    final db = await instance.database;
    await db.insert(
      'users',
      {
        'email': email,
        'uid': uid,
        'isLoggedIn': 1,
        'isCloudSyncEnabled': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Update user profile name based on email prefix
    final profileName = email.split('@')[0];
    final defaultProfile = {
      'userId': uid,
      'name': profileName[0].toUpperCase() + profileName.substring(1),
      'avatarUrl': '',
      'overallStreak': 12,
      'joinedDate': 'October 2024',
    };
    await db.insert('user_profile', defaultProfile, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> verifyAndLoginUser(String email, String uid) async {
    final db = await instance.database;
    
    // Set all other users to logged out first
    await db.update('users', {'isLoggedIn': 0});
    
    // Check if the user already exists to preserve their cloud sync setting
    final existing = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    int syncEnabled = 1;
    if (existing.isNotEmpty) {
      syncEnabled = existing.first['isCloudSyncEnabled'] as int? ?? 1;
    }

    // Set isLoggedIn to 1 for this user
    await db.insert(
      'users',
      {
        'email': email,
        'uid': uid,
        'isLoggedIn': 1,
        'isCloudSyncEnabled': syncEnabled,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Load/Restore user profile name based on email
    final profileName = email.split('@')[0];
    final defaultProfile = {
      'userId': uid,
      'name': profileName[0].toUpperCase() + profileName.substring(1),
      'avatarUrl': '',
      'overallStreak': 12,
      'joinedDate': DateFormat('MMMM yyyy').format(DateTime.now()),
    };
    await db.insert('user_profile', defaultProfile, conflictAlgorithm: ConflictAlgorithm.replace);
    
    return true;
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

  Future<String?> getLoggedInUserUid() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'isLoggedIn = 1',
    );
    if (maps.isNotEmpty) {
      return maps.first['uid'] as String?;
    }
    return null;
  }

  Future<List<HabitModel>> getUnsyncedHabits() async {
    final db = await instance.database;
    final result = await db.query(
      'habits',
      where: 'isSynced = 0',
    );
    return result.map((json) => HabitModel.fromMap(json)).toList();
  }

  Future<void> markHabitSynced(String id) async {
    final db = await instance.database;
    await db.update(
      'habits',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markHabitUnsynced(String id) async {
    final db = await instance.database;
    await db.update(
      'habits',
      {'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateCloudSyncSetting(String email, bool enabled) async {
    final db = await instance.database;
    await db.update(
      'users',
      {'isCloudSyncEnabled': enabled ? 1 : 0},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<bool> isCloudSyncEnabled(String email) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      columns: ['isCloudSyncEnabled'],
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return (maps.first['isCloudSyncEnabled'] as int? ?? 0) == 1;
    }
    return false;
  }

  Future<String> getSetting(String key, String defaultValue) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return defaultValue;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
