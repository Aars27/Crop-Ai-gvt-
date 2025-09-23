import 'package:cropai/HistoryActivityData/HistoryView.dart';
import 'package:cropai/widget/Constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../Dashboard/dashboard_screen.dart';

class FilterFormPage extends StatefulWidget {
  const FilterFormPage({super.key});

  @override
  _FilterFormPageState createState() => _FilterFormPageState();
}

class _FilterFormPageState extends State<FilterFormPage> {
  
  Map<String, dynamic> filterData = {};
  bool isLoading = true;
  String? error;
  
  // Form controllers and values
  String? selectedLocation;
  String? selectedBlock;
  String? selectedPlot;
  String? selectedActivity;
  DateTime? startDate;
  DateTime? endDate;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchFilterData();
  }

  Future<void> fetchFilterData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      setState(() {
        isLoading = true;
        error = null;
      });
      
      final response = await http.get(
        Uri.parse('${Constanst().base_url}filters'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          filterData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load filter data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

Future<void> submitForm() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (startDate == null || endDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select both start and end dates')),
    );
    return;
  }
  
  final requestBody = {
    "location": selectedLocation,
    "block": selectedBlock,
    "plot": selectedPlot,
    "activity": selectedActivity,
    "dateRange": {
      "start": "${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}",
      "end": "${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}"
    }
  };
  
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

    final response = await http.post(

      Uri.parse('${Constanst().base_url}history'),

      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Parsed Data: $data');
      if (data['data'] != null && data['data']['records'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryPage(historyData: data['data']['records']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No history records found.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history data: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}


 Future<bool> _onWillPop() async {
    // Clear the entire navigation stack and go to dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
    return false; // Prevents default back behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
                    backgroundColor: const Color(0xFF6B8E23) ,
          leading: IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder:
             (context)=>const DashboardScreen()));
          }, icon:const Icon(Icons.arrow_back,color: Colors.white,)),
          title: Text('Farm Management'.tr(),
          style: const TextStyle(color: Colors.white,
           fontSize: 18,
          fontFamily: "Poppins",  fontWeight: FontWeight.bold,),),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: fetchFilterData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Filters'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,fontFamily: "Poppins",
                                color: const Color(0xFF6B8E23),
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            // Location Dropdown
                            buildDropdown<String>(
                              label: 'Location'.tr(),
                                   hintText: 'Select Location'.tr(),
                              value: selectedLocation,
                              items: filterData['locations']?.map<DropdownMenuItem<String>>((location) {
                                return DropdownMenuItem<String>(
                                
                                  value: location,
                                  child: Text(location),
                                );
                              }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  selectedLocation = value;
                                  selectedBlock = null;
                                  selectedPlot = null;
                                });
                              },
                              validator: (value) => value == null ? 'Please select a location' : null,
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Block Dropdown
                            buildDropdown<String>(
                              label: 'Block'.tr(),
                              value: selectedBlock,
                                hintText: 'Select Block'.tr(),
                              items: filterData['blocks']?.map<DropdownMenuItem<String>>((block) {
                                return DropdownMenuItem<String>(
                                  value: block,
                                  child: Text(block),
                                );
                              }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  selectedBlock = value;
                                  selectedPlot = null;
                                });
                              },
                              validator: (value) => value == null ? 'Please select a block' : null,
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Plot Dropdown
                            buildDropdown<String>(
                              label: 'Plot'.tr(),
                              value: selectedPlot,
                                   hintText: 'Select Plot'.tr(),
                              items: filterData['plots']?.map<DropdownMenuItem<String>>((plot) {
                                return DropdownMenuItem<String>(
                                  value: plot,
                                  child: Text(plot),
                                );
                              }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  selectedPlot = value;
                                });
                              },
                              validator: (value) => value == null ? 'Please select a plot' : null,
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Activity Dropdown
                            buildDropdown<String>(
                              label: 'Activity'.tr(),
                              value: selectedActivity,
                              hintText: 'Select Activity'.tr(),
                              items: filterData['activities']?.map<DropdownMenuItem<String>>((activity) {
                                return DropdownMenuItem<String>(
                                  value: activity,
                                  child: Text(activity),
                                
                                );
                              }).toList() ?? [],
                              onChanged: (value) {
                                setState(() {
                                  selectedActivity = value;
                                });
                              },
                              validator: (value) => value == null ? 'Please select an activity' : null,
                            ),
                            
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDateField(
                                    label: 'Start Date'.tr(),
                                    date: startDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: startDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                        
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          startDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: buildDateField(
                                    label: 'End Date'.tr(),
                                    date: endDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: endDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          endDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Submit Button
                            Center(
                              child: SizedBox(
                                width: 200,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B8E23),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'View History'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }


  Widget buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String hintText,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,

          decoration: InputDecoration(
            hintText: hintText,
            label: Text(label),
             labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins",
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade500)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade500)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color :Color(0xFF6B8E23), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(20),
              // color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? "${date.day}/${date.month}/${date.year}"
                      : "Select date",
                  style: TextStyle(
                    color: date != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const Icon(Icons.calendar_today, color: Color(0xFF6B8E23), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
