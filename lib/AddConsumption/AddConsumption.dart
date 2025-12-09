import 'package:flutter/material.dart';

class DieselConsumptionScreen extends StatefulWidget {
  const DieselConsumptionScreen({super.key});

  @override
  State<DieselConsumptionScreen> createState() => _DieselConsumptionScreenState();
}

class _DieselConsumptionScreenState extends State<DieselConsumptionScreen> {
  final TextEditingController blockCtrl = TextEditingController();
  final TextEditingController plotCtrl = TextEditingController();
  final TextEditingController areaCtrl = TextEditingController();
  final TextEditingController levelingCtrl = TextEditingController();

  @override


  Future<bool> _onWillPop() async {
    // Navigate to dashboard screen when back button is pressed
    Navigator.pushReplacementNamed(context, '/dashboard');
    return false; // Prevents default back behavior
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
                  onPressed: () => Navigator.pop(context),
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
                  label: "Block Name *",
                  hint: "Select Block",
                  controller: blockCtrl,
                ),

                const SizedBox(height: 18),

                _buildField(
                  label: "Plot Name *",
                  hint: "Select Plot",
                  controller: plotCtrl,
                ),

                const SizedBox(height: 18),

                _buildField(
                  label: "Area (Acre)",
                  hint: "Total Area",
                  controller: areaCtrl,
                  readOnly: true,
                ),

                const SizedBox(height: 18),

                _buildField(
                  label: "Area Leveling (Acre) *",
                  hint: "Enter Area Leveling",
                  controller: levelingCtrl,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 25),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
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
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
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
