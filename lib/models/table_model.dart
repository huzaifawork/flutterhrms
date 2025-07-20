class TableModel {
  final String id;
  final String tableName;
  final String? tableType;
  final int capacity;
  final String status;
  final String? image;
  final String? description;
  final String? location;
  final String? recommendationReason;
  final double? score;
  final int? rank;
  final String? explanation;

  TableModel({
    required this.id,
    required this.tableName,
    this.tableType,
    required this.capacity,
    required this.status,
    this.image,
    this.description,
    this.location,
    this.recommendationReason,
    this.score,
    this.rank,
    this.explanation,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct table data and recommendation wrapper
    final tableData = json['table'] ?? json;
    
    return TableModel(
      id: tableData['_id'] ?? tableData['id'] ?? '',
      tableName: tableData['tableName'] ?? tableData['tableNumber'] ?? '',
      tableType: tableData['tableType'],
      capacity: tableData['capacity'] ?? 0,
      status: tableData['status'] ?? 'Available',
      image: tableData['image'] != null 
          ? (tableData['image'].startsWith('http') 
              ? tableData['image'] 
              : 'http://localhost:8080${tableData['image']}')
          : null,
      description: tableData['description'],
      location: tableData['location'],
      recommendationReason: json['reason'] ?? json['recommendationReason'],
      score: json['score']?.toDouble(),
      rank: json['rank'],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableName': tableName,
      'tableType': tableType,
      'capacity': capacity,
      'status': status,
      'image': image,
      'description': description,
      'location': location,
      'recommendationReason': recommendationReason,
      'score': score,
      'rank': rank,
      'explanation': explanation,
    };
  }

  TableModel copyWith({
    String? id,
    String? tableName,
    String? tableType,
    int? capacity,
    String? status,
    String? image,
    String? description,
    String? location,
    String? recommendationReason,
    double? score,
    int? rank,
    String? explanation,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      tableType: tableType ?? this.tableType,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      image: image ?? this.image,
      description: description ?? this.description,
      location: location ?? this.location,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  String toString() {
    return 'TableModel(id: $id, tableName: $tableName, capacity: $capacity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
