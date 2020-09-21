import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:biometric_storage/biometric_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

var encryptedBox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for biometric_storage

  BiometricStorageFile storageFile;

  storageFile = await BiometricStorage().getStorage('box_key',
      options: StorageFileInitOptions(
        authenticationRequired: false,
      ));

  String rawKey = await storageFile.read();
  Uint8List boxKey;

  if (rawKey == null) {
    print('rawKey is null - generating and saving');
    boxKey = Hive.generateSecureKey();
    print('boxKey: ' + boxKey.toString());
    await storageFile.write(base64Encode(boxKey));
  } else {
    print('rawKey: $rawKey \nRetrieving and converting to Uint8List');
    boxKey = base64Decode(rawKey);
    print('boxKey: ' + boxKey.toString());
  }

  await Hive.initFlutter();
  encryptedBox = await Hive.openBox('vaultBox', encryptionKey: boxKey);
  encryptedBox.put('secret', 'Hive is cool');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Hive Key',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Secure Hive Key'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('vaultBox').listenable(),
        builder: (context, box, widget) {
          return Center(
            child: Text(
              encryptedBox.get('secret', defaultValue: 'Retrieving from box'),
            ),
          );
        },
      ),
    );
  }
}
