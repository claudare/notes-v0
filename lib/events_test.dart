import 'dart:convert';

import 'package:test/test.dart';
import 'package:notes_v0/events.dart';

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
