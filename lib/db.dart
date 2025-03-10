import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:notes_v0/events.dart' as ev;

void main() {
  // this requires that sqlite is installed on the given os
  // so i will need to build or aquire the given library files
  // this is annoying kinda
  // https://pub.dev/packages/sqlite3#manually-providing-sqlite3-libraries
  // for now just install the sqlite3 dev
  // sudo apt install libsqlite3-dev
  // i think in flutter it gets bundled automatically?
  print('Using sqlite3 ${sqlite3.version}');

  // Create a new in-memory database. To use a database backed by a file, you
  // can replace this with sqlite3.open(yourFilePath).
  final db = sqlite3.openInMemory();

  // Create eventlog
  // use data TEXT as utf8 encoding is automatic
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

  final firstEv = ev.CreateNoteEvent(noteId: 1);
  final secondEv = ev.EditBodyNoteEvent(
    noteId: 1,
    value: "hello world, алоало",
  );
  final thirdEv = ev.DeleteNoteEvent(noteId: 1);

  // Prepare a statement to run it multiple times:
  final stmtLogInsert = db.prepare(
    'INSERT INTO eventlog (seq_id, data) VALUES (?, ?);',
  );
  stmtLogInsert
    ..execute([1, jsonEncode(firstEv.toJson())])
    ..execute([2, jsonEncode(secondEv.toJson())])
    ..execute([3, jsonEncode(thirdEv.toJson())]);

  // Dispose a statement when you don't need it anymore to clean up resources.
  stmtLogInsert.dispose();

  // You can run select statements with PreparedStatement.select, or directly
  // on the database:
  final ResultSet resultSet = db.select(
    'SELECT * FROM eventlog WHERE seq_id >= ? order by seq_id ASC;',
    [1],
  );

  // You can iterate on the result set in multiple ways to retrieve Row objects
  // one by one.
  for (final Row row in resultSet) {
    final int seqId = row['seq_id'];
    print("data type ${row['data'].runtimeType}, value ${row['data']}");

    final event = ev.Event.parseEvent(jsonDecode(row['data']));

    print('EventLog[id: $seqId, data: $event]');
    switch (event) {
      case ev.CreateNoteEvent():
        print('creating note ${event.noteId}');
        db.execute(
          'INSERT INTO note (note_id, title, body) VALUES (?, "", "");',
          [event.noteId],
        );

      case ev.DeleteNoteEvent():
        // this actually fails
        print('deleting note ${event.noteId}');
        db.execute('DELETE FROM note WHERE note_id = ?;', [event.noteId]);
        if (db.updatedRows == 0) {
          print('WARNING: bad event was provided, nothing was deleted!!!');
        }
      case ev.EditBodyNoteEvent():
        print('editing note ${event.noteId} body to ${event.value}');
        db.execute(
          '''
          UPDATE note
            SET body = ?
          WHERE
            note_id = ?;
          ''',
          [event.value, event.noteId],
        );
    }

    // print out the state of the db
    printDbState(db);
  }

  // Don't forget to dispose the database to avoid memory leaks
  db.dispose();
}

void printDbState(Database db) {
  print("DB STATE START");
  final res = db.select('SELECT * FROM note');

  for (final row in res) {
    print(
      'Note[id: ${row['note_id']}, title: ${row['title']}, body: ${row['body']}]',
    );
  }
  print("DB STATE END");
}
