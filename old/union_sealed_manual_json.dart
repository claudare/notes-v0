import 'dart:convert';

import 'dart:typed_data';
import 'package:test/test.dart';

// other cool libraries to do this, but in binary.
// https://pub.dev/packages/packme - but unfortunately its an rpc lib
// https://github.com/grpc/grpc-dart - its nice but overly complex. May be good for easy client/server implementation though...
// https://pub.dev/packages/bson - bson format. manual but good?

// following https://dart.dev/language/class-modifiers#sealed
// serialize with
// dart run build_runner build
// serializing this is an impossible task
class Envelope {
  final int sequenceId;
  final int timestamp;
  Event event;

  Envelope({
    required this.sequenceId,
    required this.timestamp,
    required this.event,
  });

  Envelope.fromJson(Map<String, dynamic> json)
    : sequenceId = json['seq'],
      timestamp = json['ts'],
      event = Event.parseEvent(json['event']);

  Map<String, dynamic> toJson() => {
    'seq': sequenceId,
    'ts': timestamp,
    'event': {event.name(): event.toJson()},
  };

  // sequenceId is assumed to be globally unique, so events could be compared this way
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Envelope && sequenceId == other.sequenceId;
}

sealed class Event {
  static final Map<String, Event Function(Map<String, dynamic>)> _eventParsers =
      {
        'note_create': (json) => CreateNoteEvent.fromJson(json),
        'note_delete': (json) => DeleteNoteEvent.fromJson(json),
      };

  const Event();

  // override to provide the name of this thing
  String name();

  // empty values which will be overriden
  Event.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};

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

  @override
  String name() => 'note_create';
  @override
  CreateNoteEvent.fromJson(Map<String, dynamic> json) : noteId = json['noteId'];
  @override
  Map<String, dynamic> toJson() => {'noteId': noteId};
}

class DeleteNoteEvent extends Event {
  int noteId;
  String extra;

  DeleteNoteEvent({required this.noteId, required this.extra});

  @override
  String name() => 'note_delete';
  @override
  DeleteNoteEvent.fromJson(Map<String, dynamic> json)
    : noteId = json['noteId'],
      extra = json['extra'];
  @override
  Map<String, dynamic> toJson() => {'noteId': noteId, 'extra': extra};
}

// inline tests are possible!
// but automatic `dart test` only looks into the test folder
// run this with
// dart test lib/union_sealed.dart
// or just run
// dart run lib/union_sealed.dart
void main() {
  test('smoke', () {
    List<Event> events = [
      CreateNoteEvent(noteId: 1),
      DeleteNoteEvent(noteId: 1, extra: "hello world"),
    ];

    for (final event in events) {
      print('processing event ${event.toString()}');
      switch (event) {
        case CreateNoteEvent():
          print("creating note");
          print('serialized as ${jsonEncode(event.toJson())}');
        case DeleteNoteEvent():
          print("deleting note");
      }

      var _ = switch (event) {
        CreateNoteEvent() => print('created ${event.noteId}'),
        DeleteNoteEvent() => print(
          'deleted ${event.noteId} with ${event.extra}',
        ),
      };
    }
  });

  test('single sederialize', () {
    final og = CreateNoteEvent(noteId: 1);

    final ser = jsonEncode(og.toJson());
    print('serialized ${ser}');
    final map = jsonDecode(ser);
    // print('map ${map}');
    final CreateNoteEvent deser = CreateNoteEvent.fromJson(map);

    expect(og.noteId, deser.noteId, reason: "values must be the same");
  });

  test('envelope sederialize', () {
    //
    final og = Envelope(
      sequenceId: 1,
      timestamp: 42,
      event: CreateNoteEvent(noteId: 1),
    );

    final ser = jsonEncode(og.toJson());
    print('serialized $ser');
    final map = jsonDecode(ser);
    print('map ${map}');
    final result = Envelope.fromJson(map);

    expect(
      (og.event as CreateNoteEvent).noteId,
      (result.event as CreateNoteEvent).noteId,
      reason: "values must be the same",
    );

    expect(og == result, true, reason: "envelopes are assumed to be the same");
  }, tags: "envelope");
}
