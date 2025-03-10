import 'package:bson/bson.dart';

// this sucks as all events must have a GLOBAL unique id.
// why cant i create insteances of [[[SerializationRepository]]]?

void main() {
  /// Before starting to use the Object codec, we have to register the classes
  /// in the repository
  /// The unique id can best directly .addType(Person, Person.fromBson, 1),
  /// but I guess that it is better to store it in the class to be sure
  /// not to change it from one execution to the other.
  SerializationRepository.addType(Person, Person.fromBson, Person.uniqueId);
  SerializationRepository.addType(
    Marriage,
    Marriage.fromBson,
    Marriage.uniqueId,
  );

  /// Let's create our objects
  final john = Person('John', 30);
  final jane = Person('Jane', 31);
  final marriage = Marriage(DateTime(1990, 5, 22), john, jane);

  /// Now we serialize the top class. The serialize method is defined in the
  /// BsonSerializable mixin.
  BsonBinary result = marriage.serialize();

  var checkBinary =
      'c20000001024637573746f6d496400020000000324637573746f6d'
      '4461746100a1000000096461746500000b4ac9950000000373706f75736531003e00'
      '00001024637573746f6d496400010000000324637573746f6d44617461001d000000'
      '026e616d6500050000004a6f686e0010616765001e00000000000373706f75736532'
      '003e0000001024637573746f6d496400010000000324637573746f6d44617461001d'
      '000000026e616d6500050000004a616e650010616765001f00000000000000';

  print(
    'The result is '
    '${result.hexString == checkBinary ? 'correct' : 'uncorrect'}',
  );
}

/// Example class that implements toJson and fromJson
class Person with BsonSerializable {
  const Person(this.name, this.age);

  /// Class fields
  final String name;
  final int age;

  @override
  int get hashCode => Object.hash(name, age);

  @override
  bool operator ==(Object other) =>
      other is Person && name == other.name && age == other.age;

  /// This field is not strictly necessary, in the sens that when we will
  /// register the class we will simply need to identify it with an unique
  /// number. Anyway, I guess that it is better to store it in the class,
  /// so that we will always reuse the same
  /// The name uniqueId can be changed, if needed.
  static int get uniqueId => 1;

  /// This method is usde to create the object instance starting from
  /// a map with the structure <field Name> : <value>.
  /// It does the reverse job of what we do in the toBson() method
  /// The name fromBson can be changed, if needed.
  Person.fromBson(Map<String, dynamic> dataMap)
    : name = dataMap['name'],
      age = dataMap['age'];

  /// This is just s syntactic sugar for symplifying the
  /// deserialization process. It is not mandatory and can also be avoided
  /// In this case you have to call ObjectCodec directly.
  static Person deserialize(BsonBinary bsonBinary) =>
      ObjectCodec.deserialize(bsonBinary) as Person;

  /// This is the method of the BsonSerializable mixin to be overridden
  /// It creates a map with the pairs <field Name> : <value>.
  /// The values must be types managed by the Bson standard or objects
  /// that are using the BsonSerializable mixin.
  @override
  Map<String, dynamic> get toBson => {'name': name, 'age': age};
}

class Marriage with BsonSerializable {
  const Marriage(this.date, this.spouse1, this.spouse2);

  final DateTime date;
  final Person spouse1;
  final Person spouse2;

  @override
  int get hashCode => Object.hash(date, spouse1, spouse2);

  @override
  bool operator ==(Object other) =>
      other is Marriage &&
      date == other.date &&
      spouse1 == other.spouse1 &&
      spouse2 == other.spouse2;

  static int get uniqueId => 2;

  Marriage.fromBson(Map<String, dynamic> dataMap)
    : date = dataMap['date'],
      spouse1 = dataMap['spouse1'],
      spouse2 = dataMap['spouse2'];

  static Marriage deserialize(BsonBinary bsonBinary) =>
      ObjectCodec.deserialize(bsonBinary) as Marriage;

  @override
  Map<String, dynamic> get toBson => {
    'date': date,
    'spouse1': spouse1,
    'spouse2': spouse2,
  };
}
