import 'dart:convert';

import 'package:notes_v0/db.dart';

// following https://dart.dev/language/class-modifiers#sealed

sealed class Event {
  static final Map<String, Event Function(Map<String, dynamic>)> _eventParsers =
      {
        NoteCreated._type: (json) => NoteCreated.fromJson(json),
        NoteDeleted._type: (json) => NoteDeleted.fromJson(json),
        NoteBodyEdited._type: (json) => NoteBodyEdited.fromJson(json),
      };

  const Event();

  // empty values which will be overriden
  Event.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};

  // now the database sideeffects
  List<Statement> statements();

  // Static method to parse any event from a map
  static Event parseEvent(Map<String, dynamic> eventMap) {
    final eventType = eventMap['_type'];

    if (_eventParsers.containsKey(eventType)) {
      return _eventParsers[eventType]!(eventMap);
    }

    throw ArgumentError('Unknown event type: $eventType');
  }
}

class NoteCreated extends Event {
  int noteId;

  NoteCreated({required this.noteId});

  static const String _type = 'noteCreated';

  @override
  NoteCreated.fromJson(Map<String, dynamic> json) : noteId = json['noteId'];

  @override
  Map<String, dynamic> toJson() => {'_type': _type, 'noteId': noteId};

  @override
  statements() {
    return [
      Statement('INSERT INTO note (note_id, title, body) VALUES (?, "", "");', [
        noteId,
      ]),
    ];
  }

  // each event must produce a sql statement to execute
}

class NoteDeleted extends Event {
  int noteId;

  NoteDeleted({required this.noteId});

  static const _type = 'noteDeleted';

  @override
  NoteDeleted.fromJson(Map<String, dynamic> json) : noteId = json['noteId'];
  @override
  Map<String, dynamic> toJson() => {'_type': _type, 'noteId': noteId};

  @override
  List<Statement> statements() {
    return [
      Statement('DELETE FROM note WHERE note_id = ?;', [noteId]),
    ];
  }
}

class NoteBodyEdited extends Event {
  int noteId;
  String value;

  NoteBodyEdited({required this.noteId, required this.value});

  static const _type = 'noteBodyEdited';

  @override
  NoteBodyEdited.fromJson(Map<String, dynamic> json)
    : noteId = json['noteId'],
      value = json['value'];
  @override
  Map<String, dynamic> toJson() => {
    '_type': _type,
    'noteId': noteId,
    'value': value,
  };

  @override
  List<Statement> statements() {
    return [
      Statement('UPDATE note SET body = ? WHERE note_id = ?;', [value, noteId]),
    ];
  }
}

class TagCreated extends Event {
  int tagId;
  String name;

  TagCreated({required this.tagId, required this.name});

  static const _type = 'tagCreated';

  @override
  TagCreated.fromJson(Map<String, dynamic> json)
    : tagId = json['tagId'],
      name = json['name'];
  @override
  Map<String, dynamic> toJson() => {
    '_type': _type,
    'tagId': tagId,
    'name': name,
  };

  @override
  List<Statement> statements() {
    return [
      Statement('INSERT INTO tag (tag_id, name) VALUES (?, ?);', [tagId, name]),
    ];
  }
}

class TagAddedToNote extends Event {
  int tagId;
  int noteId;

  TagAddedToNote({required this.tagId, required this.noteId});

  static const String _type = 'tagAddedToNote';

  @override
  TagAddedToNote.fromJson(Map<String, dynamic> json)
    : tagId = json['tagId'],
      noteId = json['noteId'];

  @override
  Map<String, dynamic> toJson() => {
    '_type': _type,
    'tagId': tagId,
    'noteId': noteId,
  };

  @override
  List<Statement> statements() {
    return [
      Statement('INSERT INTO note_tag (note_id, tag_id) VALUES (?, ?);', [
        noteId,
        tagId,
      ]),
    ];
  }
}

class TagAssignToNote extends Event {
  int noteId;
  String tagName;

  TagAssignToNote({required this.noteId, required this.tagName});

  static const _type = 'tagAssignToNote';

  @override
  TagAssignToNote.fromJson(Map<String, dynamic> json)
    : noteId = json['noteId'],
      tagName = json['tagName'];

  @override
  Map<String, dynamic> toJson() => {
    '_type': _type,
    'noteId': noteId,
    'tagName': tagName,
  };

  // hmm, staments in this case require to have some sort of logic
  // but by principles I dont want them to.
  // In this case, sqlite should have the ability to autogenerate these ids
  // Also, I dont want autoincrement?
  // Maybe use a composite primary key with autoincrement? The UNIQUE(device_id, tag_id), where tag_id is INTEGER PRIMATE KEY AUTOINCREMENT?
  // I really do need to use some sort of shorter uuids for all items
  // dont use v4, use something which can be prefixed (scoped) with the device id (which is fully random)
  // this way collisions are really well taken care of.
  // but then this will require custom compilation of the sqlite3, which I would like to avoid
  // there is a way to bring in custom functions though, could be interesing
  // https://pub.dev/packages/sqlite3/example
  // same can be done with sqlite_async
  // https://github.com/powersync-ja/sqlite_async.dart/blob/main/packages/sqlite_async/example/custom_functions_example.dart
  @override
  List<Statement> statements() {
    return [
      Statement('INSERT OR IGNORE INTO tag (tag_id, name) VALUES (?, ?);', [
        null,
        tagName,
      ]),
      Statement(
        'INSERT INTO note_tag (note_id, tag_id) SELECT ?, tag_id FROM tag WHERE name = ?;',
        [noteId, tagName],
      ),
    ];
  }
}
