import 'dart:convert';

import 'package:cropai/Dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DieselConsumptionScreen extends StatefulWidget {
  const DieselConsumptionScreen({super.key});

  @override
  State<DieselConsumptionScreen> createState() => _DieselConsumptionScreenState();
}

class _DieselConsumptionScreenState extends State<DieselConsumptionScreen> {
  final TextEditingController diselConsumption = TextEditingController();
  final TextEditingController Date = TextEditingController();
  final TextEditingController Remark = TextEditingController();




  @override
  Future<bool> _onWillPop() async {
    // Navigate to dashboard screen when back button is pressed
    Navigator.pushReplacementNamed(context, '/dashboard');
    return false; // Prevents default back behavior
  }


  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      Date.text =
      "${d.year}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}";
    }
  }



  Future<void> submitDiesel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      print('No token');
      return;
    }

    final url = Uri.parse(
        'https://ccbfsolution.pmmsapp.com/api/diesel-consumption');

    final body = {
      'diesel_consumption': double.tryParse(diselConsumption.text) ?? 0,
      'date_of_entry': Date.text,
      'remark': Remark.text
    };

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {

      Fluttertoast.showToast(msg: 'Successfully Submited',
      backgroundColor: Colors.green,
        textColor: Colors.white

      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> DashboardScreen()));


    } else {
      print('Error ${res.statusCode}  ${res.body}');
    }
  }



  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Connect to the back button handler
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: const Color(0xFF6B8E23),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> DashboardScreen()));
                  }
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 15),
                  title: const Text(
                    "Diesel Consumption",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 40),
                    child: Image.asset(
                      "assets/images/circle_logo.png",
                      width: 90,
                      height: 60,
                    ),
                  ),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
            ];
          },
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(
                  label: "Disel Consumption *",
                  hint: "Disel Consumption",
                  controller: diselConsumption,
                ),

                const SizedBox(height: 18),

                _buildField(
                  label: "Select Date *",
                  hint: "Select Date",
                  controller: Date,
                  readOnly: true,
                  onTap: pickDate,
                ),


                const SizedBox(height: 18),

                _buildField(
                  label: "Remark/Activity",
                  hint: "Remark",
                  controller: Remark,
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: submitDiesel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B8E23),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          color: Color(0xFF6B8E23),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
        ),
      ),
    );
  }

}
