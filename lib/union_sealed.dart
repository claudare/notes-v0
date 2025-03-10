import 'package:test/test.dart';

// following https://dart.dev/language/class-modifiers#sealed

sealed class Event {
  // common events go here
  // final int seqenceId;
  // final int timestamp;
  // Event(this.seqenceId, this.timestamp);
}

class CreateNoteEvent extends Event {
  int noteId;

  CreateNoteEvent(this.noteId);
}

class DeleteNoteEvent extends Event {
  int noteId;
  String extra;

  DeleteNoteEvent(this.noteId, this.extra);
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
  List<Event> events = [CreateNoteEvent(1), DeleteNoteEvent(1, "testing this")];

  for (final event in events) {
    print('prcessing event ${event.toString()}');

    // switch (event) {
    //   case CreateNoteEvent():
    //     print("creating note");
    //   case DeleteNoteEvent():
    //     print("deleting note");
    // }

    var _ = switch (event) {
      CreateNoteEvent() => print('created ${event.noteId}'),
      DeleteNoteEvent() => print('deleted ${event.noteId} with ${event.extra}'),
    };
  }

  // test('calculate', () {
  //   expect(42, 420);
  // });
}
