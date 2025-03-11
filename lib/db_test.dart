import 'package:test/test.dart';
import 'package:notes_v0/events.dart' as ev;
import 'package:notes_v0/db.dart';

void main() {
  late Db db;

  setUp(() {
    db = Db(filePath: null);
  });

  tearDown(() {
    db.deinit();
  });

  test('notes with tags', () {
    // Create a new event for creating a note
    final createNoteEvent = ev.NoteCreated(noteId: 1);

    db.execStatements(createNoteEvent.statements());

    // Fetch the created note from the database
    final createdNote = db.getNoteWithTags(1);
    expect(createdNote != null, true);
    expect(createdNote!.noteId, 1);
    expect(createdNote.title, "");
    expect(createdNote.body, "");

    // // Create events for creating tags
    final createTagEvent1 = ev.TagCreated(tagId: 10, name: "tag1");
    db.execStatements(createTagEvent1.statements());
    db.execStatements(ev.TagAddedToNote(noteId: 1, tagId: 10).statements());

    final createTagEvent2 = ev.TagCreated(tagId: 11, name: "tag2");
    db.execStatements(createTagEvent2.statements());
    db.execStatements(ev.TagAddedToNote(noteId: 1, tagId: 11).statements());

    // // Fetch the note with associated tags
    final noteWithTags = db.getNoteWithTags(1);
    expect(noteWithTags != null, true);
    expect(noteWithTags!.noteId, 1);
    expect(noteWithTags.tags.length, 2);

    final tags = noteWithTags.tags.map((tag) => tag.name).toList();
    expect(tags.contains("tag1"), true);
    expect(tags.contains("tag2"), true);
  });
}
