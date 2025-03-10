import 'dart:convert';

import 'package:test/test.dart';

// other cool libraries to do this, but in binary.
// https://pub.dev/packages/packme - but unfortunately its an rpc lib
// https://github.com/grpc/grpc-dart - its nice but overly complex. May be good for easy client/server implementation though...
// https://pub.dev/packages/bson - bson format. manual but good?

// following https://dart.dev/language/class-modifiers#sealed

class Statement {
  String sql;
  List<Object?> parameters;

  Statement(this.sql, this.parameters);
}

sealed class Event {
  static final Map<String, Event Function(Map<String, dynamic>)> _eventParsers =
      {
        CreateNoteEvent._name: (json) => CreateNoteEvent.fromJson(json),
        DeleteNoteEvent._name: (json) => DeleteNoteEvent.fromJson(json),
        EditBodyNoteEvent._name: (json) => EditBodyNoteEvent.fromJson(json),
      };

  const Event();

  // empty values which will be overriden
  Event.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};

  // now the database sideeffects
  List<Statement> statements();

  // Static method to parse any event from a map
  static Event parseEvent(Map<String, dynamic> eventMap) {
    for (var entry in eventMap.entries) {
      if (_eventParsers.containsKey(entry.key)) {
        return _eventParsers[entry.key]!(entry.value);
      }
    }
    throw ArgumentError('Unknown event type: ${eventMap.keys}');
  }
}

class CreateNoteEvent extends Event {
  int noteId;

  CreateNoteEvent({required this.noteId});

  static const String _name = 'noteCreate';

  @override
  CreateNoteEvent.fromJson(Map<String, dynamic> json) : noteId = json['noteId'];

  @override
  Map<String, dynamic> toJson() => {
    _name: {'noteId': noteId},
  };

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

class DeleteNoteEvent extends Event {
  int noteId;

  DeleteNoteEvent({required this.noteId});

  static const _name = 'noteDelete';

  @override
  DeleteNoteEvent.fromJson(Map<String, dynamic> json) : noteId = json['noteId'];
  @override
  Map<String, dynamic> toJson() => {
    _name: {'noteId': noteId},
  };

  @override
  List<Statement> statements() {
    return [
      Statement('DELETE FROM note WHERE note_id = ?;', [noteId]),
    ];
  }
}

class EditBodyNoteEvent extends Event {
  int noteId;
  String value;

  EditBodyNoteEvent({required this.noteId, required this.value});

  static const _name = 'noteEditBody';

  @override
  EditBodyNoteEvent.fromJson(Map<String, dynamic> json)
    : noteId = json['noteId'],
      value = json['value'];
  @override
  Map<String, dynamic> toJson() => {
    _name: {'noteId': noteId, 'value': value},
  };

  @override
  List<Statement> statements() {
    return [
      Statement('UPDATE note SET body = ? WHERE note_id = ?;', [value, noteId]),
    ];
  }
}

// inline tests are possible!
// but automatic `dart test` only looks into the test folder
// run this with
// dart test lib/union_sealed.dart
// or just run
// dart run lib/union_sealed.dart
void main() {
  test('single sederialize', () {
    final og = CreateNoteEvent(noteId: 1);

    final ser = jsonEncode(og.toJson());
    print('serialized ${ser}');
    final map = jsonDecode(ser);
    print('map ${map}');
    final deser = Event.parseEvent(map);

    expect(
      og.noteId,
      (deser as CreateNoteEvent).noteId,
      reason: "values must be the same",
    );
  });
}
