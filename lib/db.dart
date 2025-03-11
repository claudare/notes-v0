import 'dart:convert';

import 'package:notes_v0_1/models.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:notes_v0_1/events.dart' as ev;

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
    CREATE TABLE tag (
      tag_id INTEGER NOT NULL PRIMARY KEY,
      name TEXT NOT NULL
    );
    ''');
    db.execute('''
    CREATE TABLE note (
      note_id INTEGER NOT NULL PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL
    );
    ''');
    db.execute('''
    CREATE TABLE note_tag (
      note_id INTEGER NOT NULL,
      tag_id INTEGER NOT NULL,
      FOREIGN KEY (note_id) REFERENCES note(note_id),
      FOREIGN KEY (tag_id) REFERENCES tag(tag_id)
    );
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

  void execEventStatements(ev.Event event) {
    execStatements(event.statements());
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

  Iterable<EventLog> eventLogQueryIterable({required int fromId}) sync* {
    final stmt = db.prepare(
      'SELECT seq_id, data FROM eventlog WHERE seq_id >= ? ORDER BY seq_id ASC;',
    );

    try {
      final cursor = stmt.selectCursor([fromId]);

      while (cursor.moveNext()) {
        yield EventLog.fromRow(cursor.current);
      }
    } finally {
      // i really wish dart had more features... like defer
      stmt.dispose();
    }
  }

  Note? getNoteWithTags(int noteId) {
    final stmt = db.prepare('''
      SELECT
        note.note_id, note.title, note.body,
        tag.tag_id, tag.name
      FROM
        note
      LEFT JOIN
        note_tag ON note.note_id = note_tag.note_id
      LEFT JOIN
        tag ON note_tag.tag_id = tag.tag_id
      WHERE
        note.note_id = ?
      ''');

    try {
      final cursor = stmt.selectCursor([noteId]);

      if (!cursor.moveNext()) {
        return null; // Note not found
      }

      final first = cursor.current;

      // row is {note_id: 1, title: , body: , tag_id: 10, name: tag1}
      // print('row is $first');

      final note = Note(noteId: 1);

      List<Tag> tags = [];

      if (first['tag_id'] != null) {
        // first tag will be included in the original row
        // this is not very ergonimic tbh
        // and this dangles "name" in the sql statement
        tags.add(Tag.fromRow(first));
      }

      while (cursor.moveNext()) {
        final tagRow = cursor.current;
        tags.add(Tag.fromRow(tagRow));
      }

      // print('got tags $tags');

      note.tags = tags;

      return note;
    } finally {
      stmt.dispose();
    }
  }

  void tagInsert(Tag tag) {
    db.execute(
      '''
      INSERT INTO tag (tag_id, name)
      VALUES (?, ?);
    ''',
      [tag.tagId, tag.name],
    );
  }

  List<Tag> tagQueryAll() {
    final resultSet = db.select('SELECT * FROM tag');
    List<Tag> tags = [];
    for (final row in resultSet) {
      final tag = Tag.fromRow(row);
      tags.add(tag);
    }
    return tags;
  }

  void printFullState() {
    print("DB FULL STATE START");
    final res = db.select('SELECT note_id FROM note');

    for (final row in res) {
      final note = getNoteWithTags(row['note_id']);
      if (note != null) {
        print(note.toString());
      }
    }
    print("DB FULL STATE END");
  }
}
