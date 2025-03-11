import 'package:notes_v0_1/events.dart';

class EventLog {
  int seqId;
  String data;

  EventLog({required this.seqId, required this.data});

  factory EventLog.fromRow(Map<String, dynamic> map) {
    return EventLog(seqId: map['seq_id'] as int, data: map['data'] as String);
  }
}

// This is for convenient use
class Note {
  int noteId;
  String title;
  String body;

  List<Tag> tags;

  Note({
    required this.noteId,
    this.title = "",
    this.body = "",
    this.tags = const [],
  });

  // cant use this anymore, as tags are involved
  // Note.fromRow(Map<String, dynamic> row)
  //   : noteId = row['note_id'],
  //     title = row['title'],
  //     body = row['body'];

  @override
  String toString() {
    return 'Note[id: $noteId, title: $title, body: $body, tagCount ${tags.length}]';
  }
}

class Tag {
  int tagId;
  String name;

  Tag({required this.tagId, required this.name});

  factory Tag.fromRow(Map<String, dynamic> map) {
    return Tag(tagId: map['tag_id'] as int, name: map['name'] as String);
  }

  @override
  String toString() {
    return 'Tag[id: $tagId, name: $name]';
  }
}
