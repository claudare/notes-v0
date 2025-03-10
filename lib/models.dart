import 'package:sqlite3/sqlite3.dart' as sqlite;

class EventLog {
  int seqId;
  String data;

  EventLog({required this.seqId, required this.data});
}

// This is for convenient use
class Note {
  int noteId;
  String title;
  String body;

  Note({required this.noteId, this.title = "", this.body = ""});

  Note.fromRow(sqlite.Row row)
    : noteId = row['note_id'],
      title = row['title'],
      body = row['body'];

  @override
  String toString() {
    return 'Note[id: $noteId, title: $title, body: $body]';
  }
}
