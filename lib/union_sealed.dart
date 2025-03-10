import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:test/test.dart';

part 'union_sealed.g.dart';

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
}

sealed class Event {}

@JsonSerializable()
class CreateNoteEvent extends Event {
  int noteId;

  CreateNoteEvent({required this.noteId});

  /// Connect the generated [_$PersonFromJson] function to the `fromJson`
  /// factory.
  factory CreateNoteEvent.fromJson(Map<String, dynamic> json) =>
      _$CreateNoteEventFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$CreateNoteEventToJson(this);
}

@JsonSerializable()
class DeleteNoteEvent extends Event {
  int noteId;
  String extra = "empty";

  DeleteNoteEvent({required this.noteId, required this.extra});

  /// Connect the generated [_$PersonFromJson] function to the `fromJson`
  /// factory.
  factory DeleteNoteEvent.fromJson(Map<String, dynamic> json) =>
      _$DeleteNoteEventFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$DeleteNoteEventToJson(this);
}

/*
  what each event has? sequenceId and timestamp
*/

// inline tests are possible!
// but automatic `dart test` only looks into the test folder
// run this with
// dart test lib/union_sealed.dart
// or just run
// dart run lib/union_sealed.dart
void main() {
  List<Event> events = [
    CreateNoteEvent(noteId: 1),
    DeleteNoteEvent(noteId: 1, extra: "hello world"),
  ];

  for (final event in events) {
    print('prcessing event ${event.toString()}');
    switch (event) {
      case CreateNoteEvent():
        print("creating note");
        print('serialized as ${event.toJson()}');
      case DeleteNoteEvent():
        print("deleting note");
    }

    var _ = switch (event) {
      CreateNoteEvent() => print('created ${event.noteId}'),
      DeleteNoteEvent() => print('deleted ${event.noteId} with ${event.extra}'),
    };
  }

  // test('calculate', () {
  //   expect(42, 420);
  // });
}
