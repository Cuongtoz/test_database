import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'car.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Realm Demo'),
      ),
      body: CarList(),
    );
  }
}

class CarList extends StatefulWidget {
  @override
  _CarListState createState() => _CarListState();
}

class _CarListState extends State<CarList> {
  late Future<RealmResults<Car>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carsFuture = _getCarsFromDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RealmResults<Car>>(
      future: _carsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == Enum) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final cars = snapshot.data!;
          return ListView.builder(
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return Card(
                child: ListTile(
                  title: Text(car.model ?? ""),
                  subtitle: Text('Miles: ${car.miles ?? ""}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarDetailPage(car: car),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDataPage(car: car),
                            ),
                          );
                          setState(() {
                            _carsFuture = _getCarsFromDatabase();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await _deleteCar(car);
                          setState(() {
                            _carsFuture = _getCarsFromDatabase();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<void> _deleteCar(Car car) async {
    final realm = await _openRealm();
    realm.write(() {
      realm.delete(car);
    });
  }
}

class EditDataPage extends StatelessWidget {
  final Car car;

  const EditDataPage({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modelController = TextEditingController(text: car.model);
    final milesController = TextEditingController(text: car.miles?.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: modelController,
              decoration: InputDecoration(labelText: 'Enter model'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: milesController,
              decoration: InputDecoration(labelText: 'Enter miles'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final String newModel = modelController.text;
                final int newMiles = int.tryParse(milesController.text) ?? 0;

                final realm = await _openRealm();
                realm.write(() {
                  car.model = newModel;
                  car.miles = newMiles;
                });

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class CarDetailPage extends StatelessWidget {
  final Car car;

  const CarDetailPage({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details of ${car.model ?? ""}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model: ${car.model ?? ""}'),
            Text('Miles: ${car.miles ?? ""}'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<RealmResults<Car>> _getCarsFromDatabase() async {
  final realm = await _openRealm();
  return realm.all<Car>();
}

Future<Realm> _openRealm() async {
  final config = Configuration.local([Car.schema], schemaVersion: 0);
  return Realm.open(config);
}
