import 'dart:convert';

import 'package:notes_v0/db.dart';
import 'package:test/test.dart';

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

// dart test lib/events.dart
void main() {
  Event roundTrip(Event og) {
    final jsonMap = og.toJson();
    final ser = jsonEncode(jsonMap);
    final map = jsonDecode(ser);
    return Event.parseEvent(map);
  }

  group('Event Serialization Tests', () {
    test('NoteCreated serialization', () {
      final og = NoteCreated(noteId: 1);
      final res = roundTrip(og);

      expect(og.noteId, (res as NoteCreated).noteId);
    });

    test('NoteDeleted serialization', () {
      final og = NoteDeleted(noteId: 2);
      final res = roundTrip(og);

      expect(og.noteId, (res as NoteDeleted).noteId);
    });

    test('NoteBodyEdited serialization', () {
      final og = NoteBodyEdited(noteId: 3, value: 'test body');
      final res = roundTrip(og);

      expect(og.noteId, (res as NoteBodyEdited).noteId);
      expect(og.value, (res).value);
    });
  });
}
