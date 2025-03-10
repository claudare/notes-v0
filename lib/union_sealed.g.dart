// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'union_sealed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateNoteEvent _$CreateNoteEventFromJson(Map<String, dynamic> json) =>
    CreateNoteEvent(noteId: (json['noteId'] as num).toInt());

Map<String, dynamic> _$CreateNoteEventToJson(CreateNoteEvent instance) =>
    <String, dynamic>{'noteId': instance.noteId};

DeleteNoteEvent _$DeleteNoteEventFromJson(Map<String, dynamic> json) =>
    DeleteNoteEvent(
      noteId: (json['noteId'] as num).toInt(),
      extra: json['extra'] as String,
    );

Map<String, dynamic> _$DeleteNoteEventToJson(DeleteNoteEvent instance) =>
    <String, dynamic>{'noteId': instance.noteId, 'extra': instance.extra};
