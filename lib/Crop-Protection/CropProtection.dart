import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Dashboard/dashboard_screen.dart';
import '../widget/Constants.dart';
// This should already be there, but make sure it includes FilteringTextInputFormatter



class Cropprotection extends StatefulWidget {
  const Cropprotection({super.key});

  @override
  State<Cropprotection> createState() => crop_protection();
}

class crop_protection extends State<Cropprotection> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';

  // Text Controllers
  final TextEditingController _fuelConsumptionController =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _HSD_Consuption_Controller =
      TextEditingController();

  // Focus nodes to track focus state
  final _levelingFocusNode = FocusNode();
  final _majorMaintenanceFocusNode = FocusNode();
  final _HSD_FocusNode = FocusNode();

  // Dropdown Values with default options
  final String _selectedSiteName = 'Select Site';
  String? _selectedBlockName = 'Select Block';
  String? _selectedPlotName = 'Select Plot';
  final String _selectedAreaName = 'Select Area';
/*  String? _selectedTractor = 'Select Tractor';
  String? _selectedMachine = 'Select Machine';*/

  String? _selectedApplication = 'Select Method'.tr();
  final String _selectedCompany = 'Select Company';

  final String _selectedUOM = 'Select UOM';
  String? _selectedStageSource = 'Select Stage Source'.tr();
  String? _selectedManPowerRoll = 'Select ManPower';

  int? _selectedchemicalId;

  final String _selectedIngredient = 'Select Ingredients';
  List<String> _chemicalNames = ['Select Ingredients'];
  Map<String, int> _chemicalIdMap = {};
  Set<String> selectedIngredients = <String>{};
  List<String> _filteredChemicalNames = [];
  bool showIngredientDropdown = false;
  final TextEditingController _ingredientSearchController =
      TextEditingController();
  Map<String, Map<String, dynamic>> selectedIngredientData = {};

  final String _selectedLandQuality = 'Select Land Quality';

//  String? _selectedManPower = 'Select Man Power';

  // ID storage for API communication
  int? _selectedSiteId;
  int? _selectedBlockId;
  int? _selectedPlotId;
  double? _selectedArea;
/*

  // Date and Time Controllers
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
*/

  DateTime? _startDate = DateTime.now();
  TimeOfDay? _startTime = TimeOfDay.now();
  TimeOfDay? _endTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 4)));

  // API Data
  final List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _plots = [];

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'];
  List<String> _plotNames = ['Select Plot'];
  final List<String> _areaOptions = ['Select Area'];
  // List<String> _tractorName = ['Select Tractor'];

//  List<String> _manPowerName = ['Select Man Power'];

  List<Map<String, dynamic>> _tractorData = [];
  List<Map<String, dynamic>> _machineData = [];
  List<String> _tractorDisplayNames = ['Select Tractor'];
  List<String> _machineDisplayNames = ['Select Machine'];

  // Add these variables at the top with other declarations
  final List<Map<String, dynamic>> _manpowerTypes = [];
  List<String> _manpowerTypeNames = ['Select Man Power'.tr()];
  List<Map<String, dynamic>> _filteredCategories = [];
  List<String> _filteredCategoryNames = ['Select Category'.tr()];

final Map<String, Map<String, dynamic>> _chemicalDataMap = {};
  final Map<String, List<Map<String, dynamic>>> _categoriesByType = {};



  final List<String> _applicationMethodName = [
    'Select Method',
    'Spray',
    'Drip Irrigation',
    'Drenching',
    'Soil Application'
  ];
  final List<String> _CompanyMethodName = [
    'Select Company',
    'Bayer',
    'Syngenta',
    'UPL',
    'BASF'
  ];


  final List<String> _StageSourceName = [
    'Select Stage Source',
    'Pre-Emergence',
    'Post-Emergence',
    'Vegetative Stage',
    'Flowering Stage'
  ];



  bool _isLoading = true;

  bool showCheckboxes = false;
  bool isLoading = true;

  List<String> categories = [];
  Set<String> selectedCategories = {};

  Map<String, TextEditingController> controllers = {};
  Map<String, FocusNode> focusNodes = {};

  final String _selectedTractor = 'Select Tractor';
  Set<String> selectedTractors = {};
  final List<String> _tractorName = ['Select Tractor'];
  bool showTractorDropdown = false;
  final TextEditingController _tractorSearchController =
      TextEditingController();
  List<String> _filteredTractorNames = [];

  final String _selectedMachine = 'Select Machine';
  Set<String> selectedMachines = {};
  final List<String> _machineName = ['Select Machine'];
  bool showMachineDropdown = false;
  final TextEditingController _machineSearchController =
      TextEditingController();
  List<String> _filteredMachineNames = [];

  // Map to store the relationship between display names and original API category names
  Map<String, String> categoryMapping = {};
// List to store display category names
  List<String> displayCategories = [];

  Future<bool> _onWillPop() async {
    // Navigate to dashboard screen when back button is pressed
    Navigator.pushReplacementNamed(context, '/dashboard');
    return false; // Prevents default back behavior
  }

  @override
  void initState() {
    super.initState();
    _fetchBlocksAndPlots();
    _machineDisplayNames = ['Select Machine']; // Changed from _machineName
    _tractorDisplayNames = ['Select Tractor']; // Add this line
    _fetchMachineDetails();
    _fetchTractorDetails();

    _fetchChemicalDetails();
    fetchCategories();
    initializeManpowerCategories();

    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });
  }

  void initializeManpowerCategories() {
    categories = ['Unskilled', 'Semi Skilled 1', 'Semi Skilled 2'];
    // Initialize empty controllers and focus nodes maps
    controllers.clear();
    focusNodes.clear();
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


  Widget _buildIngredientSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedIngredients,
     // NEW VALIDATOR
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Please select at least one ingredient';
  }
  return null;
},

      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ingredient selection dropdown
            TextFormField(
              controller: _ingredientSearchController,
              readOnly: !showIngredientDropdown,
              onTap: () {
                setState(() {
                  showIngredientDropdown = true;
                  if (_ingredientSearchController.text.isNotEmpty) {
                    _filteredChemicalNames = _chemicalNames
                        .where((ingredient) =>
                            ingredient != 'Select Ingredients' &&
                            ingredient.toLowerCase().contains(
                                _ingredientSearchController.text.toLowerCase()))
                        .toList();
                  } else {
                    _filteredChemicalNames = _chemicalNames
                        .where(
                            (ingredient) => ingredient != 'Select Ingredients')
                        .toList();
                  }
                });
              },
              onChanged: (value) {
                setState(() {
                  _filteredChemicalNames = _chemicalNames
                      .where((ingredient) =>
                          ingredient != 'Select Ingredients' &&
                          ingredient
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Active Ingredients *'.tr(),
                errorText: state.errorText,
                labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins",
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide:
                      const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: selectedIngredients.isEmpty
                    ? 'Search or select ingredients'.tr()
                    : selectedIngredients.join(', '),
                hintStyle: TextStyle(
                  color:
                      selectedIngredients.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showIngredientDropdown
                    ? const Icon(Icons.search, color: Color(0xFF6B8E23))
                    : null,
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      showIngredientDropdown = !showIngredientDropdown;
                      if (showIngredientDropdown &&
                          _ingredientSearchController.text.isNotEmpty) {
                        _filteredChemicalNames = _chemicalNames
                            .where((ingredient) =>
                                ingredient != 'Select Ingredients' &&
                                ingredient.toLowerCase().contains(
                                    _ingredientSearchController.text
                                        .toLowerCase()))
                            .toList();
                      } else if (showIngredientDropdown) {
                        _filteredChemicalNames = _chemicalNames
                            .where((ingredient) =>
                                ingredient != 'Select Ingredients')
                            .toList();
                      }
                    });
                  },
                  child: Icon(
                    showIngredientDropdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
                  ),
                ),
              ),
            ),

            // Dropdown list
            if (showIngredientDropdown)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(top: 8.0),
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredChemicalNames.length,
                  itemBuilder: (context, index) {
                    final ingredient = _filteredChemicalNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        ingredient,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedIngredients.contains(ingredient),
                      onChanged: (bool? selected) {
                        setState(() {

                          if (selected == true) {
  selectedIngredients.add(ingredient);
  // Get chemical data from API response
  var chemicalData = _chemicalDataMap[ingredient];
  
  // Initialize data for the selected ingredient with API values
  selectedIngredientData[ingredient] = {
    'dose': TextEditingController(),  // This creates a new controller
    'uom': chemicalData?['uom'] ?? 'Select UOM',
    'company': chemicalData?['brand_name'] ?? 'Select Company',
    'id': chemicalData?['id'] ?? 0,
  };
}
                          
                           else {
                            selectedIngredients.remove(ingredient);
                            // Clean up data for deselected ingredient
                            selectedIngredientData[ingredient]?['dose']
                                ?.dispose();
                            selectedIngredientData.remove(ingredient);
                          }
                          state.didChange(selectedIngredients);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B8E23),
                    );
                  },
                ),
              ),

            // Dynamic dose, UOM, and company fields for selected ingredients
            if (selectedIngredients.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Ingredient Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B8E23),
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 10),
              ...selectedIngredients
                  .map((ingredient) => _buildIngredientDetailCard(ingredient)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildIngredientDetailCard(String ingredient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ingredient,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B8E23),
                fontFamily: "Poppins",
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Row for Dose, UOM, and Company with equal spacing
            Row(
              children: [
                // Dose field
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    onTap: () {
                      _closeAllDropdowns();
                    },
                    controller: selectedIngredientData[ingredient]?['dose'] ?? TextEditingController(),                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  //  maxLength: 2, // Changed from no limit to 2 digits
  inputFormatters: [
    LengthLimitingTextInputFormatter(2),
    FilteringTextInputFormatter.digitsOnly, // Only allow digits
  ],
                  
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: "Poppins",
                    ),
                    decoration: InputDecoration(
                      labelText: 'Dose *',
                      hintText: 'Enter',
                      labelStyle: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.0,
                          fontFamily: "Poppins"),
                      hintStyle: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 10.0,
                          color: Colors.grey),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF6B8E23),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter dose';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // UOM dropdown
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 48, // Fixed height
              child: TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: selectedIngredientData[ingredient]!['uom']
                ),
                decoration: InputDecoration(
                  labelText: 'UOM',
                  labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
            fontWeight: FontWeight.bold,
            fontSize: 10.0,
            fontFamily: "Poppins"),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: const EdgeInsets.symmetric(
            vertical: 8.0, horizontal: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                style: const TextStyle(fontFamily: "Poppins", fontSize: 11),
              ),
            ),
          ),

                const SizedBox(width: 8),

                // Company dropdown
             Expanded(
              flex :1,
               child: SizedBox(
                 height: 48, // Fixed height
                 child: TextFormField(
                   readOnly: true,
                   controller: TextEditingController(
                     text: selectedIngredientData[ingredient]!['company']
                   ),
                   decoration: InputDecoration(
                     labelText: 'Company',
                     labelStyle: const TextStyle(
                         color: Color(0xFF6B8E23),
                         fontWeight: FontWeight.bold,
                         fontSize: 10.0,
                         fontFamily: "Poppins"),
                     floatingLabelBehavior: FloatingLabelBehavior.always,
                     contentPadding: const EdgeInsets.symmetric(
                         vertical: 8.0, horizontal: 12.0),
                     border: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12.0),
                       borderSide: const BorderSide(color: Colors.grey, width: 1),
                     ),
                     enabledBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12.0),
                       borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                     ),
                     focusedBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(12.0),
                       borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 1.5),
                     ),
                     filled: true,
                     fillColor: Colors.grey[100],
                   ),
                   style: const TextStyle(fontFamily: "Poppins", fontSize: 11),
                 ),
               ),
             ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    _fuelConsumptionController.dispose();
    _areaController.dispose();
    _doseController.dispose();
    /*  _majorMaintenanceController.dispose();*/
    _levelingFocusNode.dispose();
/*
    _majorMaintenanceFocusNode.dispose();
*/

    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _closeAllDropdowns() {
    setState(() {
      showMachineDropdown = false;
      showTractorDropdown = false;
      showCheckboxes = false;
      showIngredientDropdown = false;
    });
  }

  Widget _buildMachineSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedMachines,
      validator: (value) {
        // Machine selection is now optional - no validation required
        // You can remove this validator completely or keep it for other validations
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only one input field that acts as both the selection display and search field
            TextFormField(
              controller: _machineSearchController,
              readOnly: !showMachineDropdown,
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showMachineDropdown = true;
                  _machineSearchController.clear();

                  _filteredMachineNames =
                      _machineDisplayNames // Changed from _machineName
                          .where((machine) => machine != 'Select Machine')
                          .toList();
                });
              },
              onChanged: (value) {
                setState(() {
                  // Filter machine names based on search input
                  _filteredMachineNames = _machineDisplayNames
                      .where((machine) =>
                          machine != 'Select Machine' &&
                          machine.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText:
                    'Machine (Optional)'.tr(), // Changed label text to indicate it's optional
                errorText: state.errorText,
                labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins",
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide:
                      const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: selectedMachines.isEmpty
                    ? 'Search or select machine'.tr()
                    : selectedMachines.join(', '),
                hintStyle: TextStyle(
                  color: selectedMachines.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showMachineDropdown
                    ? const Icon(Icons.search, color: Color(0xFF6B8E23))
                    : null,
                suffixIcon: IconButton(
                  onPressed: showMachineDropdown
                      ? () {
                          // _closeAllDropdowns();
                          setState(() {
                            // Toggle dropdown when arrow is clicked
                            showMachineDropdown = !showMachineDropdown;

                            if (showMachineDropdown &&
                                _machineSearchController.text.isNotEmpty) {
                              // If dropdown is being opened, keep the filtered list
                              _filteredMachineNames = _machineName
                                  .where((machine) =>
                                      machine != 'Select Machine' &&
                                      machine.toLowerCase().contains(
                                          _machineSearchController.text
                                              .toLowerCase()))
                                  .toList();
                            } else if (showMachineDropdown) {
                              // Reset filtered list when opening dropdown without search
                              _filteredMachineNames = _machineName
                                  .where(
                                      (machine) => machine != 'Select Machine')
                                  .toList();
                            } else {
                              // Clear search text when closing dropdown
                              _machineSearchController.clear();
                              // Reset filtered list to all machines
                              _filteredMachineNames = _machineName
                                  .where(
                                      (machine) => machine != 'Select Machine')
                                  .toList();
                            }
                          });
                        }
                      : null,
                  icon: Icon(
                    showMachineDropdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
                  ),
                ),
              ),
            ),

            if (showMachineDropdown)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(top: 8.0),
                height: 200, // Fixed height for the dropdown list
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredMachineNames.length,
                  itemBuilder: (context, index) {
                    final machine = _filteredMachineNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        machine,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedMachines.contains(machine),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedMachines.add(machine);
                          } else {
                            selectedMachines.remove(machine);
                          }

                          state.didChange(selectedMachines);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B8E23),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTractorSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedTractors,
      validator: (value) {
        return null; // Always return null to make it optional
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input field - label में भी * हटा दें optional के लिए
            TextFormField(
              controller: _tractorSearchController,
              readOnly: !showTractorDropdown,
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showTractorDropdown = true;
                  _tractorSearchController.clear();
                  // Reset filtered list when opening dropdown
                  _filteredTractorNames =
                      _tractorDisplayNames // Changed from _tractorName
                          .where((tractor) => tractor != 'Select Tractor')
                          .toList();
                });
              },
              onChanged: (value) {
                setState(() {
                  _filteredTractorNames =
                      _tractorDisplayNames // Changed from _tractorName
                          .where((tractor) =>
                              tractor != 'Select Tractor' &&
                              tractor
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                          .toList();
                });
              },
              decoration: InputDecoration(
                labelText:
                    'Tractor (Optional)'.tr(), // * हटाया गया और Optional जोड़ा गया
                errorText: state.errorText,
                labelStyle: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins",
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15.0,
                  horizontal: 20.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide:
                      const BorderSide(color: Color(0xFF6B8E23), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                hintText: selectedTractors.isEmpty
                    ? 'Search or select tractor'.tr()
                    : selectedTractors.join(', '),
                hintStyle: TextStyle(
                  color: selectedTractors.isEmpty ? Colors.grey : Colors.black,
                  fontFamily: "Poppins",
                  fontSize: 14,
                ),
                prefixIcon: showTractorDropdown
                    ? const Icon(Icons.search, color: Color(0xFF6B8E23))
                    : null,
                suffixIcon: IconButton(
                  onPressed: showTractorDropdown
                      ? () {
                          // _closeAllDropdowns();
                          setState(() {
                            showTractorDropdown = !showTractorDropdown;

                            if (showTractorDropdown &&
                                _tractorSearchController.text.isNotEmpty) {
                              _filteredTractorNames = _tractorName
                                  .where((tractor) =>
                                      tractor != 'Select Tractor' &&
                                      tractor.toLowerCase().contains(
                                          _tractorSearchController.text
                                              .toLowerCase()))
                                  .toList();
                            } else if (showTractorDropdown) {
                              _filteredTractorNames = _tractorName
                                  .where(
                                      (tractor) => tractor != 'Select Tractor')
                                  .toList();
                            } else {
                              // Clear search text when closing dropdown
                              _tractorSearchController.clear();
                              // Reset filtered list to all tractors
                              // In the toggle dropdown section:
                              _filteredTractorNames =
                                  _tractorDisplayNames // Changed from _tractorName
                                      .where((tractor) =>
                                          tractor != 'Select Tractor')
                                      .toList();
                            }
                          });
                        }
                      : null,
                  icon: Icon(
                    showTractorDropdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF6B8E23),
                  ),
                ),
              ),
            ),

            if (showTractorDropdown)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                margin: const EdgeInsets.only(top: 8.0),
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredTractorNames.length,
                  itemBuilder: (context, index) {
                    final tractor = _filteredTractorNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        tractor,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedTractors.contains(tractor),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedTractors.add(tractor);
                          } else {
                            selectedTractors.remove(tractor);
                          }
                          state.didChange(selectedTractors);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B8E23),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B8E23), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        }
      });
    }
  }

// Modified _selectTime method with initialTime set to current time or existing selection
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B8E23), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

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
      onTap: () {
        setState(() {
          _closeAllDropdowns();
        });
      },
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength, // Set max length
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null, // Add input formatter for length limiting
      validator: customValidator ??
          (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Please enter $labelText';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' ' : ''),
        labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            fontFamily: "Poppins"),
        hintText: hintText ?? 'Enter $labelText',
        hintStyle: const TextStyle(
            fontFamily: "Poppins", fontSize: 14.0, color: Colors.grey),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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
    required List items,
    required Function(String?) onChanged,
  }) {
    final bool valueExists =
        selectedValue != null && items.contains(selectedValue);
    final String? safeValue = valueExists ? selectedValue : null;

    return DropdownButtonFormField<String>(
      onTap: () {
        setState(() {
          _closeAllDropdowns();
        });
      },
      isDense: true,
      isExpanded: true,
      menuMaxHeight: 300,
      validator: (value) {
        // Special case: Make Type of Man Power optional
        if (labelText == 'Type of Man Power' ||
            labelText == 'Type of Man Power ') {
          return null; // No validation for Type of Man Power
        }

        if (value == null || value.startsWith('Select')) {
          return 'Please select $labelText'.tr();
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText.tr() +
            (labelText == 'Type of Man Power' ||
                    labelText == 'Type of Man Power '
                ? ''
                : ' *'),
        labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
            fontWeight: FontWeight.bold,
            fontSize: 12.0,
            fontFamily: "Poppins"),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
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
      value: safeValue,
      items: items.map<DropdownMenuItem<String>>((name) {
        return DropdownMenuItem<String>(
          value: name,
          child: Text(
            name,
            style: TextStyle(
              color:
                  name.startsWith('Select'.tr()) ? Colors.grey : Colors.black,
              fontFamily: "Poppins",
              fontSize: 12.0,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const SizedBox.shrink(), // Remove default dropdown icon
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: "Poppins",
      ),
      hint: Text(
        "Select ${labelText.split(' ')[0]}".tr(),
        style: const TextStyle(
          color: Colors.grey,
          fontFamily: "Poppins",
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildManpowerSection() {
    return FormField<Set<String>>(
      initialValue: selectedCategories,
      validator: null, // No validation - optional field
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                // Only allow opening if a manpower type is selected
                if (_selectedManPowerRoll != null &&
                    _selectedManPowerRoll != 'Select Man Power' &&
                    _selectedManPowerRoll != 'Select Man Power'.tr() &&
                    categories.isNotEmpty) {
                  _closeAllDropdowns();
                  setState(() {
                    showCheckboxes = !showCheckboxes;
                  });
                } else {
                  // Show message if no type selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select Type of Man Power first'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText: 'Category of Man Power (Optional)'.tr(),
                    errorText: state.errorText,
                    labelStyle: const TextStyle(
                      color: Color(0xFF6B8E23),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                      fontFamily: "Poppins",
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 20.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide:
                      const BorderSide(color: Colors.grey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide:
                      BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide:
                      const BorderSide(color: Color(0xFF6B8E23), width: 2),
                    ),
                    filled: true,
                    fillColor: (_selectedManPowerRoll == null ||
                        _selectedManPowerRoll == 'Select Man Power' ||
                        _selectedManPowerRoll == 'Select Man Power'.tr() ||
                        categories.isEmpty)
                        ? Colors.grey.shade100
                        : Colors.white,
                    suffixIcon: IconButton(
                      onPressed: (_selectedManPowerRoll != null &&
                          _selectedManPowerRoll != 'Select Man Power' &&
                          _selectedManPowerRoll != 'Select Man Power'.tr() &&
                          categories.isNotEmpty &&
                          showCheckboxes)
                          ? () {
                        setState(() {
                          showCheckboxes = !showCheckboxes;
                        });
                      }
                          : null,
                      icon: Icon(
                        showCheckboxes
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: (_selectedManPowerRoll != null &&
                            _selectedManPowerRoll != 'Select Man Power' &&
                            _selectedManPowerRoll != 'Select Man Power'.tr() &&
                            categories.isNotEmpty)
                            ? const Color(0xFF6B8E23)
                            : Colors.grey,
                      ),
                    )),
                child: Text(
                  selectedCategories.isEmpty
                      ? (_selectedManPowerRoll == null ||
                      _selectedManPowerRoll == 'Select Man Power' ||
                      _selectedManPowerRoll == 'Select Man Power'.tr())
                      ? 'Select Type of Man Power first'.tr()
                      : categories.isEmpty
                      ? 'No categories available'.tr()
                      : 'Select Category'.tr()
                      : selectedCategories.join(', '),
                  style: TextStyle(
                    color:
                    selectedCategories.isEmpty ? Colors.grey : Colors.black,
                    fontFamily: "Poppins",
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (showCheckboxes && categories.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: categories.map((category) {
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        category.tr(),
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedCategories.contains(category),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedCategories.add(category);
                            // Initialize controller if not exists
                            if (!controllers.containsKey(category)) {
                              controllers[category] = TextEditingController();
                            }
                            if (!focusNodes.containsKey(category)) {
                              focusNodes[category] = FocusNode();
                            }
                          } else {
                            selectedCategories.remove(category);
                            // Clear the controller value when unchecked
                            if (controllers.containsKey(category) && controllers[category] != null) {
                              controllers[category]!.clear();
                            }
                          }
                          state.didChange(selectedCategories);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B8E23),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
            if (selectedCategories.isNotEmpty)
              SizedBox(
                height: 90,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: selectedCategories.map((category) {
                      // Ensure controller exists for this category
                      if (!controllers.containsKey(category) || controllers[category] == null) {
                        controllers[category] = TextEditingController();
                      }
                      if (!focusNodes.containsKey(category) || focusNodes[category] == null) {
                        focusNodes[category] = FocusNode();
                      }

                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: controllers[category]!,
                          focusNode: focusNodes[category]!,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          buildCounter: (context,
                              {required currentLength,
                                required isFocused,
                                maxLength}) {
                            return null;
                          },
                          validator: (value) {
                            if (selectedCategories.contains(category)) {
                              if (value == null || value.isEmpty) {
                                return 'Required'.tr();
                              }
                              if (int.tryParse(value) == null) {
                                return 'Numbers only'.tr();
                              }
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: '${category.tr()} *',
                            labelStyle: const TextStyle(
                                color: Color(0xFF6B8E23),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                fontFamily: "Poppins"),
                            hintText: 'Enter ${category.tr()}',
                            hintStyle: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 12.0,
                                color: Colors.grey),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 15.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: const BorderSide(width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: const BorderSide(
                                color: Color(0xFF6B8E23),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }


  Widget _buildDateTimePicker({
    required String labelText,
    required String hintText,
    required dynamic value,
    required IconData icon,
    required Function() onTap,
    bool isRequired = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextFormField(
          validator: (val) {
            if (isRequired && (value == null || value.toString().isEmpty)) {
              return 'Please select $labelText';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: labelText + (isRequired ? '*' : ''),
            labelStyle: const TextStyle(
              color: Color(0xFF6B8E23),
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              fontFamily: "Poppins",
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 12.0,
              fontFamily: "Poppins",
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 20.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
            ),
            suffixIcon: Icon(icon, color: const Color(0xFF6B8E23)),
          ),
          controller: TextEditingController(
            text: value?.toString() ?? '',
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12.0,
            fontFamily: "Poppins",
          ),
          readOnly: true,
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = prefs.getString('auth_token') ?? '';
        int? userId = prefs.getInt('user_id');
        if (token.isEmpty) {
          throw Exception('Authentication token not found');
        }
        // Format date with null check
        String formattedDate = '';
        if (_startDate != null) {
          formattedDate = DateFormat('yyyy-MM-dd').format(_startDate!);
        }

        // Format times with null checks
        String startTimeStr = '';
        String endTimeStr = '';

        if (_startTime != null) {
          startTimeStr =
              '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        }

        if (_endTime != null) {
          endTimeStr =
              '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
        }

        // Calculate time in hours between start and end time
        double timeHrs = 0;
        if (_startTime != null && _endTime != null && _startDate != null) {
          DateTime startDateTime = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            _startTime!.hour,
            _startTime!.minute,
          );
          DateTime endDateTime = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
            _endTime!.hour,
            _endTime!.minute,
          );

          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(const Duration(days: 1));
          }

          timeHrs = endDateTime.difference(startDateTime).inMinutes / 60.0;
        }

// 
// Prepare chemical data with dose, UOM, and company
List<Map<String, dynamic>> chemicalData = [];
for (String ingredient in selectedIngredients) {
  var ingredientData = selectedIngredientData[ingredient];
  if (ingredientData != null) {
    int chemicalId = ingredientData['id'] ?? 0;
    String dose = ingredientData['dose']?.text ?? '';
    String uom = ingredientData['uom'] ?? '';
    String company = ingredientData['company'] ?? '';
    
    if (chemicalId > 0 && dose.isNotEmpty) {
      chemicalData.add({
        'id': chemicalId,
        'dose': dose,
        'uom': uom,
        'company': company,
      });
    }
  }
}
        // Get machine IDs as strings
        List<String> machineIds = [];
        if (selectedMachines.isNotEmpty) {
          for (String machineDisplayName in selectedMachines) {
            // Find the machine data by display name
            for (var machine in _machineData) {
              String displayName =
                  '${machine['machine_name']} - ${machine['machine_no']}';
              if (displayName == machineDisplayName) {
                machineIds.add(machine['id'].toString()); // Convert to string
                break;
              }
            }
          }
        }

// Get tractor IDs as strings
        List<String> tractorIds = [];
        if (selectedTractors.isNotEmpty) {
          for (String tractorDisplayName in selectedTractors) {
            // Find the tractor data by display name
            for (var tractor in _tractorData) {
              String displayName =
                  '${tractor['tractor_name']} - ${tractor['tractor_type']}';
              if (displayName == tractorDisplayName) {
                tractorIds.add(tractor['id'].toString()); // Convert to string
                break;
              }
            }
          }
        }
        // Collect manpower data with category IDs

        int? selectedTypeId;
        if (_selectedManPowerRoll != null &&
            _selectedManPowerRoll != 'Select Man Power') {
          var selectedType = _manpowerTypes.firstWhere(
                (type) => type['type_name'] == _selectedManPowerRoll,
            orElse: () => {},
          );
          if (selectedType.isNotEmpty) {
            selectedTypeId = selectedType['type_id'];
          }
        }

        // Collect manpower data with category_ids and values
        List<Map<String, dynamic>> manpowerData = [];
        if (selectedCategories.isNotEmpty &&
            _selectedManPowerRoll != null &&
            _selectedManPowerRoll != 'Select Man Power') {
          List<Map<String, dynamic>> typeCategories =
              _categoriesByType[_selectedManPowerRoll] ?? [];

          for (String categoryName in selectedCategories) {
            var categoryInfo = typeCategories.firstWhere(
                  (cat) => cat['category_name'] == categoryName,
              orElse: () => {},
            );

            if (categoryInfo.isNotEmpty &&
                controllers[categoryName]?.text.isNotEmpty == true) {
              manpowerData.add({
                'category_id': categoryInfo['category_id'],
                'no_of_person':
                int.tryParse(controllers[categoryName]!.text) ?? 0,
              });
            }
          }
        }

        // Prepare data for API request
        final Map<String, dynamic> requestData = {
          'block_name': _selectedBlockId.toString(),
          'plot_name': _selectedPlotId.toString(),

          'area': _selectedArea,
          'chemical_ids': chemicalData,
          'application_method': _selectedApplication == 'Select Method'.tr()
              ? null
              : _selectedApplication,
          'application_stage_source':
              _selectedStageSource == 'Select Stage Source'
                  ? null
                  : _selectedStageSource,
          'area_covered': _areaController.text,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'date': formattedDate,
          //        'category': selectedCategories.toList(),
          //  'hsd_consumption': double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
          'hsd_consumption': _HSD_Consuption_Controller.text.isEmpty
              ? null
              : (double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0),
          //  'manpower_type': _selectedManPowerRoll == 'Select ManPower' ? null : _selectedManPowerRoll,

          'user_id': userId, // Now getting user_id from SharedPreferences
        };

        if (selectedTypeId != null) {
          requestData['manpower_type_id'] = selectedTypeId;
        }

        if (manpowerData.isNotEmpty) {
          requestData['manpower_categories'] = manpowerData;
        }

        // if (selectedCategories.isNotEmpty) {
        //   requestData['category'] =
        //       List<String>.from(selectedCategories.map((cat) => cat.trim()));
        // }

        if (machineIds.isNotEmpty) {
          requestData['machine_ids'] = machineIds;
        }

        if (tractorIds.isNotEmpty) {
          requestData['tractor_ids'] = tractorIds;
        }


        print("Request Data: ${json.encode(requestData)}");
        print("User ID being sent: $userId"); // Debug print
        final response = await http.post(
          Uri.parse('${Constanst().base_url}crop-protection'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = json.decode(response.body);
          print("API Response: $responseData");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Details submitted successfully'),
              backgroundColor: Color(0xFF6B8E23),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );

          _resetForm();
        } else {
          // Error handling - Parse error response
          try {
            final errorData = jsonDecode(response.body);
            String errorMessage = '';

            // Check for specific error types
            if (errorData.containsKey('error')) {
              String mainError = errorData['error'] ?? 'Failed to submit data';

              // Check for chemical stock error
              if (errorData.containsKey('available_stock') &&
                  errorData.containsKey('requested_consumption')) {
                String availableStock = errorData['available_stock'] ?? '0.00';
                String requestedConsumption =
                    errorData['requested_consumption']?.toString() ?? '0';

                errorMessage =
                    '$mainError\nAvailable Stock: $availableStock\nRequested: $requestedConsumption';
              } else {
                errorMessage = mainError;
              }
            } else if (errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            } else {
              errorMessage = 'Failed to submit data';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(
                    seconds: 4), // Increased duration for longer messages
              ),
            );
          } catch (parseError) {
            // If JSON parsing fails, show generic error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to submit data. Status: ${response.statusCode}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

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
                      MaterialPageRoute(
                          builder: (context) => const DashboardScreen()),
                    );
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Crop Protection'.tr(),
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
              ? const Center(
                  child: CircularProgressIndicator(
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
                          labelText: 'Block Name',
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
                          labelText: 'Plot Name',
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
                                fontFamily: "Poppins"),
                            hintStyle: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 14.0,
                                color: Colors.grey),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 20.0),
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

                        // Area Leveling TextField
                        _buildCustomTextField(
                          labelText: 'Area Covered'.tr(),
                          hintText: 'Enter Area'.tr(),
                          controller: _areaController,
                          focusNode: _levelingFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true), // Number keyboard with decimal
                          maxLength: 5, // Limit to 3 digits
                        ),

                        const SizedBox(height: 20),

                        _buildMachineSelectionSection(),

                        const SizedBox(height: 20),

                        _buildTractorSelectionSection(),

                        const SizedBox(height: 20),

                        _buildCustomTextField(
                          labelText: 'HSD Consumption (Optional)'.tr(),
                          hintText: 'Enter HSD Consumption'.tr(),
                          controller: _HSD_Consuption_Controller,
                          focusNode: _HSD_FocusNode,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          maxLength: 6, // Limit to 3 digits
                          customValidator: (value) {
                            // Only validate if user has entered something
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                            }
                            // Return null means no validation error - field is optional
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Machine Dropdown
                        _buildCustomDropdown(
                          labelText: 'Application Method'.tr(),
                          selectedValue: _selectedApplication,
                          items: _applicationMethodName,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedApplication = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        _buildIngredientSelectionSection(),

                        const SizedBox(height: 20),

                        _buildCustomDropdown(
                          labelText: 'Application Stage Source',
                          selectedValue: _selectedStageSource,
                          items: _StageSourceName,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStageSource = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        _buildDateTimePicker(
                          labelText: 'Date'.tr(),
                          hintText: 'dd-mm-yyyy'.tr(),
                          value: _startDate == null
                              ? null
                              : DateFormat('dd-MM-yyyy').format(_startDate!),
                          icon: Icons.calendar_today,
                          onTap: () => _selectDate(context, true),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTimePicker(
                                labelText: 'Start Time'.tr(),
                                hintText: 'Start Time'.tr(),
                                value: _startTime?.format(context),
                                icon: Icons.access_time,
                                onTap: () => _selectTime(context, true),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildDateTimePicker(
                                labelText: 'End Time'.tr(),
                                hintText: 'End Time'.tr(),
                                value: _endTime?.format(context),
                                icon: Icons.access_time,
                                onTap: () => _selectTime(context, false),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildCustomDropdown(
                          labelText: 'Type of Man Power'.tr(),
                          selectedValue: _selectedManPowerRoll,
                          items: _manpowerTypeNames,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedManPowerRoll = value;
                              });
                              _updateCategoriesForType(value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Man Power Section
                        _buildManpowerSection(),

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
                              child: Text(
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

  void _resetForm() {
    setState(() {
      // Reset dropdown selections
      _selectedBlockName = 'Select Block';
      _selectedPlotName = 'Select Plot';
      _selectedApplication = 'Select Method'.tr();
      _selectedStageSource = 'Select Stage Source'.tr();
      _selectedManPowerRoll = 'Select ManPower'.tr();

      selectedTractors.clear();
      _tractorSearchController.clear();
      showTractorDropdown = false;

      selectedMachines.clear();
      _machineSearchController.clear();
      showMachineDropdown = false;

      _HSD_Consuption_Controller.clear();

      _areaController.clear();

      // Reset date and time
      _startDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime =
          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 4)));

      // Clear ingredient selections and data
      selectedIngredients.clear();
      _ingredientSearchController.clear();
      showIngredientDropdown = false;

      // Dispose all dynamic controllers and clear data - ADD NULL CHECKS
      for (String ingredient in selectedIngredientData.keys) {
        var ingredientData = selectedIngredientData[ingredient];
        if (ingredientData != null && ingredientData['dose'] != null) {
          (ingredientData['dose'] as TextEditingController).dispose();
        }
      }
      selectedIngredientData.clear();

      // Clear manpower selections
      selectedCategories.clear();

      _filteredTractorNames = _tractorDisplayNames // Changed from _tractorName
          .where((tractor) => tractor != 'Select Tractor')
          .toList();
      _filteredMachineNames = _machineDisplayNames // Changed from _machineName
          .where((machine) => machine != 'Select Machine')
          .toList();

      // Dispose and clear manpower controllers - ADD NULL CHECKS
      for (var controller in controllers.values) {
        controller.dispose(); // Add null check
      }
      controllers.clear();

      // Clear focus nodes - ADD NULL CHECKS
      for (var focusNode in focusNodes.values) {
        focusNode.dispose(); // Add null check
      }
      focusNodes.clear();

      // Reset area text
      _areaText = '';
      _selectedArea = null;
    });
  }

  Future<void> _fetchMachineDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}machine-names'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> machineApiData = responseData['data'];

          setState(() {
            _machineData = List<Map<String, dynamic>>.from(machineApiData);
            _machineDisplayNames = ['Select Machine'];

            for (var machine in _machineData) {
              String displayName =
                  '${machine['machine_name']} - ${machine['machine_no']}';
              _machineDisplayNames.add(displayName);
            }

            _filteredMachineNames = _machineDisplayNames
                .where((machine) => machine != 'Select Machine')
                .toList();
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  Future<void> _fetchTractorDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tractorToken = prefs.getString('auth_token') ?? '';

      if (tractorToken.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}tractors-names'),
        headers: {
          'Authorization': 'Bearer $tractorToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> tractorApiData = responseData['data'];

          setState(() {
            _tractorData = List<Map<String, dynamic>>.from(tractorApiData);
            _tractorDisplayNames = ['Select Tractor'];

            for (var tractor in _tractorData) {
              String displayName =
                  '${tractor['tractor_name']} - ${tractor['tractor_type']}';
              _tractorDisplayNames.add(displayName);
            }

            _filteredTractorNames = _tractorDisplayNames
                .where((tractor) => tractor != 'Select Tractor')
                .toList();
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  Future<void> _fetchChemicalDetails() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}crop-chemicals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final List<dynamic> chemicalsData = responseData['data'];

          setState(() {
            // Reset collections
            _chemicalNames = ['Select Ingredients'];
            _chemicalIdMap = {};

            // Process each chemical in the response
            for (var chemical in chemicalsData) {
  String chemicalName = chemical['chemical_name'];
  int chemicalId = chemical['id'];

  // Add name to dropdown list
  _chemicalNames.add(chemicalName);

  // Store complete chemical data
  _chemicalDataMap[chemicalName] = {
    'id': chemicalId,
    'uom': chemical['uom'],
    'brand_name': chemical['brand_name'],
  };
  
  // Keep the ID mapping for backward compatibility
  _chemicalIdMap[chemicalName] = chemicalId;
}

            // Initialize filtered list
            _filteredChemicalNames = _chemicalNames
                .where((chemical) => chemical != 'Select Ingredients')
                .toList();
          });
        } else {
          throw Exception('API returned false success status');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }



  Future<void> fetchCategories() async {
    print('📡 Starting fetchCategories API call...');
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');


    if (token == null || token.isEmpty) {
      print('⚠️ Token not found in SharedPreferences');
      return;
    }

    print('✅ Token found: $token');

    try {
      final response = await http.post(
        Uri.parse('${Constanst().base_url}manpower/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('🔁 API call completed with status code: ${response.statusCode}');
      print('📦 Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == 'success') {
          final List<dynamic> data = body['data'];

          setState(() {
            // Clear existing data
            _manpowerTypes.clear();
            _manpowerTypeNames = ['Select Man Power'];
            _categoriesByType.clear();

            // Process the hierarchical data
            for (var typeData in data) {
              int typeId = typeData['type_id'];
              String typeName = typeData['type_name'];
              List<dynamic> categoriesData = typeData['categories'];

              // Store type information
              _manpowerTypes.add({
                'type_id': typeId,
                'type_name': typeName,
              });
              _manpowerTypeNames.add(typeName);

              // Store categories for this type
              List<Map<String, dynamic>> typeCategories = [];
              for (var categoryData in categoriesData) {
                typeCategories.add({
                  'category_id': categoryData['category_id'],
                  'category_name': categoryData['category_name'],
                  'no_of_person': categoryData[
                  'no_of_person'], // Keep this for reference if needed
                });
              }
              _categoriesByType[typeName] = typeCategories;
            }

            isLoading = false;
          });

          print('✅ Manpower types loaded: $_manpowerTypeNames');
          print('✅ Categories by type: $_categoriesByType');
        } else {
          print('❌ API returned unsuccessful status');
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load manpower data')),
          );
        }
      } else {
        print(
            '❌ Failed to fetch categories. Status code: ${response.statusCode}');
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      print('❌ Error fetching categories: SocketException');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      print('❌ Error fetching categories: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }

  void _updateCategoriesForType(String selectedTypeName) {
    if (selectedTypeName == 'Select Man Power'.tr()) {
      setState(() {
        _filteredCategories = [];
        _filteredCategoryNames = ['Select Category'.tr()];
        categories = []; // Clear categories list
        selectedCategories.clear();
        // Clear all controllers
        for (var controller in controllers.values) {
          controller.dispose();
        }
        controllers.clear();
        focusNodes.clear();
      });
      return;
    }

    // Get categories for the selected type from _categoriesByType
    List<Map<String, dynamic>> typeCategories = _categoriesByType[selectedTypeName] ?? [];

    if (typeCategories.isNotEmpty) {
      setState(() {
        // Set filtered categories
        _filteredCategories = List<Map<String, dynamic>>.from(typeCategories);

        // Clear existing controllers and focus nodes
        for (var controller in controllers.values) {
          controller.dispose();
        }
        for (var node in focusNodes.values) {
          node.dispose();
        }
        controllers.clear();
        focusNodes.clear();
        selectedCategories.clear();

        // Reset category names and categories list
        _filteredCategoryNames = ['Select Category'.tr()];
        categories = [];

        // Setup new categories
        for (var category in typeCategories) {
          String categoryName = category['category_name'].toString();
          _filteredCategoryNames.add(categoryName);
          categories.add(categoryName);

          // Initialize controllers and focus nodes for each category
          controllers[categoryName] = TextEditingController();
          focusNodes[categoryName] = FocusNode();
        }
      });

      print('✅ Categories updated for $selectedTypeName: $categories');
    } else {
      print('⚠️ No categories found for type: $selectedTypeName');
      setState(() {
        categories = [];
        selectedCategories.clear();
        controllers.clear();
        focusNodes.clear();
      });
    }
  }






}
