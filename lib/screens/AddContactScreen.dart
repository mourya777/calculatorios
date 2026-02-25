import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/AppConstants.dart';
import '../utils/StorageService.dart';

class AddContactScreen extends StatefulWidget {
  @override
  _AddContactScreenState createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add Contact',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 4-digit ID Field
              TextFormField(
                controller: _idController,
                style: TextStyle(color: Colors.white, fontSize: 24),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: 'Enter 4-digit ID',
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  prefixIcon: Icon(Icons.qr_code, color: AppConstants.accentColor, size: 30),
                  helperText: 'Enter the 4-digit ID of the person you want to add',
                  helperStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstants.accentColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ID';
                  }
                  if (value.length != 4) {
                    return 'ID must be 4 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),

              // Add Button
              ElevatedButton(
                onPressed: _isLoading ? null : _addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentColor,
                  minimumSize: Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'ADD CONTACT',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String contactId = _idController.text.trim();

        bool added = await StorageService.addContact(contactId);

        if (added) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          String myId = await StorageService.getMyId();
          String message = contactId == myId
              ? 'You cannot add your own ID'
              : 'This ID already exists in your contacts';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }
}