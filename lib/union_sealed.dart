import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
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
}

sealed class Event {}

class CreateNoteEvent extends Event {
  int noteId;

  CreateNoteEvent({required this.noteId});
}

class DeleteNoteEvent extends Event {
  int noteId;
  String extra = "empty";

  DeleteNoteEvent({required this.noteId, required this.extra});
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
      // print('serialized as ${event.toJson()}');
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
