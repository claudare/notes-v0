# notes-v0


# ideas

Self-hosted note pass suck, so im going to create my own. This time in going a simple experiment.

Tech:
 - flutter frontend for all systems
 - go backend sync server

All the data must be replicated through the backend. All devices listen for updates through websockets. Reader, writer is used for abstraction.

The front-end uses redux pattern and all data created is an event stream.

There are accounts, but for the now only admin exists. Upon logging in you must register the DEVICE with the server.

Each device has its own event stream (aka a file) that is PER APP. These event streams are resolved into projections, which stay on the device. Even projections such as search index also belong to the device. Would be nice to be able to download search index from the server, but it just complicates things.

Now, the difficulty is merging streams from different devices into one full view. Need to take a git approach. Main stream does not hold any data, but rather orders and manages conflicts. Conflicts must have a UI change. Each note should exist in the conflict state indefinitely, until its resolved. Use device ids and names to nicely present the differences.

Another difficulty is incremental updates. I guess incremental diffs are always against the current branch (current device). Multi-device conflicts could be presented as git diff (with extra UI sugar), and its "resolves" are added to the main stream.
Or these resolves are applied to each device streams that took part. But then both conflicting devices need to be online to coordinate things via a sort of networked mutex. We cant effect the raw event stream of another device, as it could be deep offline...

Another difficulty is inserting offline writes. This will require to rebuild the projections from scratch. Or projections need to be reversed to the insertion point, new events replayed, and then continuing the operation.

Another difficulty is data deletion. There is another event stream which will zero out a log (or zero database tables) once all the devices confirm this.

Events are serialized by the clients, preferrably in binary. not sure how dart will play with unions... I think its a pain, but we will see...

The stream could be either a file or a database entries with jsonb...

Nice to haves is importers of data exports. Decoding puzzles are cool exercise in coding.

What about using a flat stream aggregate. Each device uses its own sequential ordering. The server recieves all these events and labels them sequentially. But then offline will greatly reorder things. Maybe use the dynamic modulus trick. Since each device must be registered, we know the count. So global ids could be sparse, but that doesnt solve the frequency problem.

If database is used as a view, then the projection chnages from
f(state, event) -> state
To
f(event) -> []sql-statements

Statements are not stored, but events are. Statements are applied in a transaction for each event? If application fails, the transaction is simply rolled back.

What kind of projections are created for notes app? Keep data small for each one.

Events:
- Reorder, Pin.
- createNote, archiveNote, trashNote, deleteNote.
- edit title, edit content (diff-add, diff-rm)
- addTagToNote, removeTagFromNote
- addFavorite, removeFavorite

These must work over the read projection tables. The are the following:
- Global order. Provides an ordered list of all indivisual notes. Takes care of pinning. How do I allow reordering while making it easily queryable?
- Note content. The largest projection. It keeps full current content of each note. Title, body, createDate, editDate.
- Tags. Normalized relational of tags to notes
- SearchIndex. A special projection. Maybe using the fts5 sqlite thingy? Its a virtual table which is non-transactionally resolved in another thread.
