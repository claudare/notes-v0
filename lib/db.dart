import 'dart:convert';

import 'package:notes_v0/models.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:notes_v0/events.dart' as ev;

// could also use https://pub.dev/packages/sqlite_async
// as it allows for more performant async operation and has transactions
// also, nice helper for migrations
// currently using
// https://pub.dev/packages/sqlite3

class Statement {
  String sql;
  List<Object?> parameters;

  Statement(this.sql, this.parameters);
}

class Db {
  late sqlite.Database db;

  // Constructor to initialize the database either in memory or from a file
  Db({String? filePath}) {
    if (filePath == null) {
      // Open in-memory database
      db = sqlite.sqlite3.openInMemory();
    } else {
      // Open database from a file
      db = sqlite.sqlite3.open(filePath);
      throw UnimplementedError("too early for this");
    }

    createSchema();
  }

  void deinit() {
    db.dispose();
  }

  void createSchema() {
    db.execute('''
          CREATE TABLE eventlog (
            seq_id INTEGER NOT NULL PRIMARY KEY,
            data TEXT NOT NULL
          );
        ''');

    db.execute('''
        CREATE TABLE note (
          note_id INTEGER NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL
        )
        ''');
  }

  void execStatements(List<Statement> statements) {
    if (statements.isEmpty) {
      throw ArgumentError("statements cant be empty");
    } else if (statements.length == 1) {
      final statement = statements[0];
      db.execute(statement.sql, statement.parameters);
    } else {
      db.execute("BEGIN TRANSACTION;");
      for (final statement in statements) {
        db.execute(statement.sql, statement.parameters);
      }
      db.execute("COMMIT;");
    }
  }

  void eventLogInsert(EventLog log) {
    // no caching of prepared statements yet
    db.execute('INSERT INTO eventlog (seq_id, data) VALUES (?, ?);', [
      log.seqId,
      log.data,
    ]);
  }

  List<EventLog> eventLogQuery({required int fromId}) {
    final sqlite.ResultSet resultSet = db.select(
      'SELECT seq_id, data FROM eventlog WHERE seq_id >= ? order by seq_id ASC;',
      [fromId],
    );
    List<EventLog> logs = [];
    for (final row in resultSet) {
      final log = EventLog.fromRow(row);
      logs.add(log);
    }
    return logs;
  }

  void printFullState() {
    print("DB FULL STATE START");
    final res = db.select('SELECT * FROM note');

    for (final row in res) {
      final note = Note.fromRow(row);
      print(note.toString());
      // print(
      //   'Note[id: ${row['note_id']}, title: ${row['title']}, body: ${row['body']}]',
      // );
    }
    print("DB FULL STATE END");
  }
}
