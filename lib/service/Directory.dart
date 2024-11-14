
import 'package:illinois/model/Directory.dart';

class Directory {

  // Singleton Factory

  static final Directory _instance = Directory._internal();
  factory Directory() => _instance;
  Directory._internal();

  Future<List<DirectoryMember>?> loadMembers() async {
    await Future.delayed(Duration(milliseconds: 1500));
    return <DirectoryMember>[
      DirectoryMember(id: '', netId: '', firstName: 'James', lastName: 'Smith'),
      DirectoryMember(id: '', netId: '', firstName: 'Mary', lastName: 'Johnson'),
      DirectoryMember(id: '', netId: '', firstName: 'Michael', lastName: 'Williams'),
      DirectoryMember(id: '', netId: '', firstName: 'Patricia', lastName: 'Brown'),
      DirectoryMember(id: '', netId: '', firstName: 'Robert', lastName: 'Jones'),
      DirectoryMember(id: '', netId: '', firstName: 'Jennifer', lastName: 'Garcia'),
      DirectoryMember(id: '', netId: '', firstName: 'John', lastName: 'Miller'),
      DirectoryMember(id: '', netId: '', firstName: 'Linda', lastName: 'Davis'),
      DirectoryMember(id: '', netId: '', firstName: 'David', lastName: 'Rodriguez'),
      DirectoryMember(id: '', netId: '', firstName: 'Elizabeth', lastName: 'Martinez'),
      DirectoryMember(id: '', netId: '', firstName: 'William', lastName: 'Hernandez'),
      DirectoryMember(id: '', netId: '', firstName: 'Barbara', lastName: 'Lopez'),
      DirectoryMember(id: '', netId: '', firstName: 'Richard', lastName: 'Gonzalez'),
      DirectoryMember(id: '', netId: '', firstName: 'Susan', lastName: 'Wilson'),
      DirectoryMember(id: '', netId: '', firstName: 'Joseph', lastName: 'Anderson'),
      DirectoryMember(id: '', netId: '', firstName: 'Jessica', lastName: 'Thomas'),
      DirectoryMember(id: '', netId: '', firstName: 'Thomas', lastName: 'Taylor'),
      DirectoryMember(id: '', netId: '', firstName: 'Karen', lastName: 'Moore'),
      DirectoryMember(id: '', netId: '', firstName: 'Christopher', lastName: 'Jackson'),
      DirectoryMember(id: '', netId: '', firstName: 'Sarah', lastName: 'Martin'),
      DirectoryMember(id: '', netId: '', firstName: 'Charles', lastName: 'Lee'),
      DirectoryMember(id: '', netId: '', firstName: 'Lisa', lastName: 'Perez'),
      DirectoryMember(id: '', netId: '', firstName: 'Daniel', lastName: 'Thompson'),
      DirectoryMember(id: '', netId: '', firstName: 'Nancy', lastName: 'White'),
      DirectoryMember(id: '', netId: '', firstName: 'Matthew', lastName: 'Harris'),
      DirectoryMember(id: '', netId: '', firstName: 'Sandra', lastName: 'Sanchez'),
      DirectoryMember(id: '', netId: '', firstName: 'Anthony', lastName: 'Clark'),
      DirectoryMember(id: '', netId: '', firstName: 'Betty', lastName: 'Ramirez'),
      DirectoryMember(id: '', netId: '', firstName: 'Mark', lastName: 'Lewis'),
      DirectoryMember(id: '', netId: '', firstName: 'Ashley', lastName: 'Robinson'),
      DirectoryMember(id: '', netId: '', firstName: 'Donald', lastName: 'Walker'),
      DirectoryMember(id: '', netId: '', firstName: 'Emily', lastName: 'Allenb'),
      DirectoryMember(id: '', netId: '', firstName: 'Steven', lastName: 'King'),
      DirectoryMember(id: '', netId: '', firstName: 'Kimberly', lastName: 'Wright'),
      DirectoryMember(id: '', netId: '', firstName: 'Andrew', lastName: 'Scott'),
      DirectoryMember(id: '', netId: '', firstName: 'Margaret', lastName: 'Torres'),
      DirectoryMember(id: '', netId: '', firstName: 'Paul', lastName: 'Nguyen'),
      DirectoryMember(id: '', netId: '', firstName: 'Donna', lastName: 'Hill'),
      DirectoryMember(id: '', netId: '', firstName: 'Joshua', lastName: 'Flores'),
      DirectoryMember(id: '', netId: '', firstName: 'Michelle', lastName: 'Green'),
    ];
  }

}