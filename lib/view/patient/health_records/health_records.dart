import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class PatientHealthRecordsPage extends StatefulWidget {
  @override
  _PatientHealthRecordsPageState createState() => _PatientHealthRecordsPageState();
}

class _PatientHealthRecordsPageState extends State<PatientHealthRecordsPage> {
  List<HealthRecord> records = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Health Records'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewRecord,
          ),
        ],
      ),
      body: records.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: 50, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No health records yet',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add a new record',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _buildRecordCard(records[index]);
        },
      ),
    );
  }

  Widget _buildRecordCard(HealthRecord record) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(record.imagePath),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Recommended by: ${record.doctorName}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(record.date),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ]),
                  ),
                ],
              ),
              if (record.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  record.description.length > 50
                      ? '${record.description.substring(0, 50)}...'
                      : record.description,
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addNewRecord() async {
    final image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecordScreen(imagePath: image.path),
      ),
    );

    if (result != null) {
      setState(() {
        records.add(result);
      });
    }
  }

  void _showRecordDetails(HealthRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(record.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(record.imagePath)),
                SizedBox(height: 16),
                Text(
                  'Recommended by: ${record.doctorName}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(record.date)}',
                ),
                SizedBox(height: 16),
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(record.description),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class AddRecordScreen extends StatefulWidget {
  final String imagePath;

  AddRecordScreen({required this.imagePath});

  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title = 'Prescription';
  late String _doctorName = '';
  late String _description = '';
  final DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Health Record'),
        actions: [
          TextButton(
            onPressed: _saveRecord,
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Record Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _title = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Doctor Name',
                  border: OutlineInputBorder(),
                  hintText: 'Dr. Smith',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter doctor name';
                  }
                  return null;
                },
                onChanged: (value) => _doctorName = value,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter details about this record',
                ),
                maxLines: 3,
                onChanged: (value) => _description = value,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_date),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        HealthRecord(
          imagePath: widget.imagePath,
          title: _title,
          doctorName: _doctorName,
          description: _description,
          date: _date,
        ),
      );
    }
  }
}

class HealthRecord {
  final String imagePath;
  final String title;
  final String doctorName;
  final String description;
  final DateTime date;

  HealthRecord({
    required this.imagePath,
    required this.title,
    required this.doctorName,
    required this.description,
    required this.date,
  });
}