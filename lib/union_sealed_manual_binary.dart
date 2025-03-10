import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

class Envelope {
  final int sequenceId;
  final int timestamp;
  Event event;

  Envelope({
    required this.sequenceId,
    required this.timestamp,
    required this.event,
  });

  // Deserialize from ByteData
  factory Envelope.fromBin(ByteData bd) {
    // Read sequence ID (8 bytes)
    final sequenceId = bd.getUint64(0);

    // Read timestamp (8 bytes)
    final timestamp = bd.getUint64(8);

    // extract the "sublist" for the event to be parsed
    // this does not create any memory, but rather defines an offset of the buffer to read
    final eventTrimmed = ByteData.sublistView(bd, 16);

    final event = Event.parseEvent(eventTrimmed);

    return Envelope(sequenceId: sequenceId, timestamp: timestamp, event: event);
  }

  // Serialize to binary
  Uint8List toBin() {
    final bb = BytesBuilder();

    // Write sequence ID as 64-bit integer
    final sequenceIdBytes = ByteData(8)..setUint64(0, sequenceId);
    bb.add(sequenceIdBytes.buffer.asUint8List());

    // Write timestamp as 64-bit integer
    final timestampBytes = ByteData(8)..setUint64(0, timestamp);
    bb.add(timestampBytes.buffer.asUint8List());

    // Write the embedded event
    bb.add(event.toBin());

    return bb.toBytes();
  }
}

sealed class Event {
  static final _eventParsers = {
    CreateNoteEvent.binId: (ByteData bd) => CreateNoteEvent.fromBin(bd),
    DeleteNoteEvent.binId: (ByteData bd) => DeleteNoteEvent.fromBin(bd),
  };

  const Event();

  // Unique identifier for the event type
  static int binId = 0;

  // Static method to parse any event from binary data
  static Event parseEvent(ByteData bd) {
    // Read the event type discriminator (first byte)
    final eventType = bd.getUint8(0);

    // Check if we have a parser for this event type
    if (!_eventParsers.containsKey(eventType)) {
      throw ArgumentError('Unknown event type: $eventType');
    }

    // Create the event using the appropriate parser
    return _eventParsers[eventType]!(bd);
  }

  // Convert event to binary
  Uint8List toBin();
}

class CreateNoteEvent extends Event {
  final int noteId;

  CreateNoteEvent({required this.noteId});

  static const binId = 1;

  // Deserialize from ByteData
  factory CreateNoteEvent.fromBin(ByteData bd) {
    // Skip the first byte (event type discriminator)
    final noteId = bd.getUint64(1);
    return CreateNoteEvent(noteId: noteId);
  }

  // Serialize to binary
  @override
  Uint8List toBin() {
    final bb = BytesBuilder();

    // Write event type discriminator
    bb.addByte(binId);

    // Write noteId as 64-bit integer
    final noteIdBytes = ByteData(8)..setUint64(0, noteId);
    bb.add(noteIdBytes.buffer.asUint8List());

    return bb.toBytes();
  }
}

class DeleteNoteEvent extends Event {
  final int noteId;
  final String extra;

  DeleteNoteEvent({required this.noteId, required this.extra}) {
    // Validate extra string UTF-8 encoded length
    final extraBytes = utf8.encode(extra);
    if (extraBytes.length > 255) {
      throw ArgumentError(
        'Extra string UTF-8 encoded length must be 255 bytes or less',
      );
    }
    // I think this is a faulty way of checking the length
    // or the length must be checked before its passed here
    // Validate extra string length
    // if (extra.length > 255) {
    //   throw ArgumentError('Extra string must be 255 characters or less');
    // }
  }

  static const binId = 2;

  // Deserialize from ByteData
  factory DeleteNoteEvent.fromBin(ByteData bd) {
    // Skip the first byte (event type discriminator)
    final noteId = bd.getUint64(1);
    final extraLength = bd.getUint8(9);

    // Read extra string (UTF-8 encoded)
    // this does not respect the subview!
    // as a list means that we loose it!
    // accessing buffer is always a risk!
    final extraBytes = bd.buffer.asUint8List(
      bd.offsetInBytes + 10,
      extraLength,
    );

    final extra = utf8.decode(extraBytes);

    return DeleteNoteEvent(noteId: noteId, extra: extra);
  }

  // Serialize to binary
  @override
  Uint8List toBin() {
    final bb = BytesBuilder();

    // Write event type discriminator
    bb.addByte(binId);

    // Write noteId as 64-bit integer
    final noteIdBytes = ByteData(8)..setUint64(0, noteId);
    bb.add(noteIdBytes.buffer.asUint8List());

    // Write extra string length (u8)
    final extraBytes = utf8.encode(extra);
    bb.addByte(extraBytes.length);

    // Write extra string (UTF-8 encoded)
    bb.add(extraBytes);

    return bb.toBytes();
  }
}

void main() {
  test('serialize and deserialize CreateNoteEvent', () {
    final original = CreateNoteEvent(noteId: 42);
    final binary = original.toBin();
    final parsed = Event.parseEvent(ByteData.sublistView(binary));

    expect(parsed, isA<CreateNoteEvent>());
    expect((parsed as CreateNoteEvent).noteId, equals(42));
  });

  test('serialize and deserialize DeleteNoteEvent', () {
    final original = DeleteNoteEvent(noteId: 123, extra: "hello");
    final binary = original.toBin();
    final parsed = Event.parseEvent(ByteData.sublistView(binary));

    expect(parsed, isA<DeleteNoteEvent>());
    final deleteParsed = parsed as DeleteNoteEvent;
    expect(deleteParsed.noteId, equals(123));
    expect(deleteParsed.extra, equals("hello"));
  });

  test('DeleteNoteEvent extra string length validation', () {
    expect(
      () => DeleteNoteEvent(noteId: 1, extra: 'a' * 256),
      throwsArgumentError,
    );
  });

  test('serialize and deserialize Envelope with CreateNoteEvent', () {
    final original = Envelope(
      sequenceId: 42,
      timestamp: 1234567890,
      event: CreateNoteEvent(noteId: 100),
    );

    final binary = original.toBin();
    final parsed = Envelope.fromBin(ByteData.sublistView(binary));

    expect(parsed.sequenceId, equals(42));
    expect(parsed.timestamp, equals(1234567890));
    expect(parsed.event, isA<CreateNoteEvent>());
    expect((parsed.event as CreateNoteEvent).noteId, equals(100));
  });

  test('serialize and deserialize Envelope with DeleteNoteEvent', () {
    final original = Envelope(
      sequenceId: 99,
      timestamp: 255,
      event: DeleteNoteEvent(noteId: 200, extra: "test"),
    );

    final binary = original.toBin();

    final parsed = Envelope.fromBin(ByteData.sublistView(binary));

    expect(parsed.sequenceId, equals(99));
    expect(parsed.timestamp, equals(255));
    expect(parsed.event, isA<DeleteNoteEvent>());

    final deleteParsed = parsed.event as DeleteNoteEvent;
    expect(deleteParsed.noteId, equals(200));
    expect(deleteParsed.extra, equals("test"));
  });
}
