

import 'package:firebase_core/firebase_core.dart';
import 'package:illinois/service/Service.dart';

class FirebaseService extends Service{

  static final FirebaseService _service = FirebaseService._internal();
  FirebaseService._internal();
  factory FirebaseService() {
    return _service;
  }

  @override
  Future<void> initService() async{
    await super.initService();

    await Firebase.initializeApp();
  }

}