// import 'dart:convert';
// import 'dart:io';
//
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Add this import for input formatters
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../Dashboard/dashboard_screen.dart';
// import '../widget/Constants.dart';
//
// class Arealevelingscreen extends StatefulWidget {
//   const Arealevelingscreen({super.key});
//
//   @override
//   State<Arealevelingscreen> createState() => ArealevelingPreperation();
// }
//
// class ArealevelingPreperation extends State<Arealevelingscreen> {
//   // Form Key
//   final _formKey = GlobalKey<FormState>();
//   String _areaText = '';
//
//   // Text Controllers
//   final TextEditingController _fuelConsumptionController =
//       TextEditingController();
//   final TextEditingController _levelingController = TextEditingController();
//   final TextEditingController _HSD_Consuption_Controller =
//       TextEditingController();
//   List<Map<String, TextEditingController>> _sparePartsControllers = [];
//
//   // Focus nodes to track focus state
//   final _levelingFocusNode = FocusNode();
//   final _majorMaintenanceFocusNode = FocusNode();
//   final _HSD_FocusNode = FocusNode();
//
//   // Dropdown Values with default options
//   final String _selectedSiteName = 'Select Site';
//   String? _selectedBlockName = 'Select Block'.tr();
//   String? _selectedPlotName = 'Select Plot'.tr();
//
//   List<String> _blockNames = ['Select Block'];
//   List<String> _plotNames = ['Select Plot'];
//
//   // final String _selectedAreaName = 'Select Area';
//
//   String? _selectedManPowerRoll = 'Select Man Power';
//   String? _selectedLandQuality = 'Select Land Quality';
//
//   int? _selectedBlockId;
//   int? _selectedPlotId;
//   double? _selectedArea;
//
//   final String _selectedTractor = 'Select Tractor';
//   Set<String> selectedTractors = {};
//   List<String> _tractorName = ['Select Tractor'];
//
//   bool showTractorDropdown = false;
//   final TextEditingController _tractorSearchController =
//       TextEditingController();
//   List<String> _filteredTractorNames = [];
//
//   // final String _selectedMachine = 'Select Machine';
//   Set<String> selectedMachines = {};
//   List<String> _machineName = ['Select Machine'];
//   bool showMachineDropdown = false;
//   final TextEditingController _machineSearchController =
//       TextEditingController();
//   List<String> _filteredMachineNames = [];
//
//   List<Map<String, dynamic>> _machines = []; // Store full machine data
//   final List<Map<String, dynamic>> _tractors = []; // Store full tractor data
//
//
//   DateTime? _startDate = DateTime.now();
//   TimeOfDay? _startTime = TimeOfDay.now();
//   TimeOfDay? _endTime =
//       TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 4)));
//
//   // API Data
//   final List<Map<String, dynamic>> _sites = [];
//   List<Map<String, dynamic>> _blocks = [];
//   List<Map<String, dynamic>> _plots = [];
//
//   // Lists for dropdown items
//   final List<String> _siteNames = ['Select Site'];
//
//   final List<String> _areaOptions = ['Select Area'];
//
//   List<String> _manpowerTypeNames = ['Select Man Power'];
//
//   final List<Map<String, dynamic>> _manpowerTypes = [];
//   final Map<String, List<Map<String, dynamic>>> _categoriesByType = {};
//
//   bool _isLoading = true;
//
//   bool showCheckboxes = false;
//   bool isLoading = true;
//
//   List<String> categories = [];
//   Set<String> selectedCategories = {};
//   Map<String, TextEditingController> controllers = {};
//   Map<String, FocusNode> focusNodes = {};
// // Map to store the relationship between display names and original API category names
//   Map<String, String> categoryMapping = {};
// // List to store display category names
//   List<String> displayCategories = [];
//
//   Future<bool> _onWillPop() async {
//     // Clear the entire navigation stack and go to dashboard
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const DashboardScreen()),
//     );
//     return false; // Prevents default back behavior
//   }
//
//   @override
//   void initState() {
//     super.initState();
//
//     for (var controllerMap in _sparePartsControllers) {
//       controllerMap['part']?.clear();
//       controllerMap['value']?.clear();
//     }
//
//     if (_sparePartsControllers.isNotEmpty) {
//       final firstController = _sparePartsControllers.first;
//       for (int i = 1; i < _sparePartsControllers.length; i++) {
//         _sparePartsControllers[i]['part']?.dispose();
//         _sparePartsControllers[i]['value']?.dispose();
//       }
//       _sparePartsControllers = [firstController];
//     }
//
//     _fetchBlocksAndPlots();
//     _fetchTractorDetails();
//     _machineName = ['Select Machine'];
//     _fetchMachineDetails();
//
//     // Call the manpower categories API
//     fetchCategories();
//
//     _levelingFocusNode.addListener(() {
//       setState(() {});
//     });
//   }
//
//   void _addNewSparePart() {
//     setState(() {
//       _sparePartsControllers.add({
//         'part': TextEditingController(),
//         'value': TextEditingController(),
//       });
//     });
//   }
//
//   void _removeSparePart(int index) {
//     setState(() {
//       if (index < _sparePartsControllers.length) {
//         // Dispose controllers to prevent memory leaks
//         _sparePartsControllers[index]['part']?.dispose();
//         _sparePartsControllers[index]['value']?.dispose();
//         _sparePartsControllers.removeAt(index);
//       }
//     });
//   }
//
//   Widget _buildSparePartsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header with title and Add button
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Major Maintainance'.tr(),
//               style: const TextStyle(
//                   color: Color(0xFF6B8E23),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14.0,
//                   fontFamily: "Poppins"),
//             ),
//             ElevatedButton.icon(
//               icon: const Icon(
//                 Icons.add,
//                 size: 12,
//                 color: Colors.white,
//               ),
//               label: const Text('Add Spare').tr(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF6B8E23),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 textStyle: const TextStyle(fontSize: 14),
//               ),
//               onPressed: _addNewSparePart,
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//
//         // Display all spare parts fields
//         ..._sparePartsControllers.asMap().entries.map((entry) {
//           int index = entry.key;
//           var controllers = entry.value;
//
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 10.0),
//             child: Row(
//               children: [
//                 // Spare part name field
//                 Expanded(
//                   flex: 3,
//                   child: _buildCustomTextField(
//                     labelText: 'Major Repair'.tr(),
//                     hintText: 'Enter major repair'.tr(),
//                     controller: controllers['part']!,
//                     isRequired: false,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//
//                 // Spare part value field
//                 Expanded(
//                   flex: 2,
//                   child: _buildCustomTextField(
//                     labelText: 'Cost(Rs)'.tr(),
//                     hintText: 'Enter value'.tr(),
//                     controller: controllers['value']!,
//                     keyboardType: TextInputType.number,
//                     isRequired: false,
//                   ),
//                 ),
//
//                 // Remove button
//                 IconButton(
//                   icon: const Icon(Icons.remove_circle, color: Colors.red),
//                   onPressed: () => _removeSparePart(index),
//                 ),
//               ],
//             ),
//           );
//         }),
//       ],
//     );
//   }
//
//   Future<void> _fetchBlocksAndPlots() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String token = prefs.getString('auth_token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('Authentication token not found');
//       }
//
//       final response = await http.post(
//         Uri.parse('${Constanst().base_url}site-blocks-plots'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//
//         if (responseData['success'] == true) {
//           final List<dynamic> blocksData = responseData['data'];
//
//           setState(() {
//             // Reset arrays - Remove .tr() from initialization
//             _blocks = [];
//             _blockNames = ['Select Block']; // No .tr() here
//
//             // Process blocks data
//             for (var block in blocksData) {
//               _blocks.add({
//                 'block_name': block['block_name'],
//                 'plots': block['plots'],
//               });
//               _blockNames.add(block['block_name'].toString());
//             }
//
//             // Initialize plot dropdown with just the default option
//             _plots = [];
//             _plotNames = ['Select Plot']; // No .tr() here
//
//             // Reset area text
//             _areaText = '';
//             _selectedArea = null;
//
//             _isLoading = false;
//           });
//         } else {
//           throw Exception('API returned false success status');
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Something went wrong')),
//         );
//       }
//     } on SocketException {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please connect your internet')),
//       );
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Something went wrong')),
//       );
//     }
//   }
//
//   void _updatePlots(String blockName) {
//     // Check if "Select Block" is chosen - Remove .tr() from comparison
//     if (blockName == 'Select Block') {
//       setState(() {
//         // Reset plot dropdown
//         _plots = [];
//         _plotNames = ['Select Plot']; // No .tr() here
//         _selectedPlotName = 'Select Plot'; // No .tr() here
//
//         // Reset area field
//         _areaText = '';
//         _selectedArea = null;
//         _selectedPlotId = null;
//       });
//       return;
//     }
//
//     // Find selected block
//     final selectedBlock = _blocks.firstWhere(
//       (block) => block['block_name'] == blockName,
//       orElse: () => {},
//     );
//
//     if (selectedBlock.isNotEmpty) {
//       setState(() {
//         _selectedBlockId = _blockNames.indexOf(blockName);
//
//         // Reset subsequent selections
//         _selectedPlotName = 'Select Plot'; // No .tr() here
//         _selectedPlotId = null;
//         _selectedArea = null;
//         _areaText = '';
//
//         // Update plots for the selected block
//         final List<dynamic> plotsData = selectedBlock['plots'];
//         _plots = List<Map<String, dynamic>>.from(plotsData.map((plot) => {
//               'plot_name': plot['plot_name'],
//               'area': plot['area'],
//             }));
//
//         // Update plot names dropdown - Remove .tr() from initialization
//         _plotNames = ['Select Plot']; // No .tr() here
//         _plotNames.addAll(
//             _plots.map((plot) => plot['plot_name'].toString()).toList());
//       });
//     }
//   }
//
// // Fix the _updateAreaText method
//   void _updateAreaText(String plotName) {
//     // Check if "Select Plot" is chosen - Remove .tr() from comparison
//     if (plotName == 'Select Plot') {
//       setState(() {
//         _areaText = '';
//         _selectedArea = null;
//         _selectedPlotId = null;
//       });
//       return;
//     }
//
//     // Find selected plot
//     final selectedPlot = _plots.firstWhere(
//       (plot) => plot['plot_name'] == plotName,
//       orElse: () => {},
//     );
//
//     if (selectedPlot.isNotEmpty) {
//       setState(() {
//         _selectedPlotId = _plotNames.indexOf(plotName);
//         _selectedArea = double.tryParse(selectedPlot['area'].toString());
//         _areaText = '${selectedPlot['area']} ';
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     // Dispose controllers and focus nodes to prevent memory leaks
//     _fuelConsumptionController.dispose();
//     _levelingController.dispose();
//     _levelingFocusNode.dispose();
//
//     for (var controllerMap in _sparePartsControllers) {
//       controllerMap['part']?.dispose();
//       controllerMap['value']?.dispose();
//     }
//
//     for (var controller in controllers.values) {
//       controller.dispose();
//     }
//     for (var node in focusNodes.values) {
//       node.dispose();
//     }
//     super.dispose();
//   }
//
//   // Date Picker Method
//   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _startDate ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2101),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF6B8E23), // header background color
//               onPrimary: Colors.white, // header text color
//               onSurface: Colors.black, // body text color
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//         }
//       });
//     }
//   }
//
// // Modified _selectTime method with initialTime set to current time or existing selection
//   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: isStartTime
//           ? (_startTime ?? TimeOfDay.now())
//           : (_endTime ?? TimeOfDay.now()),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF6B8E23), // header background color
//               onPrimary: Colors.white, // header text color
//               onSurface: Colors.black, // body text color
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       setState(() {
//         if (isStartTime) {
//           _startTime = picked;
//         } else {
//           _endTime = picked;
//         }
//       });
//     }
//   }
//
//   Widget _buildCustomTextField({
//     required String labelText,
//     String? hintText,
//     TextInputType? keyboardType,
//     required TextEditingController controller,
//     FocusNode? focusNode,
//     bool isRequired = true,
//     String? Function(String?)? customValidator,
//     int? maxLength, // Add maxLength parameter
//   }) {
//     return TextFormField(
//       onTap: () {
//         setState(() {
//           _closeAllDropdowns();
//         });
//       },
//       controller: controller,
//       focusNode: focusNode,
//       keyboardType: keyboardType ?? TextInputType.text,
//       maxLength: maxLength, // Set max length
//       inputFormatters: maxLength != null
//           ? [LengthLimitingTextInputFormatter(maxLength)]
//           : null, // Add input formatter for length limiting
//       validator: customValidator ??
//           (value) {
//             if (isRequired && (value == null || value.isEmpty)) {
//               return 'Please enter $labelText';
//             }
//             return null;
//           },
//       decoration: InputDecoration(
//         labelText: (labelText + (isRequired ? ' *' : '')).tr(),
//         labelStyle: const TextStyle(
//             color: Color(0xFF6B8E23),
//             fontWeight: FontWeight.bold,
//             fontSize: 14.0,
//             fontFamily: "Poppins"),
//         hintText: (hintText ?? 'Enter $labelText').tr(),
//         hintStyle: const TextStyle(
//             fontFamily: "Poppins", fontSize: 14.0, color: Colors.grey),
//         floatingLabelBehavior: FloatingLabelBehavior.always,
//         contentPadding:
//             const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20.0),
//           borderSide: const BorderSide(width: 1),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20.0),
//           borderSide: BorderSide(
//             color: Colors.grey.shade400,
//             width: 1,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20.0),
//           borderSide: const BorderSide(
//             color: Color(0xFF6B8E23),
//             width: 2,
//           ),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         counterText: "", // Hide the counter text that shows "0/4"
//       ),
//     );
//   }
//
//   void _handleMachineSelection(
//       String machine, bool selected, FormFieldState<Set<String>> state) {
//     setState(() {
//       if (selected == true) {
//         selectedMachines.add(machine);
//         // Clear tractors when machine is selected
//       } else {
//         selectedMachines.remove(machine);
//       }
//       state.didChange(selectedMachines);
//     });
//   }
//
//   void _handleTractorSelection(
//       String tractor, bool selected, FormFieldState<Set<String>> state) {
//     setState(() {
//       if (selected == true) {
//         selectedTractors.add(tractor);
//         // Clear machines when tractor is selected
//       } else {
//         selectedTractors.remove(tractor);
//       }
//       state.didChange(selectedTractors);
//     });
//   }
//
//   void _closeAllDropdowns() {
//     setState(() {
//       showMachineDropdown = false;
//       showTractorDropdown = false;
//       showCheckboxes = false;
//     });
//   }
//
//
// Widget _buildMachineSelectionSection() {
//   return FormField<Set<String>>(
//     initialValue: selectedMachines,
//     validator: (value) {
//       if (value == null || value.isEmpty) {
//         return 'Please select at least one machine'.tr();
//       }
//       return null;
//     },
//     builder: (FormFieldState<Set<String>> state) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: () => _showMachineBottomSheet(state),
//             child: InputDecorator(
//               decoration: InputDecoration(
//                 labelText: 'Machine*'.tr(),
//                 labelStyle: const TextStyle(
//                   color: Color(0xFF6B8E23),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14.0,
//                   fontFamily: "Poppins",
//                 ),
//
//  border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: const BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
//                 ),
//
//
//               floatingLabelBehavior: FloatingLabelBehavior.always,
//                 contentPadding: const EdgeInsets.symmetric(
//                   vertical: 15.0,
//                   horizontal: 20.0,
//                 ),
//           filled: true,
//           fillColor: Colors.white,
//           suffixIcon: const Icon(
//             Icons.keyboard_arrow_down,
//             color: Color(0xFF6B8E23),
//           ),
//                 errorText: state.hasError ? state.errorText : null,
//               ),
//
//             child: Text(
//                       selectedMachines.isEmpty
//                         ? 'Search or Select Machines'.tr()
//                         : selectedMachines.join(', '),
//                       style: TextStyle(
//                         color: selectedMachines.isEmpty ? Colors.grey : Colors.black,
//                         fontFamily: "Poppins",
//                         fontSize: 14,
//                       ),
//                     ),
//               ),
//
//           ),
//
//           if (state.hasError)
//             Padding(
//               padding: const EdgeInsets.only(left: 20, top: 5),
//               child: Text(
//                 state.errorText!,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//               ),
//         ],
//       );
//     },
//   );
// }
//
// Widget _buildTractorSelectionSection() {
//   return FormField<Set<String>>(
//     initialValue: selectedTractors,
//     validator: (value) {
//       if (value == null || value.isEmpty) {
//         return 'Please select at least one tractor'.tr();
//       }
//       return null;
//     },
//     builder: (FormFieldState<Set<String>> state) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: () => _showTractorBottomSheet(state),
//             child: InputDecorator(
//               decoration: InputDecoration(
//                 labelText: 'Tractor*'.tr(),
//                 labelStyle: const TextStyle(
//                   color: Color(0xFF6B8E23),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14.0,
//                   fontFamily: "Poppins",
//                 ),
//                 floatingLabelBehavior: FloatingLabelBehavior.always,
//                 contentPadding: const EdgeInsets.symmetric(
//                   vertical: 15.0,
//                   horizontal: 20.0,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: const BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//                 suffixIcon: const Icon(
//                   Icons.keyboard_arrow_down,
//                   color: Color(0xFF6B8E23),
//                 ),
//                 errorText: state.hasError ? state.errorText : null,
//               ),
//               child: Text(
//                 selectedTractors.isEmpty
//                   ? 'Search or select tractor'.tr()
//                   : selectedTractors.join(', '),
//                 style: TextStyle(
//                   color: selectedTractors.isEmpty ? Colors.grey : Colors.black,
//                   fontFamily: "Poppins",
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ),
//  if (state.hasError)
//             Padding(
//               padding: const EdgeInsets.only(left: 20, top: 5),
//               child: Text(
//                 state.errorText!,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             ),
//
//         ],
//       );
//     },
//   );
// }
//
//
//   Widget _buildCustomDropdown({
//     required String labelText,
//     required String? selectedValue,
//     required List items,
//     required Function(String?) onChanged,
//   }) {
//     final bool valueExists =
//         selectedValue != null && items.contains(selectedValue);
//     final String? safeValue = valueExists ? selectedValue : null;
//
//     return DropdownButtonFormField<String>(
//       onTap: () {
//         setState(() {
//           _closeAllDropdowns();
//         });
//       },
//       isDense: true,
//       isExpanded: true,
//       menuMaxHeight: 300,
//       validator: (value) {
//         // Special case: Make Type of Man Power optional
//         if (labelText == 'Type of Man Power') {
//           return null;
//         }
//         // For all other dropdowns, keep existing validation
//         if (value == null || value.startsWith('Select')) {
//           return 'Please select $labelText'.tr();
//         }
//         return null;
//       },
//       decoration: InputDecoration(
//         labelText:
//             (labelText + (labelText == 'Type of Man Power' ? '' : ' *')).tr(),
//         labelStyle: const TextStyle(
//             color: Color(0xFF6B8E23),
//             fontWeight: FontWeight.bold,
//             fontSize: 14.0,
//             fontFamily: "Poppins"),
//         floatingLabelBehavior: FloatingLabelBehavior.always,
//         contentPadding:
//             const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20.0),
//           borderSide: const BorderSide(
//             color: Colors.grey,
//             width: 1,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20.0),
//           borderSide: BorderSide(
//             color: Colors.grey.shade400,
//             width: 1,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20.0),
//           borderSide: const BorderSide(
//             color: Color(0xFF6B8E23),
//             width: 2,
//           ),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         suffixIcon: const Icon(
//           Icons.keyboard_arrow_down,
//           color: Color(0xFF6B8E23),
//         ),
//       ),
//       value: safeValue,
//       items: items.map((name) {
//         return DropdownMenuItem<String>(
//           value: name,
//           child: Text(
//             name.toString().tr(), // Apply .tr() only here for display
//             style: TextStyle(
//               color: name.toString().startsWith('Select')
//                   ? Colors.grey
//                   : Colors.black,
//               fontFamily: "Poppins",
//               fontSize: 14.0,
//             ),
//           ),
//         );
//       }).toList(),
//       onChanged: (value) {
//         onChanged(value);
//         // If this is the manpower type dropdown, update categories
//         if (labelText == 'Type of Man Power' &&
//             value != null &&
//             value != 'Select Man Power') {
//           _updateCategoriesForType(value);
//         }
//       },
//       icon: const SizedBox.shrink(),
//       dropdownColor: Colors.white,
//       style: const TextStyle(
//         color: Colors.black,
//         fontSize: 14,
//         fontFamily: "Poppins",
//       ),
//       hint: Text(
//         "Select ${labelText.split(' ')[0]}".tr(),
//         style: const TextStyle(
//           color: Colors.grey,
//           fontFamily: "Poppins",
//           fontSize: 14.0,
//         ),
//       ),
//     );
//   }
//
// // Updated _updateCategoriesForType method
//   void _updateCategoriesForType(String typeName) {
//     setState(() {
//       // Clear previous selections
//       selectedCategories.clear();
//       showCheckboxes = false; // Close the dropdown when type changes
//
//       // Clear existing controllers and focus nodes
//       for (var controller in controllers.values) {
//         controller.dispose();
//       }
//       for (var node in focusNodes.values) {
//         node.dispose();
//       }
//       controllers.clear();
//       focusNodes.clear();
//
//       // Get categories for the selected type
//       if (_categoriesByType.containsKey(typeName)) {
//         List<Map<String, dynamic>> typeCategories =
//             _categoriesByType[typeName]!;
//
//         categories = typeCategories
//             .map((cat) => cat['category_name'].toString())
//             .toList();
//
//         // Initialize controllers and focus nodes for new categories
//         for (String category in categories) {
//           controllers[category] = TextEditingController();
//           focusNodes[category] = FocusNode();
//         }
//
//         print('🔄 Updated categories for $typeName: $categories');
//       } else {
//         categories = [];
//         print('⚠️ No categories found for type: $typeName');
//       }
//     });
//   }
//
//
// // Updated _buildManpowerSection with better UX
//   Widget _buildManpowerSection() {
//     return FormField<Set<String>>(
//       initialValue: selectedCategories,
//       validator: null, // No validation - optional field
//       builder: (FormFieldState<Set<String>> state) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//            GestureDetector(
//   onTap: () {
//     if (_selectedManPowerRoll != null &&
//         _selectedManPowerRoll != 'Select Man Power' &&
//         categories.isNotEmpty) {
//       _showManpowerBottomSheet(state);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select Type of Man Power first'),
//           backgroundColor: Colors.orange,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   },
//   child: InputDecorator(
//     decoration: InputDecoration(
//       labelText: 'Category of Man Power (Optional)'.tr(),
//       labelStyle: const TextStyle(
//         color: Color(0xFF6B8E23),
//         fontWeight: FontWeight.bold,
//         fontSize: 14.0,
//         fontFamily: "Poppins",
//       ),
//       floatingLabelBehavior: FloatingLabelBehavior.always,
//       contentPadding: const EdgeInsets.symmetric(
//         vertical: 15.0,
//         horizontal: 20.0,
//       ),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(20.0),
//         borderSide: const BorderSide(color: Colors.grey, width: 1),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(20.0),
//         borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(20.0),
//         borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
//       ),
//       filled: true,
//       fillColor: (_selectedManPowerRoll == null ||
//               _selectedManPowerRoll == 'Select Man Power' ||
//               categories.isEmpty)
//           ? Colors.grey.shade100
//           : Colors.white,
//       suffixIcon: Icon(
//         Icons.keyboard_arrow_down,
//         color: (_selectedManPowerRoll != null &&
//                 _selectedManPowerRoll != 'Select Man Power' &&
//                 categories.isNotEmpty)
//             ? const Color(0xFF6B8E23)
//             : Colors.grey,
//       ),
//       errorText: state.hasError ? state.errorText : null,
//     ),
//     child: Text(
//       selectedCategories.isEmpty
//           ? (_selectedManPowerRoll == null ||
//                   _selectedManPowerRoll == 'Select Man Power')
//               ? 'Select Type of Man Power first'.tr()
//               : categories.isEmpty
//                   ? 'No categories available'.tr()
//                   : 'Select Category'.tr()
//           : selectedCategories.join(', '),
//       style: TextStyle(
//         color: selectedCategories.isEmpty ? Colors.grey : Colors.black,
//         fontFamily: "Poppins",
//         fontSize: 14,
//       ),
//     ),
//   ),
// ),
//             if (showCheckboxes && categories.isNotEmpty)
//               Container(
//                 margin: const EdgeInsets.only(top: 8),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Column(
//                   children: categories.map((category) {
//                     return CheckboxListTile(
//                       contentPadding: const EdgeInsets.only(left: 4),
//                       title: Text(
//                         category.tr(),
//                         style: const TextStyle(fontFamily: "Poppins"),
//                       ),
//                       value: selectedCategories.contains(category),
//                       onChanged: (bool? selected) {
//                         setState(() {
//                           if (selected == true) {
//                             selectedCategories.add(category);
//                           } else {
//                             selectedCategories.remove(category);
//                             // Clear the controller value when unchecked
//                             if (controllers[category] != null) {
//                               controllers[category]!.clear();
//                             }
//                           }
//                           state.didChange(selectedCategories);
//                         });
//                       },
//                       controlAffinity: ListTileControlAffinity.leading,
//                       activeColor: const Color(0xFF6B8E23),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             const SizedBox(height: 10),
//             if (selectedCategories.isNotEmpty)
//               SizedBox(
//                 height: 90,
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   physics: const BouncingScrollPhysics(),
//                   child: Row(
//                     children: selectedCategories.map((category) {
//                       return Container(
//                         width: 140,
//                         margin: const EdgeInsets.symmetric(horizontal: 4),
//                         child: TextFormField(
//                           controller: controllers[category]!,
//                           focusNode: focusNodes[category],
//                           keyboardType: TextInputType.number,
//                           maxLength: 3,
//                           buildCounter: (context,
//                               {required currentLength,
//                               required isFocused,
//                               maxLength}) {
//                             return null;
//                           },
//                           validator: (value) {
//                             if (selectedCategories.contains(category)) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Required'.tr();
//                               }
//                               if (int.tryParse(value) == null) {
//                                 return 'Numbers only'.tr();
//                               }
//                             }
//                             return null;
//                           },
//                           decoration: InputDecoration(
//                             labelText: '${category.tr()} *',
//                             labelStyle: const TextStyle(
//                                 color: Color(0xFF6B8E23),
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12.0,
//                                 fontFamily: "Poppins"),
//                             hintText: 'Enter ${category.tr()}',
//                             hintStyle: const TextStyle(
//                                 fontFamily: "Poppins",
//                                 fontSize: 12.0,
//                                 color: Colors.grey),
//                             floatingLabelBehavior: FloatingLabelBehavior.always,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 10.0, horizontal: 15.0),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15.0),
//                               borderSide: const BorderSide(width: 1),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15.0),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade400,
//                                 width: 1,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(15.0),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF6B8E23),
//                                 width: 2,
//                               ),
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
//
//
//
//   Widget _buildDateTimePicker({
//     required String labelText,
//     required String hintText,
//     required dynamic value,
//     required IconData icon,
//     required Function() onTap,
//     bool isRequired = true,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AbsorbPointer(
//         child: TextFormField(
//           validator: (val) {
//             if (isRequired && (value == null || value.toString().isEmpty)) {
//               return 'Please select $labelText';
//             }
//             return null;
//           },
//           decoration: InputDecoration(
//             labelText: (labelText + (isRequired ? ' *' : '')).tr(),
//             labelStyle: const TextStyle(
//               color: Color(0xFF6B8E23),
//               fontWeight: FontWeight.bold,
//               fontSize: 14.0,
//               fontFamily: "Poppins",
//             ),
//             floatingLabelBehavior: FloatingLabelBehavior.always,
//             hintText: hintText,
//             hintStyle: const TextStyle(
//               color: Colors.grey,
//               fontSize: 14.0,
//               fontFamily: "Poppins",
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: const EdgeInsets.symmetric(
//               vertical: 15.0,
//               horizontal: 20.0,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(20.0),
//               borderSide: const BorderSide(color: Colors.grey, width: 1),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(20.0),
//               borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(20.0),
//               borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
//             ),
//             suffixIcon: Icon(icon, color: const Color(0xFF6B8E23)),
//           ),
//           controller: TextEditingController(
//             text: value?.toString() ?? '',
//           ),
//           style: const TextStyle(
//             color: Colors.black,
//             fontSize: 14.0,
//             fontFamily: "Poppins",
//           ),
//           readOnly: true,
//         ),
//       ),
//     );
//   }
//
// // Update the _submitForm method - replace the existing machine and tractor ID collection logic
//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       // Show loading indicator
//       setState(() {
//         _isLoading = true;
//       });
//
//       try {
//         // Get token from SharedPreferences
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         String token = prefs.getString('auth_token') ?? '';
//         int? userId = prefs.getInt('user_id');
//
//         if (token.isEmpty) {
//           throw Exception('Authentication token not found');
//         }
//
//         // Format date
//         String formattedDate = '';
//         if (_startDate != null) {
//           formattedDate = DateFormat('yyyy-MM-dd').format(_startDate!);
//         }
//
//         // Format times
//         String startTimeStr = '';
//         String endTimeStr = '';
//
//         if (_startTime != null) {
//           startTimeStr =
//               '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
//         }
//
//         if (_endTime != null) {
//           endTimeStr =
//               '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
//         }
//
//         // UPDATED: Get actual machine IDs based on selected names
//         List<String> machineIds = [];
//         if (selectedMachines.isNotEmpty) {
//           for (String machineDisplayName in selectedMachines) {
//             // Find the machine data that corresponds to this display name
//             var machineData = _machines.firstWhere(
//               (machine) =>
//                   '${machine['machine_name']} (${machine['machine_no']})' ==
//                   machineDisplayName,
//               orElse: () => {},
//             );
//             if (machineData.isNotEmpty) {
//               machineIds.add(machineData['id'].toString());
//             }
//           }
//         }
//
//         // UPDATED: Get actual tractor IDs based on selected names
//        List<String> tractorIds = [];
// if (selectedTractors.isNotEmpty) {
//   for (String tractorDisplayName in selectedTractors) {
//     // Find the tractor data that corresponds to this display name
//     var tractorData = _tractors.firstWhere(
//       (tractor) => tractor['tractor_name'] == tractorDisplayName,
//       orElse: () => {},
//     );
//     if (tractorData.isNotEmpty) {
//       tractorIds.add(tractorData['id'].toString());
//     }
//   }
// }
//
//
//
//         List<Map<String, String>> sparePartsData = [];
//         for (var controller in _sparePartsControllers) {
//           if (controller['part']!.text.isNotEmpty ||
//               controller['value']!.text.isNotEmpty) {
//             sparePartsData.add({
//               'spare_part': controller['part']!.text,
//               'value': controller['value']!.text,
//             });
//           }
//         }
//
//         // Get type_id for selected manpower type
//         int? selectedTypeId;
//         if (_selectedManPowerRoll != null &&
//             _selectedManPowerRoll != 'Select Man Power') {
//           var selectedType = _manpowerTypes.firstWhere(
//             (type) => type['type_name'] == _selectedManPowerRoll,
//             orElse: () => {},
//           );
//           if (selectedType.isNotEmpty) {
//             selectedTypeId = selectedType['type_id'];
//           }
//         }
//
//         // Collect manpower data with category_ids and values
//         List<Map<String, dynamic>> manpowerData = [];
//         if (selectedCategories.isNotEmpty &&
//             _selectedManPowerRoll != null &&
//             _selectedManPowerRoll != 'Select Man Power') {
//           List<Map<String, dynamic>> typeCategories =
//               _categoriesByType[_selectedManPowerRoll] ?? [];
//
//           for (String categoryName in selectedCategories) {
//             var categoryInfo = typeCategories.firstWhere(
//               (cat) => cat['category_name'] == categoryName,
//               orElse: () => {},
//             );
//
//             if (categoryInfo.isNotEmpty &&
//                 controllers[categoryName]?.text.isNotEmpty == true) {
//               manpowerData.add({
//                 'category_id': categoryInfo['category_id'],
//                 'no_of_person':
//                     int.tryParse(controllers[categoryName]!.text) ?? 0,
//               });
//             }
//           }
//         }
//
//         // Prepare data for API request
//         final Map<String, dynamic> requestData = {
//           'block_name': _selectedBlockName,
//           'plot_name': _selectedPlotName,
//           'area': _selectedArea,
//           'spare_parts': sparePartsData,
//           'machine_ids': machineIds, // Now contains actual IDs
//           'tractor_ids': tractorIds, // Now contains actual IDs
//           'area_leveling': _levelingController.text,
//           'hsd_consumption':
//               double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
//           'start_time': startTimeStr,
//           'end_time': endTimeStr,
//           'date': formattedDate,
//           'user_id': userId,
//         };
//
//         // Add manpower type_id and categories if selected
//         if (selectedTypeId != null) {
//           requestData['manpower_type_id'] = selectedTypeId;
//         }
//
//         if (manpowerData.isNotEmpty) {
//           requestData['manpower_categories'] = manpowerData;
//         }
//
//         print("Request Data: ${json.encode(requestData)}");
//
//         // Make API call
//         final response = await http.post(
//           Uri.parse('${Constanst().base_url}area-leveling/store'),
//           headers: {
//             'Authorization': 'Bearer $token',
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//           },
//           body: jsonEncode(requestData),
//         );
//
//         setState(() {
//           _isLoading = false;
//         });
//
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           final responseData = json.decode(response.body);
//           print("API Response: $responseData");
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Details submitted successfully'),
//               backgroundColor: Color(0xFF6B8E23),
//               duration: Duration(seconds: 3),
//             ),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => const DashboardScreen()),
//           );
//
//           _resetForm();
//         } else {
//           try {
//             final errorData = jsonDecode(response.body);
//             String errorMessage = '';
//
//             if (errorData.containsKey('error')) {
//               String mainError = errorData['error'] ?? 'Failed to submit data';
//
//               if (errorData.containsKey('available_stock') &&
//                   errorData.containsKey('requested_consumption')) {
//                 String availableStock = errorData['available_stock'] ?? '0.00';
//                 String requestedConsumption =
//                     errorData['requested_consumption']?.toString() ?? '0';
//
//                 errorMessage =
//                     '$mainError\nAvailable Stock: $availableStock\nRequested: $requestedConsumption';
//               } else {
//                 errorMessage = mainError;
//               }
//             } else if (errorData.containsKey('message')) {
//               errorMessage = errorData['message'];
//             } else {
//               errorMessage = 'Failed to submit data';
//             }
//
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(errorMessage),
//                 backgroundColor: Colors.orange,
//                 duration: const Duration(seconds: 4),
//               ),
//             );
//           } catch (parseError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(
//                         'Failed to submit data. Status: ${response.statusCode}')
//                     .tr(),
//                 backgroundColor: Colors.red,
//                 duration: const Duration(seconds: 3),
//               ),
//             );
//           }
//         }
//       } catch (e) {
//         setState(() {
//           _isLoading = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all required fields'),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop, // Connect to the back button handler
//       child: Scaffold(
//         body: NestedScrollView(
//           headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
//             return <Widget>[
//               SliverAppBar(
//                 expandedHeight: 155.0,
//                 floating: false,
//                 pinned: true,
//                 backgroundColor: const Color(0xFF6B8E23),
//                 leading: IconButton(
//                   icon: const Icon(Icons.arrow_back, color: Colors.white),
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const DashboardScreen()),
//                     );
//                   },
//                 ),
//                 flexibleSpace: FlexibleSpaceBar(
//                   centerTitle: true,
//                   title: Text(
//                     'Area Leveling'.tr(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: "Poppins",
//                     ),
//                   ),
//                   background: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(vertical: 40),
//                     decoration: const BoxDecoration(
//                       color: Color(0xFF6B8E23),
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(40),
//                         bottomRight: Radius.circular(40),
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         Image.asset(
//                           'assets/images/circle_logo.png',
//                           width: 100,
//                           height: 60,
//                         ),
//                         const SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                 ),
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(40),
//                     bottomRight: Radius.circular(40),
//                   ),
//                 ),
//               ),
//             ];
//           },
//           body: _isLoading
//               ? const Center(
//                   child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B8E23)),
//                 ))
//               : Form(
//                   key: _formKey,
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Block Name Dropdown
//                         _buildCustomDropdown(
//                           labelText: 'Block Name'.tr(),
//                           selectedValue: _selectedBlockName,
//                           items: _blockNames,
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedBlockName = value;
//                               });
//                               _updatePlots(value);
//                             }
//                           },
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // Plot Name Dropdown
//                         _buildCustomDropdown(
//                           labelText: 'Plot Name'.tr(),
//                           selectedValue: _selectedPlotName,
//                           items: _plotNames,
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedPlotName = value;
//                               });
//                               _updateAreaText(value);
//                             }
//                           },
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         TextFormField(
//                           controller: TextEditingController(text: _areaText),
//                           readOnly: true,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontFamily: "Poppins",
//                           ),
//                           decoration: InputDecoration(
//                             labelText: 'Area (Acre)'.tr(),
//                             hintText: 'Total Area'.tr(),
//                             labelStyle: const TextStyle(
//                                 color: Color(0xFF6B8E23),
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14.0,
//                                 fontFamily: "Poppins"),
//                             hintStyle: const TextStyle(
//                                 fontFamily: "Poppins",
//                                 fontSize: 14.0,
//                                 color: Colors.grey),
//                             floatingLabelBehavior: FloatingLabelBehavior.always,
//                             contentPadding: const EdgeInsets.symmetric(
//                                 vertical: 15.0, horizontal: 20.0),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(20.0),
//                               borderSide: const BorderSide(
//                                 color: Colors.grey,
//                                 width: 1,
//                               ),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(20.0),
//                               borderSide: BorderSide(
//                                 color: Colors.grey.shade400,
//                                 width: 1,
//                               ),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(20.0),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF6B8E23),
//                                 width: 2,
//                               ),
//                             ),
//                             filled: true,
//                             fillColor: Colors.white,
//                           ),
//                           validator: (value) {
//                             if (_selectedArea == null) {
//                               return 'Please select a plot first'.tr();
//                             }
//                             return null;
//                           },
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // Area Leveling TextField
//                         _buildCustomTextField(
//                           labelText: 'Area Leveling(Acre)'.tr(),
//                           hintText: 'Enter Area Leveling'.tr(),
//                           controller: _levelingController,
//                           focusNode: _levelingFocusNode,
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true), // Number keyboard with decimal
//                           maxLength: 5, // Limit to 4 digits
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         _buildMachineSelectionSection(),
//
//                         const SizedBox(height: 20),
//                         _buildTractorSelectionSection(),
//
//                         const SizedBox(height: 20),
//
//                         // HSD Consumption TextField
//                         _buildCustomTextField(
//                           labelText: 'HSD Consumption'.tr(),
//                           hintText: 'Enter HSD Consumption'.tr(),
//                           controller: _HSD_Consuption_Controller,
//                           focusNode: _HSD_FocusNode,
//                           keyboardType: const TextInputType.numberWithOptions(
//                               decimal: true),
//                           maxLength: 6, // Limit to 3 digits
//                           customValidator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter HSD consumption'.tr();
//                             }
//                             if (double.tryParse(value) == null) {
//                               return 'Please enter a valid number'.tr();
//                             }
//                             return null;
//                           },
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // Date Picker
//                         _buildDateTimePicker(
//                           labelText: 'Date'.tr(),
//                           hintText: 'dd-mm-yyyy'.tr(),
//                           value: _startDate == null
//                               ? null
//                               : DateFormat('dd-MM-yyyy').format(_startDate!),
//                           icon: Icons.calendar_today,
//                           onTap: () => _selectDate(context, true),
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // Time Pickers Row
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _buildDateTimePicker(
//                                 labelText: 'Start Time'.tr(),
//                                 hintText: 'Start Time'.tr(),
//                                 value: _startTime?.format(context),
//                                 icon: Icons.access_time,
//                                 onTap: () => _selectTime(context, true),
//                               ),
//                             ),
//                             const SizedBox(width: 15),
//                             Expanded(
//                               child: _buildDateTimePicker(
//                                 labelText: 'End Time'.tr(),
//                                 hintText: 'End Time'.tr(),
//                                 value: _endTime?.format(context),
//                                 icon: Icons.access_time,
//                                 onTap: () => _selectTime(context, false),
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         _buildCustomDropdown(
//                           labelText: 'Type of Man Power'.tr(),
//                           selectedValue: _selectedManPowerRoll,
//                           items: _manpowerTypeNames, // Changed this line
//                           onChanged: (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedManPowerRoll = value;
//                               });
//                             }
//                           },
//                         ),
//
//                         const SizedBox(height: 20),
//
//                         // Man Power Section
//                         _buildManpowerSection(),
//
//                         const SizedBox(height: 20),
//
//                         _buildSparePartsSection(),
//
//                         const SizedBox(height: 20),
//
//                         // Submit Button
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 50),
//                           child: SizedBox(
//                             width: 100,
//                             height: 50,
//                             child: ElevatedButton(
//                               onPressed: _submitForm,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF6B8E23),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 elevation: 2,
//                               ),
//                               child: Text(
//                                 'Submit'.tr(),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   fontFamily: "Poppins",
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//
//                         const SizedBox(height: 35),
//                       ],
//                     ),
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
//
//   // Fix the _resetForm method
//   void _resetForm() {
//     setState(() {
//       _selectedBlockName = 'Select Block'; // No .tr() here
//       _selectedPlotName = 'Select Plot'; // No .tr() here
//       _areaText = '';
//       _selectedArea = null;
//       _selectedBlockId = null;
//       _selectedPlotId = null;
//
//       selectedTractors.clear();
//       _tractorSearchController.clear();
//       showTractorDropdown = false;
//
//       selectedMachines.clear();
//       _machineSearchController.clear();
//       showMachineDropdown = false;
//
//       _sparePartsControllers.clear();
//
//       _selectedManPowerRoll = 'Select Man Power'; // No .tr() here
//       _selectedLandQuality = 'Select Land Quality'; // No .tr() here
//       _fuelConsumptionController.clear();
//       _levelingController.clear();
//       _HSD_Consuption_Controller.clear();
//       _startDate = null;
//       _startTime = null;
//       _endTime = null;
//
//       // Clear selected categories and their values
//       selectedCategories = {};
//       for (var controller in controllers.values) {
//         controller.clear();
//       }
//
//       // Reset dropdowns - No .tr() here
//       _updatePlots('Select Block');
//
//       // Reset form validation
//       _formKey.currentState?.reset();
//     });
//   }
//
//
// Future<void> _fetchTractorDetails() async {
//   try {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String tractorToken = prefs.getString('auth_token') ?? '';
//
//     if (tractorToken.isEmpty) {
//       throw Exception('Authentication token not found');
//     }
//
//     final response = await http.post(
//       Uri.parse('${Constanst().base_url}tractors-names'),
//       headers: {
//         'Authorization': 'Bearer $tractorToken',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final Map<String, dynamic> responseData = json.decode(response.body);
//       print('Tractor API Response: $responseData');
//
//       bool isSuccess = false;
//       List<dynamic> tractorData = [];
//
//       if (responseData.containsKey('status') && responseData['status'] == 'success') {
//         isSuccess = true;
//         tractorData = responseData['data'] ?? [];
//       } else if (responseData.containsKey('success') && responseData['success'] == true) {
//         isSuccess = true;
//         tractorData = responseData['data'] ?? [];
//       } else if (responseData.containsKey('data')) {
//         isSuccess = true;
//         tractorData = responseData['data'] ?? [];
//       }
//
//       if (isSuccess && tractorData.isNotEmpty) {
//         setState(() {
//           // Clear existing data
//           _tractors.clear();
//           _tractorName = ['Select Tractor'];
//
//           for (var tractor in tractorData) {
//             String tractorName = '';
//             dynamic tractorId = '';
//
//             // Get tractor name - based on your API response structure
//             if (tractor.containsKey('tractor_name')) {
//               tractorName = tractor['tractor_name']?.toString() ?? 'Unknown Tractor';
//             }
//
//             // Get tractor ID
//             if (tractor.containsKey('id')) {
//               tractorId = tractor['id'];
//             }
//
//             if (tractorName.isNotEmpty && tractorName != 'Unknown Tractor') {
//               // Store tractor data for ID mapping
//               _tractors.add({
//                 'id': tractorId,
//                 'tractor_name': tractorName,
//               });
//
//               // Use just the tractor name as display name since there's no tractor_no
//               _tractorName.add(tractorName);
//             }
//           }
//
//           _filteredTractorNames = _tractorName
//               .where((tractor) => tractor != 'Select Tractor')
//               .toList();
//         });
//
//         print('Tractors loaded: $_tractors');
//       }
//     }
//   } catch (e) {
//     print('Error loading tractors: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Error loading tractors')),
//     );
//   }
// }
//
//
//
//   Future<void> _fetchMachineDetails() async {
//     try {
//       // Get token from SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String token = prefs.getString('auth_token') ?? '';
//
//       if (token.isEmpty) {
//         throw Exception('Authentication token not found');
//       }
//
//       final response = await http.post(
//         Uri.parse('${Constanst().base_url}machine-names'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//
//         if (responseData['status'] == 'success') {
//           final List<dynamic> machineData = responseData['data'];
//
//           setState(() {
//             // Store full machine data
//             _machines = machineData
//                 .map((machine) => {
//                       'id': machine['id'],
//                       'machine_name': machine['machine_name'],
//                       'machine_no': machine['machine_no'],
//                     })
//                 .toList();
//
//             // Create display names (you can customize this format)
//             _machineName = ['Select Machine'];
//             _machineName.addAll(_machines
//                 .map((machine) =>
//                     '${machine['machine_name']} (${machine['machine_no']})')
//                 .toList());
//
//             _filteredMachineNames = _machineName
//                 .where((machine) => machine != 'Select Machine')
//                 .toList();
//           });
//         } else {
//           throw Exception('API returned false success status');
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Something went wrong')),
//         );
//       }
//     } on SocketException {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please connect your internet')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Something went wrong')),
//       );
//     }
//   }
//
//   Future<void> fetchCategories() async {
//     print('📡 Starting fetchCategories API call...');
//     final prefs = await SharedPreferences.getInstance();
//
//     String? token = prefs.getString('auth_token');
//
//     // String token = "837|xXRfWEcM4dbIHT7WiprxXZdbm82yTKMK1izo7Uso62fea06b";
//
//     if (token!.isEmpty) {
//       print('⚠️ Token not found in SharedPreferences');
//       return;
//     }
//
//     print('✅ Token found: $token');
//
//     try {
//       final response = await http.post(
//         Uri.parse('${Constanst().base_url}manpower/categories'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Accept': 'application/json',
//           'Content-Type': 'application/json',
//         },
//       );
//
//       print('🔁 API call completed with status code: ${response.statusCode}');
//       print('📦 Raw response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final body = jsonDecode(response.body);
//
//         if (body['status'] == 'success') {
//           final List<dynamic> data = body['data'];
//
//           setState(() {
//             // Clear existing data
//             _manpowerTypes.clear();
//             _manpowerTypeNames = ['Select Man Power'];
//             _categoriesByType.clear();
//
//             // Process the hierarchical data
//             for (var typeData in data) {
//               int typeId = typeData['type_id'];
//               String typeName = typeData['type_name'];
//               List<dynamic> categoriesData = typeData['categories'];
//
//               // Store type information
//               _manpowerTypes.add({
//                 'type_id': typeId,
//                 'type_name': typeName,
//               });
//               _manpowerTypeNames.add(typeName);
//
//               // Store categories for this type
//               List<Map<String, dynamic>> typeCategories = [];
//               for (var categoryData in categoriesData) {
//                 typeCategories.add({
//                   'category_id': categoryData['category_id'],
//                   'category_name': categoryData['category_name'],
//                   'no_of_person': categoryData[
//                       'no_of_person'], // Keep this for reference if needed
//                 });
//               }
//               _categoriesByType[typeName] = typeCategories;
//             }
//
//             isLoading = false;
//           });
//
//           print('✅ Manpower types loaded: $_manpowerTypeNames');
//           print('✅ Categories by type: $_categoriesByType');
//         } else {
//           print('❌ API returned unsuccessful status');
//           setState(() => isLoading = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to load manpower data')),
//           );
//         }
//       } else {
//         print(
//             '❌ Failed to fetch categories. Status code: ${response.statusCode}');
//         setState(() => isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Something went wrong')),
//         );
//       }
//     } on SocketException {
//       print(' Error fetching categories: SocketException');
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please connect your internet')),
//       );
//     } catch (e) {
//       print('Error fetching categories: $e');
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Something went wrong')),
//       );
//     }
//   }
//
//
//
//   // showmachine drop down value
//
// void _showMachineBottomSheet(FormFieldState<Set<String>> state) {
//   TextEditingController searchController = TextEditingController();
//   List<String> filteredMachines = _machineName.where((machine) => machine != 'Select Machine').toList();
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (BuildContext context) {
//       return StatefulBuilder(
//         builder: (context, setBottomSheetState) {
//           return Container(
//             height: MediaQuery.of(context).size.height * 0.4,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//             ),
//             child: Column(
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: const BoxDecoration(
//                     color: Color(0xFF6B8E23),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.precision_manufacturing,
//                        color: Colors.white),
//                       const SizedBox(width: 10),
//                       Text(
//                         'Select Machines'.tr(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: "Poppins",
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon:  const Icon(Icons.close, color: Colors.white),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Search Box
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: TextField(
//                     controller: searchController,
//                     onChanged: (value) {
//                       setBottomSheetState(() {
//                         filteredMachines = _machineName
//                             .where((machine) =>
//                                 machine != 'Select Machine' &&
//                                 machine.toLowerCase().contains(value.toLowerCase()))
//                             .toList();
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search machines...'.tr(),
//                       prefixIcon: const Icon(Icons.search, color: Color(0xFF6B8E23)),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
//                       ),
//                     ),
//                   ),
//                 ),
//                 // List
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: filteredMachines.length,
//                     itemBuilder: (context, index) {
//                       final machine = filteredMachines[index];
//                       final isSelected = selectedMachines.contains(machine);
//                       return Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 8),
//                         decoration: BoxDecoration(
//                           color: isSelected ? const Color(0xFF6B8E23).withOpacity(0.1) : Colors.transparent,
//                           borderRadius: BorderRadius.circular(8),
//
//                         ),
//                         child: CheckboxListTile(
//                           checkboxShape: const CircleBorder(),
//                           title: Text(
//                             machine,
//                             style: TextStyle(
//                               fontFamily: "Poppins",
//                               fontSize: 14,
//                               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//                               color: isSelected ? const Color(0xFF6B8E23) : Colors.black87,
//                             ),
//                           ),
//                           value: isSelected,
//                           onChanged: (bool? selected) {
//                             setBottomSheetState(() {
//                               if (selected == true) {
//                                 selectedMachines.add(machine);
//                               } else {
//                                 selectedMachines.remove(machine);
//                               }
//                             });
//                             setState(() {
//                               state.didChange(selectedMachines);
//                             });
//                           },
//                           activeColor: const Color(0xFF6B8E23),
//                           controlAffinity: ListTileControlAffinity.leading,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );
// }
//
// // Tractor Bottom Sheet
// void _showTractorBottomSheet(FormFieldState<Set<String>> state) {
//   TextEditingController searchController = TextEditingController();
//   List<String> filteredTractors = _tractorName.where((tractor) => tractor != 'Select Tractor').toList();
//
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (BuildContext context) {
//       return StatefulBuilder(
//         builder: (context, setBottomSheetState) {
//           return Container(
//             height: MediaQuery.of(context).size.height * 0.4,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//             ),
//             child: Column(
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: const BoxDecoration(
//                     color: Color(0xFF6B8E23),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.agriculture, color: Colors.white),
//                       const SizedBox(width: 10),
//                       Text(
//                         'Select Tractors'.tr(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: "Poppins",
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.close, color: Colors.white),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Search Box
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: TextField(
//                     controller: searchController,
//                     onChanged: (value) {
//                       setBottomSheetState(() {
//                         filteredTractors = _tractorName
//                             .where((tractor) =>
//                                 tractor != 'Select Tractor' &&
//                                 tractor.toLowerCase().contains(value.toLowerCase()))
//                             .toList();
//                       });
//                     },
//                     decoration: InputDecoration(
//                       hintText: 'Search tractors...'.tr(),
//                       prefixIcon: const Icon(Icons.search, color: Color(0xFF6B8E23)),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
//                       ),
//                     ),
//                   ),
//                 ),
//                 // List
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: filteredTractors.length,
//                     itemBuilder: (context, index) {
//                       final tractor = filteredTractors[index];
//                       final isSelected = selectedTractors.contains(tractor);
//                       return Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(
//                           color: isSelected ? const Color(0xFF6B8E23).withOpacity(0.1) : Colors.transparent,
//                           borderRadius: BorderRadius.circular(8),
//                           // border: Border.all(
//                           //   color: isSelected ? const Color(0xFF6B8E23) : Colors.transparent,
//                           // ),
//                         ),
//                         child: CheckboxListTile(
//                           checkboxShape: const CircleBorder(),
//                           title: Text(
//                             tractor,
//                             style: TextStyle(
//                               fontFamily: "Poppins",
//                               fontSize: 14,
//                               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//                               color: isSelected ? const Color(0xFF6B8E23) : Colors.black87,
//                             ),
//                           ),
//                           value: isSelected,
//                           onChanged: (bool? selected) {
//                             setBottomSheetState(() {
//                               if (selected == true) {
//                                 selectedTractors.add(tractor);
//                               } else {
//                                 selectedTractors.remove(tractor);
//                               }
//                             });
//                             setState(() {
//                               state.didChange(selectedTractors);
//                             });
//                           },
//                           activeColor: const Color(0xFF6B8E23),
//                           controlAffinity: ListTileControlAffinity.leading,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );
// }
//
// // Manpower Categories Bottom Sheet
// void _showManpowerBottomSheet(FormFieldState<Set<String>> state) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (BuildContext context) {
//       return StatefulBuilder(
//         builder: (context, setBottomSheetState) {
//           return Container(
//             height: MediaQuery.of(context).size.height * 0.3,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(20),
//                 topRight: Radius.circular(20),
//               ),
//             ),
//             child: Column(
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: const BoxDecoration(
//                     color: Color(0xFF6B8E23),
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.groups, color: Colors.white),
//                       const SizedBox(width: 10),
//                       Text(
//                         'Manpower Categories'.tr(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: "Poppins",
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () => Navigator.pop(context),
//                         icon: const Icon(Icons.close, color: Colors.white),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // List
//                 Expanded(
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: categories.length,
//                     itemBuilder: (context, index) {
//                       final category = categories[index];
//                       final isSelected = selectedCategories.contains(category);
//                       return Container(
//                         margin: const EdgeInsets.symmetric(vertical: 2),
//                         decoration: BoxDecoration(
//                           color: isSelected ? const Color(0xFF6B8E23).withOpacity(0.1) : Colors.transparent,
//                           borderRadius: BorderRadius.circular(8),
//
//                         ),
//                         child: CheckboxListTile(
//                           checkboxShape: const CircleBorder(),
//                           title: Text(
//                             category.tr(),
//                             style: TextStyle(
//                               fontFamily: "Poppins",
//                               fontSize: 14,
//                               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
//                               color: isSelected ? const Color(0xFF6B8E23) : Colors.black87,
//                             ),
//                           ),
//                           value: isSelected,
//                           onChanged: (bool? selected) {
//                             setBottomSheetState(() {
//                               if (selected == true) {
//                                 selectedCategories.add(category);
//                               } else {
//                                 selectedCategories.remove(category);
//                                 if (controllers[category] != null) {
//                                   controllers[category]!.clear();
//                                 }
//                               }
//                             });
//                             setState(() {
//                               state.didChange(selectedCategories);
//                             });
//                           },
//                           activeColor: const Color(0xFF6B8E23),
//                           controlAffinity: ListTileControlAffinity.leading,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       );
//     },
//   );
// }
//
// }
