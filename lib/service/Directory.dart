
import 'package:illinois/model/Directory.dart';

class Directory {

  // Singleton Factory

  static final Directory _instance = Directory._internal();
  factory Directory() => _instance;
  Directory._internal();

  Future<List<DirectoryMember>?> loadMembers() async {
    await Future.delayed(Duration(milliseconds: 1500));

    List<String> manPhotos = <String>[
      'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/842980/pexels-photo-842980.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/262391/pexels-photo-262391.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/25758/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
    ];

    List<String> womanPhotos = <String>[
      'https://images.pexels.com/photos/1239288/pexels-photo-1239288.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/1102341/pexels-photo-1102341.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/3541389/pexels-photo-3541389.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/1855582/pexels-photo-1855582.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
      'https://images.pexels.com/photos/2681751/pexels-photo-2681751.jpeg?auto=compress&cs=tinysrgb&w=250&h=150&dpr=2',
    ];

    return <DirectoryMember>[
      DirectoryMember(id:  '1', netId: '', firstName: 'James',      lastName: 'Smith',     pronoun: 'he',  college: 'Academic Affairs', department: 'Campus Honors Program',       email: 'james@illinois.edu',    website: 'linkedin.com/james',    photoUrl: manPhotos[0]),
      DirectoryMember(id:  '2', netId: '', firstName: 'Mary',       lastName: 'Johnson',   pronoun: 'she', college: 'Chancellor',       department: 'Academic Human Resources',    email: 'mary@illinois.edu',     website: 'linkedin.com/mary',     photoUrl: womanPhotos[0]),
      DirectoryMember(id:  '3', netId: '', firstName: 'Michael',    lastName: 'Williams',  pronoun: 'he',  college: 'Armed Forces',     department: 'Air Force Aerospace Studies', email: 'michael@illinois.edu',  website: 'linkedin.com/michael',  photoUrl: manPhotos[1]),
      DirectoryMember(id:  '4', netId: '', firstName: 'Patricia',   lastName: 'Brown',     pronoun: 'she', college: 'Education',        department: 'Curriculum and Instruction',  email: 'patricia@illinois.edu', website: 'linkedin.com/patricia', photoUrl: womanPhotos[1]),
      DirectoryMember(id:  '5', netId: '', firstName: 'Robert',     lastName: 'Jones',     pronoun: 'he',  college: 'Law',              department: 'Law Library',                 email: 'robert@illinois.edu',   website: 'linkedin.com/robert',   photoUrl: manPhotos[2]),
      DirectoryMember(id:  '6', netId: '', firstName: 'Jennifer',   lastName: 'Garcia',    pronoun: 'she', college: 'Academic Affairs', department: 'Office of the Registrar',     email: 'jennifer@illinois.edu', website: 'linkedin.com/jennifer', photoUrl: womanPhotos[2]),
      DirectoryMember(id:  '7', netId: '', firstName: 'John',       lastName: 'Miller',    pronoun: 'he',  college: 'Public Safety',    department: 'Fire Service Institute',      email: 'john@illinois.edu',     website: 'linkedin.com/john',     photoUrl: manPhotos[3]),
      DirectoryMember(id:  '8', netId: '', firstName: 'Linda',      lastName: 'Davis',     pronoun: 'she', college: 'Chancellor',       department: 'Illinois Human Resources',    email: 'linda@illinois.edu',    website: 'linkedin.com/linda',    photoUrl: womanPhotos[3]),
      DirectoryMember(id:  '9', netId: '', firstName: 'David',      lastName: 'Rodriguez', pronoun: 'he',  college: 'Education',        department: 'Education Administration',    email: 'david@illinois.edu',    website: 'linkedin.com/david',    photoUrl: manPhotos[4]),
      DirectoryMember(id: '10', netId: '', firstName: 'Elizabeth',  lastName: 'Martinez',  pronoun: 'she', college: 'Armed Forces',     department: 'Military Science',            email: 'lizbeth@illinois.edu',  website: 'linkedin.com/lizbeth',  photoUrl: womanPhotos[4]),
      DirectoryMember(id: '11', netId: '', firstName: 'William',    lastName: 'Hernandez', pronoun: 'he',  college: 'Law',              department: 'Law',                         email: 'william@illinois.edu',  website: 'linkedin.com/william',  photoUrl: manPhotos[0]),
      DirectoryMember(id: '12', netId: '', firstName: 'Barbara',    lastName: 'Lopez',     pronoun: 'she', college: 'Public Safety',    department: 'Police Training Institute',   email: 'barbara@illinois.edu',  website: 'linkedin.com/barbara',  photoUrl: womanPhotos[0]),
      DirectoryMember(id: '13', netId: '', firstName: 'Richard',    lastName: 'Gonzalez',  pronoun: 'he',  college: 'Academic Affairs', department: 'Campus Honors Program',       email: 'richard@illinois.edu',  website: 'linkedin.com/richard',  photoUrl: manPhotos[1]),
      DirectoryMember(id: '14', netId: '', firstName: 'Susan',      lastName: 'Wilson',    pronoun: 'she', college: 'Student Affairs',  department: 'Counseling Center',           email: 'susan@illinois.edu',    website: 'linkedin.com/susan',    photoUrl: womanPhotos[1]),
      DirectoryMember(id: '15', netId: '', firstName: 'Joseph',     lastName: 'Anderson',  pronoun: 'he',  college: 'Chancellor',       department: 'Academic Human Resources',    email: 'joseph@illinois.edu',   website: 'linkedin.com/joseph',   photoUrl: manPhotos[2]),
      DirectoryMember(id: '16', netId: '', firstName: 'Jessica',    lastName: 'Thomas',    pronoun: 'she', college: 'Education',        department: 'Special Education',           email: 'jessica@illinois.edu',  website: 'linkedin.com/jessica',  photoUrl: womanPhotos[2]),
      DirectoryMember(id: '17', netId: '', firstName: 'Thomas',     lastName: 'Taylor',    pronoun: 'he',  college: 'Armed Forces',     department: 'Naval Science',               email: 'thomas@illinois.edu',   website: 'linkedin.com/thomas',   photoUrl: manPhotos[3]),
      DirectoryMember(id: '18', netId: '', firstName: 'Karen',      lastName: 'Moore',     pronoun: 'she', college: 'Public Safety',    department: 'Fire Service Institute',      email: 'karen@illinois.edu',    website: 'linkedin.com/karen',    photoUrl: womanPhotos[3]),
      DirectoryMember(id: '19', netId: '', firstName: 'Christopher',lastName: 'Jackson',   pronoun: 'he',  college: 'Law',              department: 'Law Library',                 email: 'christ@illinois.edu',   website: 'linkedin.com/christ',   photoUrl: manPhotos[3]),
      DirectoryMember(id: '20', netId: '', firstName: 'Sarah',      lastName: 'Martin',    pronoun: 'she', college: 'Education',        department: 'Curriculum and Instruction',  email: 'sarah@illinois.edu',    website: 'linkedin.com/sarah',    photoUrl: womanPhotos[4]),
      DirectoryMember(id: '21', netId: '', firstName: 'Charles',    lastName: 'Lee',       pronoun: 'he',  college: 'Academic Affairs', department: 'Principal\'s Scholars Pgm',   email: 'charles@illinois.edu',  website: 'linkedin.com/charles',  photoUrl: manPhotos[0]),
      DirectoryMember(id: '22', netId: '', firstName: 'Lisa',       lastName: 'Perez',     pronoun: 'she', college: 'Chancellor',       department: 'Illinois Human Resources',    email: 'lisa@illinois.edu',     website: 'linkedin.com/lisa',     photoUrl: womanPhotos[0]),
      DirectoryMember(id: '23', netId: '', firstName: 'Daniel',     lastName: 'Thompson',  pronoun: 'he',  college: 'Law',              department: 'Law',                         email: 'daniel@illinois.edu',   website: 'linkedin.com/daniel',   photoUrl: manPhotos[1]),
      DirectoryMember(id: '24', netId: '', firstName: 'Nancy',      lastName: 'White',     pronoun: 'she', college: 'Armed Forces',     department: 'Military Science',            email: 'nancy@illinois.edu',    website: 'linkedin.com/nancy',    photoUrl: womanPhotos[1]),
      DirectoryMember(id: '25', netId: '', firstName: 'Matthew',    lastName: 'Harris',    pronoun: 'he',  college: 'Education',        department: 'Education Administration',    email: 'matthew@illinois.edu',  website: 'linkedin.com/matthew',  photoUrl: manPhotos[2]),
      DirectoryMember(id: '26', netId: '', firstName: 'Sandra',     lastName: 'Sanchez',   pronoun: 'she', college: 'Public Safety',    department: 'Police Training Institute',   email: 'sandra@illinois.edu',   website: 'linkedin.com/sandra',   photoUrl: womanPhotos[2]),
      DirectoryMember(id: '27', netId: '', firstName: 'Anthony',    lastName: 'Clark',     pronoun: 'he',  college: 'Academic Affairs', department: 'Office of the Registrar',     email: 'anthony@illinois.edu',  website: 'linkedin.com/anthony',  photoUrl: manPhotos[3]),
      DirectoryMember(id: '28', netId: '', firstName: 'Betty',      lastName: 'Ramirez',   pronoun: 'she', college: 'Student Affairs',  department: 'Campus Recreation',           email: 'betty@illinois.edu',    website: 'linkedin.com/betty',    photoUrl: womanPhotos[3]),
      DirectoryMember(id: '29', netId: '', firstName: 'Mark',       lastName: 'Lewis',     pronoun: 'he',  college: 'Chancellor',       department: 'News Bureau',                 email: 'mark@illinois.edu',     website: 'linkedin.com/mark',     photoUrl: manPhotos[3]),
      DirectoryMember(id: '30', netId: '', firstName: 'Ashley',     lastName: 'Robinson',  pronoun: 'she', college: 'Armed Forces',     department: 'Clinical Sciences',           email: 'ashley@illinois.edu',   website: 'linkedin.com/ashley',   photoUrl: womanPhotos[4]),
      DirectoryMember(id: '31', netId: '', firstName: 'Donald',     lastName: 'Walker',    pronoun: 'he',  college: 'Education',        department: 'Special Education',           email: 'donald@illinois.edu',   website: 'linkedin.com/donald',   photoUrl: manPhotos[0]),
      DirectoryMember(id: '32', netId: '', firstName: 'Emily',      lastName: 'Allenb',    pronoun: 'she', college: 'Student Affairs',  department: 'Counseling Center',           email: 'emily@illinois.edu',    website: 'linkedin.com/emily',    photoUrl: womanPhotos[0]),
      DirectoryMember(id: '33', netId: '', firstName: 'Steven',     lastName: 'King',      pronoun: 'he',  college: 'Academic Affairs', department: 'Principal\'s Scholars Pgm',   email: 'steven@illinois.edu',   website: 'linkedin.com/steven',   photoUrl: manPhotos[1]),
      DirectoryMember(id: '34', netId: '', firstName: 'Kimberly',   lastName: 'Wright',    pronoun: 'she', college: 'Law',              department: 'Law',                         email: 'kimberly@illinois.edu', website: 'linkedin.com/kimberly', photoUrl: womanPhotos[1]),
      DirectoryMember(id: '35', netId: '', firstName: 'Andrew',     lastName: 'Scott',     pronoun: 'he',  college: 'Public Safety',    department: 'Police Training Institute',   email: 'andrew@illinois.edu',   website: 'linkedin.com/andrew',   photoUrl: manPhotos[2]),
      DirectoryMember(id: '36', netId: '', firstName: 'Margaret',   lastName: 'Torres',    pronoun: 'she', college: 'Armed Forces',     department: 'Naval Science',               email: 'margaret@illinois.edu', website: 'linkedin.com/margaret', photoUrl: womanPhotos[2]),
      DirectoryMember(id: '37', netId: '', firstName: 'Paul',       lastName: 'Nguyen',    pronoun: 'he',  college: 'Education',        department: 'Education Administration',    email: 'paul@illinois.edu',     website: 'linkedin.com/paul',     photoUrl: manPhotos[3]),
      DirectoryMember(id: '38', netId: '', firstName: 'Donna',      lastName: 'Hill',      pronoun: 'she', college: 'Chancellor',       department: 'News Bureau',                 email: 'dona@illinois.edu',     website: 'linkedin.com/dona',     photoUrl: womanPhotos[3]),
      DirectoryMember(id: '39', netId: '', firstName: 'Joshua',     lastName: 'Flores',    pronoun: 'he',  college: 'Academic Affairs', department: 'Provost/VCAA Admin',          email: 'joshua@illinois.edu',   website: 'linkedin.com/joshua',   photoUrl: manPhotos[3]),
      DirectoryMember(id: '40', netId: '', firstName: 'Michelle',   lastName: 'Green',     pronoun: 'she', college: 'Law',              department: 'Law Library',                 email: 'michelle@illinois.edu', website: 'linkedin.com/michelle', photoUrl: womanPhotos[4]),
    ];
  }

}