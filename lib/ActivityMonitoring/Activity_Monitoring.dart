import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart'; // Add this import for input formatters

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/Constants.dart';
import '../Dashboard/dashboard_screen.dart';

class Activity_Monitoring extends StatefulWidget {
  const Activity_Monitoring({super.key});

  @override
  State<Activity_Monitoring> createState() => Activity_monitoring();
}

class Activity_monitoring extends State<Activity_Monitoring> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';
  final TextEditingController _areaController = TextEditingController();
  // Text Controllers
  /*final TextEditingController _fuelConsumptionController = TextEditingController();*/

 /* final TextEditingController _majorMaintenanceController = TextEditingController();*/
 /* final TextEditingController _HSD_Consuption_Controller = TextEditingController();*/

  bool _isProcessing = false; // Processing state track karne ke liye


  // Focus nodes to track focus state
  final _levelingFocusNode = FocusNode();
  final _majorMaintenanceFocusNode = FocusNode();
  final _HSD_FocusNode = FocusNode();

  // Dropdown Values with default options
  final String _selectedSiteName = 'Select Site';
  String? _selectedBlockName = 'Select Block';
  String? _selectedPlotName = 'Select Plot';
  final String _selectedAreaName = 'Select Area';
  String? _selectedColorCondition = 'Select Condition'.tr();
  String? _selectedStage = 'Select Stage'.tr();
 /* String? _selectedLandQuality = 'Select Land Quality';*/

//  String? _selectedManPower = 'Select Man Power';


  // ID storage for API communication
  int? _selectedSiteId;
  int? _selectedBlockId;
  int? _selectedPlotId;
  double? _selectedArea;

  // Date and Time Controllers
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  /*File? _capturedImage;*/

  File? _capturedImage;
  String? _currentAddress;
  double? _latitude;
  double? _longitude;
  DateTime? _captureTime;
  loc.Location location = loc.Location();
  bool _isLoading = false;




  // API Data
  final List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _plots = [];

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'];
  List<String> _plotNames = ['Select Plot'];
  final List<String> _areaOptions = ['Select Area'];
  final List<String> _tractorName = ['Select Tractor'];
//  List<String> _manPowerName = ['Select Man Power'];

  final List<String> _stageName = [
    'Select Stage', 'Vegetative', 'Flowering', 'Harvesting'
  ];
  final List<String> _leafColorCondition = [
    'Select Condition', 'Yellowing', 'Healthy', 'Drying'
  ];





  bool showCheckboxes = false;
  bool isLoading = true;

  Map<String, TextEditingController> controllers = {};
  Map<String, FocusNode> focusNodes = {};


  Future<bool> _onWillPop() async {
    // Navigate to dashboard screen when back button is pressed
    Navigator.pushReplacementNamed(context, '/dashboard');
    return false; // Prevents default back behavior
  }


  @override
  void initState() {
    super.initState();
    _fetchBlocksAndPlots();




    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });
    _majorMaintenanceFocusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _fetchBlocksAndPlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}site-blocks-plots'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final List<dynamic> blocksData = responseData['data'];

          setState(() {
            // Reset arrays
            _blocks = [];
            _blockNames = ['Select Block'];

            // Process blocks data - UPDATED to store block_id
            for (var block in blocksData) {
              _blocks.add({
                'block_id': block['block_id'], // Store block_id
                'block_name': block['block_name'],
                'plots': block['plots'],
              });
              _blockNames.add(block['block_name'].toString());
            }

            // Initialize plot dropdown with just the default option
            _plots = [];
            _plotNames = ['Select Plot'];

            // Reset area text
            _areaText = '';
            _selectedArea = null;

            _isLoading = false;
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }


// Update plots based on selected block
  void _updatePlots(String blockName) {
    if (blockName == 'Select Block') {
      setState(() {
        _plots = [];
        _plotNames = ['Select Plot'];
        _selectedPlotName = 'Select Plot';
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
        _selectedBlockId = null; // Reset block ID too
      });
      return;
    }

    final selectedBlock = _blocks.firstWhere(
          (block) => block['block_name'] == blockName,
      orElse: () => {},
    );

    if (selectedBlock.isNotEmpty) {
      setState(() {
        _selectedBlockId = selectedBlock['block_id']; // Store actual block_id from API

        // Reset subsequent selections
        _selectedPlotName = 'Select Plot';
        _selectedPlotId = null;
        _selectedArea = null;
        _areaText = '';

        // Update plots for the selected block - UPDATED to store plot_id
        final List<dynamic> plotsData = selectedBlock['plots'];
        _plots = List<Map<String, dynamic>>.from(plotsData.map((plot) => {
          'plot_id': plot['plot_id'], // Store plot_id
          'plot_name': plot['plot_name'],
          'area': plot['area'],
        }));

        _plotNames = ['Select Plot'];
        _plotNames.addAll(
            _plots.map((plot) => plot['plot_name'].toString()).toList());
      });
    }
  }


// Update area based on selected plot
  void _updateAreaText(String plotName) {
    if (plotName == 'Select Plot') {
      setState(() {
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
      });
      return;
    }

    final selectedPlot = _plots.firstWhere(
          (plot) => plot['plot_name'] == plotName,
      orElse: () => {},
    );

    if (selectedPlot.isNotEmpty) {
      setState(() {
        _selectedPlotId = selectedPlot['plot_id']; // Store actual plot_id from API
        _selectedArea = double.tryParse(selectedPlot['area'].toString());
        _areaText = '${selectedPlot['area']} ';
      });
    }
  }


  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
  /*  _fuelConsumptionController.dispose();*/
    _areaController.dispose();
   /* _majorMaintenanceController.dispose();*/
    _levelingFocusNode.dispose();
    _majorMaintenanceFocusNode.dispose();



    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
  Widget _buildImageCapture({
    required String labelText,
    bool isRequired = true,
    Function()? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 15.0),
            child: Text(
              labelText + (isRequired ? ' *' : ''),
              style: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins"
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: _capturedImage != null
                    ? Stack(
                  children: [
                    // Image widget
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.file(
                        _capturedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Processing loader overlay
                    if (_isProcessing)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: "Poppins",
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Icon(
                        Icons.add,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_capturedImage != null)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentAddress != null)
                    Text(
                      'Address: $_currentAddress',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.0,
                        fontFamily: "Poppins",
                      ),
                    ),
                  if (_latitude != null && _longitude != null)
                    Text(
                      'Location: $_latitude, $_longitude',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.0,
                        fontFamily: "Poppins",
                      ),
                    ),
                  if (_captureTime != null)
                    Text(
                      'Time: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_captureTime!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12.0,
                        fontFamily: "Poppins",
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





  Widget _buildCustomTextField({
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool isRequired = true,
    String? Function(String?)? customValidator,
    int? maxLength, // Add maxLength parameter
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength, // Set max length
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null, // Add input formatter for length limiting
      validator: customValidator ?? (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $labelText';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' *' : ''),
        labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            fontFamily: "Poppins"
        ),
        hintText: hintText ?? 'Enter $labelText',
        hintStyle: const TextStyle(
            fontFamily: "Poppins",
            fontSize: 14.0,
            color: Colors.grey
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 15.0,
            horizontal: 20.0
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(
            color: Color(0xFF6B8E23),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        counterText: "", // Hide the counter text that shows "0/4"
      ),
    );
  }


Widget _buildCustomDropdown({
  required String labelText,
  required String? selectedValue,
  required List<String> items,
  required Function(String?) onChanged,
  bool isRequired = true,
}) {
  // Remove duplicates as safety measure
  final uniqueItems = items.toSet().toList();
  
  // Ensure selectedValue exists in the list
  String? safeSelectedValue = selectedValue;
  if (safeSelectedValue != null && !uniqueItems.contains(safeSelectedValue)) {
    safeSelectedValue = uniqueItems.first;
  }
  
  return DropdownButtonFormField<String>(
    isDense: true,
    isExpanded: true,
    menuMaxHeight: 300,
    validator: (value) {
      if (isRequired && (value == null || value.startsWith('Select'))) {
        return 'Please select $labelText';
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: labelText + (isRequired ? ' *' : ''),
      labelStyle: const TextStyle(
          color: Color(0xFF6B8E23),
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
          fontFamily: "Poppins"
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 20.0
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: BorderSide(
          color: Colors.grey.shade400,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20.0),
        borderSide: const BorderSide(
          color: Color(0xFF6B8E23),
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFF6B8E23),
      ),
    ),
    value: safeSelectedValue,
    items: uniqueItems.map((name) {
      return DropdownMenuItem<String>(
        value: name,
        child: Text(
          name,
          style: TextStyle(
            color: name.startsWith('Select') ? Colors.grey : Colors.black,
            fontFamily: "Poppins",
            fontSize: 14.0,
          ),
        ),
      );
    }).toList(),
    onChanged: onChanged,
    icon: const SizedBox.shrink(),
    dropdownColor: Colors.white,
    style: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontFamily: "Poppins",
    ),
  );
}



  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      try {
        // Get token from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = prefs.getString('auth_token') ?? '';
        int? userId = prefs.getInt('user_id');
        if (token.isEmpty) {
          throw Exception('Authentication token not found');
        }

        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${Constanst().base_url}activity-monitoring'),
        );

        // Add authorization header
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        request.fields['block_name'] = '7';
        request.fields['plot_name'] = '9';
        request.fields['area'] = _selectedArea?.toString() ?? '';
        request.fields['activity_stage'] = _selectedStage == 'Select Stage' ? '' : _selectedStage ?? '';
        request.fields['leaf_condition'] = _selectedColorCondition == 'Select Condition' ? '' : _selectedColorCondition ?? '';
        request.fields['area_covered'] = _areaController.text;
        request.fields['user_id'] = userId.toString(); // Use actual user ID from SharedPreferences
        /*request.fields['user_id'] = '1';*/

        // Add image file if available
        if (_capturedImage != null) {
          // Add image file to the request
          request.files.add(
            await http.MultipartFile.fromPath(
              'image_path', // This should match the field name expected by your API
              _capturedImage!.path,
              contentType: MediaType('image', 'jpeg'), // Adjust based on image type
            ),
          );
        } else {
          // If no image is provided and it's required, show an error
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please capture an image'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Send the request
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Parse response
          final responseData = json.decode(response.body);
          print("API Response: $responseData");

          // Success - show toast message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Details submitted successfully'),
              backgroundColor: Color(0xFF6B8E23),
              duration: Duration(seconds: 3),
            ),
          );

          // Clear form fields
          _resetForm();
        } else {
          // Error handling
          final errorData = jsonDecode(response.body);
          String errorMessage = errorData['message'] ?? 'Failed to submit data';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

////////////////////////////// adding silver app bar //////////////////////////////////////////////


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Connect to the back button handler
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 148.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF6B8E23),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) =>  const DashboardScreen()),
                    );
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title:  Text(
                    'Activity Monitoring'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                  background: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6B8E23),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/circle_logo.png',
                          width: 100,
                          height: 60,
                        ),
                        const SizedBox(height: 10),
                      ],
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
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B8E23)),
          ))
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Block Name Dropdown
                  _buildCustomDropdown(
                    labelText: 'Block Name'.tr(),
                    selectedValue: _selectedBlockName,
                    items: _blockNames,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedBlockName = value;
                        });
                        _updatePlots(value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Plot Name Dropdown
                  _buildCustomDropdown(
                    labelText: 'Plot Name'.tr(),
                    selectedValue: _selectedPlotName,
                    items: _plotNames,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPlotName = value;
                        });
                        _updateAreaText(value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Area Text Field (Read-only)
                  TextFormField(
                    controller: TextEditingController(text: _areaText),
                    readOnly: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: "Poppins",
                    ),
                    decoration: InputDecoration(
                      labelText: 'Area (Acre)'.tr(),
                      hintText: 'Enter a Total Area'.tr(),
                      labelStyle: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                          fontFamily: "Poppins"
                      ),
                      hintStyle: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 14.0,
                          color: Colors.grey
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 20.0
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF6B8E23),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (_selectedArea == null) {
                        return 'Please select a plot first'.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Area Covered TextField
                  _buildCustomTextField(
                    labelText: 'Area Covered'.tr(),
                    hintText: 'Enter Area'.tr(),
                    controller: _areaController,
                    focusNode: _levelingFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true), // Number keyboard with decimal
                    maxLength: 5, 
                  ),

                  const SizedBox(height: 20),

                  // Activity Stage Dropdown
                  _buildCustomDropdown(
                    labelText: 'Activity Stage'.tr(),
                    selectedValue: _selectedStage,
                    items: _stageName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStage = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Leaf Color and Condition Dropdown
                  _buildCustomDropdown(
                    labelText: 'Leaf Color and Condition'.tr(),
                    selectedValue: _selectedColorCondition,
                    items: _leafColorCondition,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedColorCondition = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Image Capture
                  _buildImageCapture(
                    labelText: 'Capture Image'.tr(),
                    onTap: () {
                      _captureAndProcessImage();
                    },
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: SizedBox(
                      width: 100,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B8E23),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child:  Text(
                          'Submit'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }




 ////////////////////////////////////////////////////////////////////////////////////////////
  void _resetForm() {
    setState(() {
      _selectedBlockName = 'Select Block';
      _selectedPlotName = 'Select Plot';
      _areaText = '';
      _selectedArea = null;
      _selectedBlockId = null;
      _selectedPlotId = null;
      _selectedColorCondition = 'Select Condition';
      _selectedStage = 'Select Stage';

      _areaController.clear();
      _startDate = null;
      _startTime = null;
      _endTime = null;

      // Add this line to clear the captured image
      _capturedImage = null;

      // Clear selected categories and their values
      for (var controller in controllers.values) {
        controller.clear();
      }

      // Reset dropdowns
_updatePlots('Select Block');

      // Reset form validation
      _formKey.currentState?.reset();
    });
  }

  Future<void> _captureAndProcessImage() async {
    // Check and request permissions
    final cameraPermission = await _requestCameraPermission();
    final locationPermission = await _requestLocationPermission();

    if (cameraPermission) {
      try {
        // Capture image
        final pickedFile = await _pickImageFromCamera();
        if (pickedFile != null) {
          // Set captured image immediately and show processing indicator
          setState(() {
            _capturedImage = File(pickedFile.path);
            _isProcessing = true; // Show processing loader
          });

          // Record the time
          _captureTime = DateTime.now();

          // Get location if permission granted
          if (locationPermission) {
            await _getCurrentLocation();
          }

          // Process the image - add metadata
          final editedImageFile = await _addMetadataToImage(File(pickedFile.path));

          setState(() {
            _capturedImage = editedImageFile;
            _isProcessing = false; // Hide processing loader
          });
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show permission denied message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to capture images'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Function to get current location with modified address formatting
  Future<void> _getCurrentLocation() async {
    try {
      final currentLocation = await location.getLocation();
      _latitude = currentLocation.latitude;
      _longitude = currentLocation.longitude;

      // Get address from coordinates without house number
      if (_latitude != null && _longitude != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Remove house number from address, only include street, locality, etc.
          _currentAddress = "${place.thoroughfare ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}";

          // Clean up the address by removing extra commas
          _currentAddress = _currentAddress!.replaceAll(RegExp(r', ,'), ',');
          _currentAddress = _currentAddress!.replaceAll(RegExp(r'^, '), '');
          _currentAddress = _currentAddress!.replaceAll(RegExp(r', $'), '');
        }
      }
    } catch (e) {
      print("Error getting location: $e");
      // Handle error, maybe set default values or show error message
    }
  }

  Future<File> _addMetadataToImage(File originalImage) async {
    try {
      // Read the original image
      final imageBytes = await originalImage.readAsBytes();
      final originalImageDecoded = img.decodeImage(imageBytes);

      if (originalImageDecoded == null) {
        throw Exception("Could not decode image");
      }

      // Create a copy of the image for editing
      final editedImage = img.copyResize(originalImageDecoded, width: originalImageDecoded.width);

      // Prepare metadata text
      final String dateTimeText = _captureTime != null
          ? "Date & Time: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_captureTime!)}"
          : "Date & Time: Not Available";

      final String locationText = _latitude != null && _longitude != null
          ? "Location: $_latitude, $_longitude"
          : "Location: Not Available";

      final String addressText = _currentAddress != null
          ? "Address: $_currentAddress"
          : "Address: Not Available";

      // Increased banner height for better readability
      const int bannerHeight = 180;
      final int startY = editedImage.height - bannerHeight;

      // Make text fully visible without background by skipping the overlay completely
      // This will make text appear directly on the image without any background

      // Set text color to white with slight black outline effect for better visibility on any background
      final textColor = img.ColorRgba8(255, 255, 255, 255); // Fully opaque white text

      // Draw text directly on image without overlay
      img.drawString(
          editedImage,
          dateTimeText,
          font: img.arial48,
          x: 10,
          y: editedImage.height - bannerHeight + 20,
          color: textColor
      );

      img.drawString(
          editedImage,
          locationText,
          font: img.arial48,
          x: 10,
          y: editedImage.height - bannerHeight + 60,
          color: textColor
      );

      img.drawString(
          editedImage,
          addressText,
          font: img.arial48,
          x: 10,
          y: editedImage.height - bannerHeight + 100,
          color: textColor
      );

      // Save the edited image
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String editedImagePath = '${appDocDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File editedImageFile = File(editedImagePath);

      await editedImageFile.writeAsBytes(img.encodeJpg(editedImage, quality: 90));

      return editedImageFile;
    } catch (e) {
      print("Error editing image: $e");
      // Return original image in case of error
      return originalImage;
    }
  }



  Widget _buildImageWidget() {
    if (_capturedImage == null) {
      return const Center(
        child: Text('No image captured yet'),
      );
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.file(_capturedImage!),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }
  }

// Request for camera permission
  Future<bool> _requestCameraPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return false;
  }

// Request for location permission
  Future<bool> _requestLocationPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.location.status;
      if (status.isDenied) {
        final result = await Permission.location.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return false;
  }

// Your existing image picker function
  Future<XFile?> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Reduce image size for faster upload
      );
      return photo;
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return null;
    }
  }
}
