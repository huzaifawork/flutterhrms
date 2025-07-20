class StaffModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String position;
  final String department;
  final DateTime joiningDate;
  final double salary;
  final String? profileImageUrl;
  final bool isActive;
  final List<String>? skills;
  final Map<String, dynamic>? schedule;
  final Map<String, dynamic>? performance;
  final String? address;
  final String? emergencyContact;

  StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.position,
    required this.department,
    required this.joiningDate,
    required this.salary,
    this.profileImageUrl,
    this.isActive = true,
    this.skills,
    this.schedule,
    this.performance,
    this.address,
    this.emergencyContact,
  });

  // Create a staff member from JSON data
  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      position: json['position'] as String,
      department: json['department'] as String,
      joiningDate: DateTime.parse(json['joiningDate'] as String),
      salary: (json['salary'] as num).toDouble(),
      profileImageUrl: json['profileImageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      skills: json['skills'] != null
          ? List<String>.from(json['skills'] as List)
          : null,
      schedule: json['schedule'] as Map<String, dynamic>?,
      performance: json['performance'] as Map<String, dynamic>?,
      address: json['address'] as String?,
      emergencyContact: json['emergencyContact'] as String?,
    );
  }

  // Convert staff member to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'position': position,
      'department': department,
      'joiningDate': joiningDate.toIso8601String(),
      'salary': salary,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'skills': skills,
      'schedule': schedule,
      'performance': performance,
      'address': address,
      'emergencyContact': emergencyContact,
    };
  }

  // Create a copy of the staff member with updated fields
  StaffModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? position,
    String? department,
    DateTime? joiningDate,
    double? salary,
    String? profileImageUrl,
    bool? isActive,
    List<String>? skills,
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? performance,
    String? address,
    String? emergencyContact,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      position: position ?? this.position,
      department: department ?? this.department,
      joiningDate: joiningDate ?? this.joiningDate,
      salary: salary ?? this.salary,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      skills: skills ?? this.skills,
      schedule: schedule ?? this.schedule,
      performance: performance ?? this.performance,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  // Calculate years of service
  int get yearsOfService {
    final now = DateTime.now();
    int years = now.year - joiningDate.year;
    if (now.month < joiningDate.month ||
        (now.month == joiningDate.month && now.day < joiningDate.day)) {
      years--;
    }
    return years;
  }

  // Create a list of dummy staff members for testing
  static List<StaffModel> dummyStaff() {
    return [
      StaffModel(
        id: '1',
        name: 'John Smith',
        email: 'john.smith@hrms.com',
        phoneNumber: '+1234567890',
        position: 'Hotel Manager',
        department: 'Management',
        joiningDate: DateTime(2018, 5, 15),
        salary: 75000.00,
        profileImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        isActive: true,
        skills: ['Leadership', 'Customer Service', 'Team Management', 'Budgeting'],
        schedule: {
          'monday': {'start': '09:00', 'end': '18:00'},
          'tuesday': {'start': '09:00', 'end': '18:00'},
          'wednesday': {'start': '09:00', 'end': '18:00'},
          'thursday': {'start': '09:00', 'end': '18:00'},
          'friday': {'start': '09:00', 'end': '18:00'},
        },
        performance: {
          'rating': 4.8,
          'reviews': 12,
          'lastReview': '2023-01-15',
        },
        address: '123 Main St, New York, NY 10001',
        emergencyContact: 'Jane Smith, +1987654321',
      ),
      StaffModel(
        id: '2',
        name: 'Emily Johnson',
        email: 'emily.johnson@hrms.com',
        phoneNumber: '+1234567891',
        position: 'Front Desk Supervisor',
        department: 'Front Office',
        joiningDate: DateTime(2019, 8, 10),
        salary: 45000.00,
        profileImageUrl: 'https://randomuser.me/api/portraits/women/1.jpg',
        isActive: true,
        skills: ['Customer Service', 'Reservation Management', 'Problem Solving'],
        schedule: {
          'monday': {'start': '07:00', 'end': '16:00'},
          'tuesday': {'start': '07:00', 'end': '16:00'},
          'wednesday': {'start': '07:00', 'end': '16:00'},
          'thursday': {'start': '07:00', 'end': '16:00'},
          'friday': {'start': '07:00', 'end': '16:00'},
        },
        performance: {
          'rating': 4.5,
          'reviews': 8,
          'lastReview': '2023-02-20',
        },
        address: '456 Park Ave, New York, NY 10002',
        emergencyContact: 'Michael Johnson, +1987654322',
      ),
      StaffModel(
        id: '3',
        name: 'Robert Davis',
        email: 'robert.davis@hrms.com',
        phoneNumber: '+1234567892',
        position: 'Executive Chef',
        department: 'Food & Beverage',
        joiningDate: DateTime(2017, 3, 22),
        salary: 65000.00,
        profileImageUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
        isActive: true,
        skills: ['Culinary Arts', 'Menu Planning', 'Kitchen Management', 'Food Safety'],
        schedule: {
          'tuesday': {'start': '10:00', 'end': '19:00'},
          'wednesday': {'start': '10:00', 'end': '19:00'},
          'thursday': {'start': '10:00', 'end': '19:00'},
          'friday': {'start': '10:00', 'end': '19:00'},
          'saturday': {'start': '10:00', 'end': '19:00'},
        },
        performance: {
          'rating': 4.9,
          'reviews': 15,
          'lastReview': '2023-01-05',
        },
        address: '789 Broadway, New York, NY 10003',
        emergencyContact: 'Sarah Davis, +1987654323',
      ),
      StaffModel(
        id: '4',
        name: 'Jennifer Wilson',
        email: 'jennifer.wilson@hrms.com',
        phoneNumber: '+1234567893',
        position: 'Housekeeping Supervisor',
        department: 'Housekeeping',
        joiningDate: DateTime(2020, 1, 5),
        salary: 40000.00,
        profileImageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
        isActive: true,
        skills: ['Cleaning Standards', 'Team Management', 'Inventory Management'],
        schedule: {
          'monday': {'start': '06:00', 'end': '15:00'},
          'tuesday': {'start': '06:00', 'end': '15:00'},
          'wednesday': {'start': '06:00', 'end': '15:00'},
          'thursday': {'start': '06:00', 'end': '15:00'},
          'friday': {'start': '06:00', 'end': '15:00'},
        },
        performance: {
          'rating': 4.2,
          'reviews': 6,
          'lastReview': '2023-03-10',
        },
        address: '101 Lexington Ave, New York, NY 10004',
        emergencyContact: 'Thomas Wilson, +1987654324',
      ),
      StaffModel(
        id: '5',
        name: 'Michael Brown',
        email: 'michael.brown@hrms.com',
        phoneNumber: '+1234567894',
        position: 'Maintenance Technician',
        department: 'Maintenance',
        joiningDate: DateTime(2019, 6, 15),
        salary: 42000.00,
        profileImageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
        isActive: false,
        skills: ['Electrical Systems', 'Plumbing', 'HVAC', 'General Repairs'],
        schedule: {
          'monday': {'start': '08:00', 'end': '17:00'},
          'tuesday': {'start': '08:00', 'end': '17:00'},
          'wednesday': {'start': '08:00', 'end': '17:00'},
          'thursday': {'start': '08:00', 'end': '17:00'},
          'friday': {'start': '08:00', 'end': '17:00'},
        },
        performance: {
          'rating': 4.0,
          'reviews': 7,
          'lastReview': '2022-12-15',
        },
        address: '202 5th Ave, New York, NY 10005',
        emergencyContact: 'Lisa Brown, +1987654325',
      ),
    ];
  }
} 