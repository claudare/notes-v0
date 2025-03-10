import 'dart:convert';

import 'package:notes_v0/db.dart';
import 'package:notes_v0/events.dart' as ev;
import 'package:notes_v0/models.dart';

void main() {
  // Create a new in-memory database. To use a database backed by a file, you
  // can replace this with sqlite3.open(yourFilePath).
  final db = Db(filePath: null);

  final firstEv = ev.NoteCreated(noteId: 1);
  final secondEv = ev.NoteBodyEdited(noteId: 1, value: "hello world, алоало");
  final thirdEv = ev.NoteDeleted(noteId: 1);

  db.eventLogInsert(EventLog(seqId: 1, data: jsonEncode(firstEv)));
  db.eventLogInsert(EventLog(seqId: 2, data: jsonEncode(secondEv)));
  db.eventLogInsert(EventLog(seqId: 3, data: jsonEncode(thirdEv)));

  final logsIterable = db.eventLogQueryIterable(fromId: 1);
  final iter = logsIterable.iterator;

  while (iter.moveNext()) {
    final log = iter.current;
    final event = ev.Event.parseEvent(jsonDecode(log.data));

    print('EventLog[id: ${log.seqId}, data: $event]');

    db.execStatements(event.statements());

    db.printFullState();
  }

  // Don't forget to dispose the database to avoid memory leaks
  db.deinit();
}
