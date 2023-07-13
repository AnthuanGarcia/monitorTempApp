import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  Item({
    required this.data,
    this.isExpanded = false,
  });

  QueryDocumentSnapshot<Map<String, dynamic>> data;
  bool isExpanded;
}
