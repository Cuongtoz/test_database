import 'package:realm/realm.dart';

part 'car.g.dart';

@RealmModel()
class _Car {
  @PrimaryKey()
  final ObjectId id = ObjectId();
  // late String brand;
  late String? model;
  late int? miles;
}
