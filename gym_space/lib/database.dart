import 'package:firebase_core/firebase_core.dart';
import 'package:algolia/algolia.dart';

class DatabaseConnections {
  static Algolia algolia;
  
  static const FirebaseOptions database = FirebaseOptions(
    googleAppID: '1:936699691309:android:3aeae822367bc185',
    apiKey: 'AIzaSyD-Q_wLERYdlEBK97oe3qdHz7BVGMRKxFY',
    projectID: 'gymspace',
  );

  static const Algolia initAlgolia = Algolia.init(
    applicationId: 'OJPIPHPPII',
    apiKey: 'cbde1bad367edaaa76232736fc702cff',
  );
}