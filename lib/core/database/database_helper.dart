import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  factory DatabaseHelper() => _databaseHelper ?? DatabaseHelper._instance();

  DatabaseHelper._instance() {
    _databaseHelper = this;
  }
  static DatabaseHelper? _databaseHelper;

  static Database? _database;

  Future<Database?> get database async {
    _database ??= await initDb();
    return _database;
  }

  Future<Database> initDb() async {
    final path = await getDatabasesPath();
    final databasePath = '$path/cloudloop.db';

    final db =
        await openDatabase(databasePath, version: 1, onCreate: _onCreate);
    return db;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE ${DatabaseUtils.familyTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          admin_id INTEGER,
          created_at TEXT,
          updated_at TEXT,
          mobile_uuid TEXT,
          sync_at TEXT,
          deleted_at TEXT,
          page INTEGER)''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.familyMemberTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          label TEXT,
          role TEXT,
          user_id INTEGER,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar TEXT NOT NULL,
          password TEXT,
          birth_date TEXT NOT NULL,
          gender TEXT NOT NULL,
          diabetes_type INTEGER DEFAULT 1,
          weight INTEGER DEFAULT 0 NOT NULL,
          total_daily_dose INTEGER DEFAULT 0 NOT NULL,
          current_blood_glucose_level REAL precision,
          current_blood_glucose_value REAL precision,
          created_at TEXT,
          updated_at TEXT,
          mobile_uuid TEXT,
          sync_at TEXT,
          page INTEGER,
          deleted_at TEXT)''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.foodTypesTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          image TEXT NOT NULL,
          created_at TEXT,
          updated_at TEXT,
          sync_at TEXT,
          page INTEGER,
          deleted_at TEXT
          )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.userBloodGlucoseTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          "time" TEXT NOT NULL,
          value REAL precision NOT NULL,
          source TEXT NOT NULL,
          user_id INTEGER,
          level TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncAt TEXT,
          deletedAt TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.glucoseReportMetaTable} (
          current REAL precision,
          highest REAL precision,
          lowest REAL precision,
          average REAL precision
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.glucoseReportMetaLevelTable} (
          percentage REAL precision,
          days REAL precision,
          hours REAL precision,
          minutes REAL precision,
          seconds REAL precision,
          status TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.userCarbohydratesTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          value REAL NOT NULL,
          source TEXT NOT NULL,
          user_id INTEGER,
          food_type_id INTEGER,
          time TEXT,
          syncAt TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          deletedAt TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.userInsulinDeliveriesTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          time TEXT NOT NULL,
          value REAL precision NOT NULL,
          source TEXT NOT NULL,
          user_id INTEGER,
          announce_meal_enabled INTEGER DEFAULT 0,
          auto_mode_enabled INTEGER DEFAULT 0,
          iob TEXT,
          hypoPrevention INTEGER DEFAULT 0,
          createdAt TEXT,
          updatedAt TEXT,
          syncAt TEXT,
          deletedAt TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.familyInvitationLogsTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          status TEXT NOT NULL,
          source_id INTEGER NOT NULL,
          target_id INTEGER NOT NULL,
          family_id INTEGER NOT NULL,
          accepted_at TEXT,
          rejected_at TEXT,
          sent_at TEXT NOT NULL,
          created_at TEXT,
          updated_at TEXT,
          mobile_uuid TEXT,
          sync_at TEXT NOT NULL,
          deleted_at TEXT,
          page INTEGER
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.usersTable} (
          id INTEGER NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          avatar TEXT NOT NULL,
          password TEXT,
          birth_date TEXT NOT NULL,
          gender TEXT NOT NULL,
          diabetes_type INTEGER DEFAULT 1,
          weight INTEGER DEFAULT 0 NOT NULL,
          total_daily_dose INTEGER DEFAULT 0 NOT NULL,
          sent_at TEXT,
          connected_at TEXT,
          status TEXT,
          created_at TEXT,
          updated_at TEXT,
          mobile_uuid TEXT,
          sync_at TEXT,
          page INTEGER,
          deleted_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.mySelfTable} (
          temporary_id TEXT,
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          avatar TEXT,
          email TEXT,
          birthDate TEXT,
          gender TEXT,
          updated_at TEXT,
          diabetesType INTEGER DEFAULT 1,
          weight REAL DEFAULT 0 NOT NULL,
          totalDailyDose REAL DEFAULT 0 NOT NULL,
          basalRate REAL,
          insulinCarbRatio REAL ,
          insulinSensitivityFactor REAL
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.pumpTable} (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT, 
          status INTEGER DEFAULT 1 NOT NULL,
          connect_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.autoModeTable} (
          status INTEGER DEFAULT 1 NOT NULL,
          actived_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.cgmTable} (
          id TEXT NOT NULL PRIMARY KEY,
          device_id TEXT,
          transmitter_id TEXT,
          transmitter_code TEXT, 
          status INTEGER DEFAULT 1 NOT NULL,
          connect_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.announceMealTable} (
          type INTEGER,
          status INTEGER DEFAULT 1 NOT NULL,
          actived_at TEXT
        )''');

    //======================Container Table=======================//

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.insertBloodGlucoseTable} (
          temporary_id TEXT NOT NULL,
          time TEXT NOT NULL PRIMARY KEY,
          value REAL NOT NULL,
          source TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          created_at TEXT,
          updated_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.insertInsulinDeliveryTable} (
          temporary_id TEXT NOT NULL,
          time TEXT NOT NULL PRIMARY KEY,
          value REAL NOT NULL,
          source TEXT NOT NULL,
          announce_meal_enabled INTEGER DEFAULT 1,
          auto_mode_enabled INTEGER DEFAULT 1,
          iob REAL,
          hypoPrevention INTEGER DEFAULT 1,
          user_id INTEGER NOT NULL,
          created_at TEXT,
          updated_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.insertCarbohydrateTable} (
          value TEXT NOT NULL,
          source TEXT NOT NULL,
          foodType TEXT NOT NULL,
          time TEXT NOT NULL
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.updateFamilyRoleTable} (
          temporary_id TEXT NOT NULL,
          family_member_id TEXT,
          label TEXT,
          updated_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.acceptInvitationTable} (
          temporary_id TEXT NOT NULL,
          invitation_id INTEGER,
          user_id INTEGER,
          accepted_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.rejectInvitationTable} (
          temporary_id TEXT NOT NULL,
          invitation_id INTEGER,
          user_id INTEGER,
          rejected_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.removeFamilyMemberTable} (
          temporary_id TEXT NOT NULL,
          family_member_id TEXT,
          label TEXT,
          deleted_at TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.leaveFamilyTable} (
         temporary_id TEXT NOT NULL,
         user_id TEXT
        )''');

    await db.execute('''
        CREATE TABLE ${DatabaseUtils.insertInvitationTable} (
         temporary_id TEXT NOT NULL,
         email TEXT NOT NULL,
         user_id INTEGER NOT NULL,
         created_at TEXT,
         updated_at TEXT
        )''');
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db!.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertWithRaw(String query, List<Object?> argument) async {
    final db = await database;
    return db!.rawInsert(query, argument);
  }

  Future<List<Map<String, dynamic>>> queryAllRows({
    required String table,
  }) async {
    final db = await database;
    return db!.query(table);
  }

  Future<List<Map<String, dynamic>>> queryWithClauseRows({
    required String table,
    String? columnName,
    String? argument,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db!.query(
      table,
      where: '$columnName = ?',
      whereArgs: [argument],
    );
  }

  Future<List<Map<String, dynamic>>> queryRawWithClauseRows({
    required String table,
    String? columnName,
    String? argument,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db!.rawQuery(
      'SELECT * FROM $table WHERE $columnName LIKE "%$argument%" '
      'LIMIT $limit OFFSET $offset',
    );
  }

  Future<List<Map<String, dynamic>>> queryRawWhereWithClauseRows({
    required String table,
    String? columnName,
    String? whereClause,
    String? argument,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db!.rawQuery(
      'SELECT $columnName FROM $table WHERE $whereClause = "$argument"',
    );
  }

  Future<List<Map<String, dynamic>>> searchRow({
    required String table,
    String? columnName,
    String? arg,
  }) async {
    final db = await database;
    return db!.query(table, where: '$columnName LIKE $arg');
  }

  Future<QueryCursor> query({
    required String table,
    String? columnName,
    List<Object>? argument,
  }) async {
    final db = await database;
    return db!.queryCursor(
      table,
      columns: [columnName.toString()],
      whereArgs: argument,
    );
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount(String table) async {
    final db = await database;
    final results = await db!.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(
    String table,
    Map<String, dynamic> row,
    String? columnId,
    int id,
  ) async {
    final db = await database;
    return db!.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> deleteWhere(int id, String table, String columnId) async {
    final db = await database;
    return db!.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String table) async {
    final db = await database;
    return db!.delete(
      table,
    );
  }
}
