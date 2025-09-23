import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Dashboard/dashboard_screen.dart';
import '../widget/Constants.dart';

class Sowing extends StatefulWidget {
  const Sowing({super.key});

  @override
  State<Sowing> createState() => sowing_preperation();
}

class sowing_preperation extends State<Sowing> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';

  // Text Controllers
  final TextEditingController _fuelConsumptionController =
  TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _row_to_row_distance_Controller =
  TextEditingController();
  final TextEditingController _sowing_depth_Controller =
  TextEditingController();
  final TextEditingController _seed_consumption_Controller =
  TextEditingController();

/*  final TextEditingController _majorMaintenanceController = TextEditingController();*/
  final TextEditingController _HSD_Consuption_Controller =
  TextEditingController();

  List<Map<String, TextEditingController>> _sparePartsControllers = [];

  // Focus nodes to track focus state
  final _levelingFocusNode = FocusNode();
  final _majorMaintenanceFocusNode = FocusNode();
  final _HSD_FocusNode = FocusNode();
  final _row_to_row_FocusNode = FocusNode();
  final _sowing_depth_FocusNode = FocusNode();
  final _seed_consumption_FocusNode = FocusNode();

  // Dropdown Values with default options
  final String _selectedSiteName = 'Select Site';
  String? _selectedBlockName = 'Select Block';
  String? _selectedPlotName = 'Select Plot';
  final String _selectedAreaName = 'Select Area';

  String? _selectedSeed = 'Select Seed'.tr();
  String? _selectedVarity = 'Select Variety';

  String? _selected_Sowing_Method = 'Select Sowing Method'.tr();

  int? _selectedSowingMethodId; // Add this new variable to store the selected ID

  String? _selectedPurpose = 'Select Purpose';
  String? _selectedSowingSource = 'Select Sowing Source'.tr();
  String? _selectedManPowerRoll = 'Select Man Power';

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

  List<Map<String, dynamic>> _tractorData = [];
  List<Map<String, dynamic>> _machineData = [];
  List<String> _tractorDisplayNames = ['Select Tractor'];
  List<String> _machineDisplayNames = ['Select Machine'];

//  String? _selectedManPower = 'Select Man Power';

// Add these variables with your other declarations
  List<Map<String, dynamic>> _seedData = [];
  Map<String, Map<String, dynamic>> _seedVarietyMapWithIds = {};
  int? _selectedSeedId;

  // ID storage for API communication
  int? _selectedSiteId;
  int? _selectedBlockId;
  int? _selectedPlotId;
  double? _selectedArea;

  DateTime? _startDate = DateTime.now();
  TimeOfDay? _startTime = TimeOfDay.now();
  TimeOfDay? _endTime =
  TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 4)));

  // API Data
  final List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _plots = [];
  List<Map<String, dynamic>> _sowingMethods = [];
  final List<Map<String, dynamic>> _purpose = [];

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'];
  List<String> _plotNames = ['Select Plot'];
  final List<String> _areaOptions = ['Select Area'];

  List<String> _seedName = ['Select Seed'];
  List<String> _varietyName = ['Select variety'];

  List<String> _sowingName = ['Select sowing Method'.tr()];
  List<String> _purposeName = ['Select purpose'];
  List<String> _sowing_source = ['Select sowing source'.tr()];

// Add these variables at the top with other declarations
  List<Map<String, dynamic>> _manpowerTypes = [];
  List<String> _manpowerTypeNames = ['Select Man Power'.tr()];
  List<Map<String, dynamic>> _filteredCategories = [];
  List<String> _filteredCategoryNames = ['Select Category'.tr()];


  bool _isLoading = true;

  bool showCheckboxes = false;
  bool isLoading = true;

  List<String> categories = [];
  Set<String> selectedCategories = {};

  Map<String, TextEditingController> controllers = {};
  Map<String, FocusNode> focusNodes = {};

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

    for (var controllerMap in _sparePartsControllers) {
      controllerMap['part']?.clear();
      controllerMap['value']?.clear();
    }

    // Optionally remove all but one field
    if (_sparePartsControllers.isNotEmpty) {
      final firstController = _sparePartsControllers.first;

      // Dispose all other controllers
      for (int i = 1; i < _sparePartsControllers.length; i++) {
        _sparePartsControllers[i]['part']?.dispose();
        _sparePartsControllers[i]['value']?.dispose();
      }

      _sparePartsControllers = [firstController];
    }

    _fetchBlocksAndPlots();
    _machineDisplayNames = ['Select Machine']; // Changed from _machineName
    _tractorDisplayNames = ['Select Tractor']; // Add this line
    _fetchMachineDetails();
    _fetchTractorDetails();
    fetchCategories();
    _fetchSeedDetails();
    _fetchSowingMethod();
    _fetchPurposeDetail();
    _fetchSowingSource();

    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });
    _row_to_row_FocusNode.addListener(() {
      setState(() {});
    });
    _sowing_depth_FocusNode.addListener(() {
      setState(() {});
    });
    _seed_consumption_FocusNode.addListener(() {
      setState(() {});
    });
  }

  void _addNewSparePart() {
    setState(() {
      _sparePartsControllers.add({
        'part': TextEditingController(),
        'value': TextEditingController(),
      });
    });
  }

  void _removeSparePart(int index) {
    setState(() {
      if (index < _sparePartsControllers.length) {
        // Dispose controllers to prevent memory leaks
        _sparePartsControllers[index]['part']?.dispose();
        _sparePartsControllers[index]['value']?.dispose();
        _sparePartsControllers.removeAt(index);
      }
    });
  }

  Widget _buildSparePartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and Add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Major Maintainance'.tr(),
              style: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  fontFamily: "Poppins"),
            ),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.add,
                size: 14,
                color: Colors.white,
              ),
              label: const Text('Add Spare').tr(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B8E23),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: _addNewSparePart,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Display all spare parts fields
        ..._sparePartsControllers
            .asMap()
            .entries
            .map((entry) {
          int index = entry.key;
          var controllers = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                // Spare part name field
                Expanded(
                  flex: 3,
                  child: _buildCustomTextField(
                    labelText: 'Major Repair'.tr(),
                    hintText: 'Enter major repair'.tr(),
                    controller: controllers['part']!,
                    isRequired: false,
                  ),
                ),
                const SizedBox(width: 10),

                // Spare part value field
                Expanded(
                  flex: 2,
                  child: _buildCustomTextField(
                    labelText: 'Cost(Rs)'.tr(),
                    hintText: 'Enter value'.tr(),
                    controller: controllers['value']!,
                    keyboardType: TextInputType.number,
                    isRequired: false,
                  ),
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _removeSparePart(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
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
    _fuelConsumptionController.dispose();
    _areaController.dispose();
    _row_to_row_distance_Controller.dispose();
    _sowing_depth_Controller.dispose();
    _seed_consumption_Controller.dispose();
    /*_majorMaintenanceController.dispose();*/

    for (var controllerMap in _sparePartsControllers) {
      controllerMap['part']?.dispose();
      controllerMap['value']?.dispose();
    }

    _levelingFocusNode.dispose();
    _row_to_row_FocusNode.dispose();
    _sowing_depth_FocusNode.dispose();
    _seed_consumption_FocusNode.dispose();
    /*_majorMaintenanceFocusNode.dispose();*/

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
    });
  }

  Widget _buildMachineSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedMachines,
      validator: (value) {
        // Optional: validate if at least one machine is selected
        if (value == null || value.isEmpty) {
          return 'Please select at least one machine'.tr();
        }
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
                  // Clear search text when opening dropdown
                  _machineSearchController.clear();
                  // Reset filtered list when opening dropdown
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
                labelText: 'Machine *'.tr(),
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

                      if (showMachineDropdown) {
                        // Clear search text when opening dropdown
                        _machineSearchController.clear();
                        // Reset filtered list when opening dropdown
                        _filteredMachineNames =
                            _machineDisplayNames // Changed from _machineName
                                .where((machine) =>
                            machine != 'Select Machine')
                                .toList();
                      } else {
                        // Clear search text when closing dropdown
                        _machineSearchController.clear();
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

                          // Optional: Close dropdown after selection
                          // showMachineDropdown = false;
                          // _machineSearchController.clear();
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
        // Optional: validate if at least one tractor is selected
        if (value == null || value.isEmpty) {
          return 'Please select at least one tractor'.tr();
        }
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only one input field that acts as both the selection display and search field
            TextFormField(
              controller: _tractorSearchController,
              readOnly: !showTractorDropdown,
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showTractorDropdown = true;
                  // Clear search text when opening dropdown
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
                  // Filter tractor names based on search input
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
                labelText: 'Tractor*'.tr(),
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
                      // Toggle dropdown when arrow is clicked
                      showTractorDropdown = !showTractorDropdown;

                      if (showTractorDropdown) {
                        // Clear search text when opening dropdown
                        _tractorSearchController.clear();
                        // Reset filtered list when opening dropdown
                        _filteredTractorNames =
                            _tractorDisplayNames // Changed from _tractorName
                                .where((tractor) =>
                            tractor != 'Select Tractor')
                                .toList();
                      } else {
                        // Clear search text when closing dropdown
                        _tractorSearchController.clear();
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
                height: 200, // Fixed height for the dropdown list
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
      maxLength: maxLength,
      // Set max length
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null,
      // Add input formatter for length limiting
      validator: customValidator ??
              (value) {
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
    // Ensure the selectedValue exists in the items list to prevent the error
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

        // For all other dropdowns, keep existing validation
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
      items: items.toSet().map<DropdownMenuItem<String>>((name) {
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
      icon: const SizedBox.shrink(),
      // Remove default dropdown icon
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
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
    bool isTypeSelected = _selectedManPowerRoll != null &&
        _selectedManPowerRoll != 'Select Man Power'.tr() &&
        !_selectedManPowerRoll!.startsWith('Select');

    return FormField<Set<String>>(
      initialValue: selectedCategories,
      validator: null, // No validation - optional field
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showCheckboxes = !showCheckboxes;
                });
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
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      onPressed: showCheckboxes
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
                        color: const Color(0xFF6B8E23),
                      ),
                    )),
                child: Text(
                  isTypeSelected
                      ? (selectedCategories.isEmpty
                      ? 'Select Category'.tr()
                      : selectedCategories.join(', '))
                      : 'Select Type of Man Power first'.tr(),
                  style: TextStyle(
                    color:
                    selectedCategories.isEmpty ? Colors.grey : Colors.black,
                    fontFamily: "Poppins",
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            if (showCheckboxes)
              Column(
                children: categories.map((category) {
                  return CheckboxListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: Text(
                      category,
                      style: const TextStyle(fontFamily: "Poppins"),
                    ),
                    value: selectedCategories.contains(category),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                          // Clear the controller value when unchecked
                          if (controllers[category] != null) {
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
            const SizedBox(height: 10),
            if (selectedCategories.isNotEmpty)
              SizedBox(
                height: 90,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: selectedCategories.map((category) {
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          controller: controllers[category]!,
                          focusNode: focusNodes[category],
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          // Added 3 digit limitation
                          buildCounter: (context,
                              {required currentLength,
                                required isFocused,
                                maxLength}) {
                            return null; // Hide the counter
                          },
                          validator: (value) {
                            // If category is selected then value is required
                            if (selectedCategories.contains(category)) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Numbers only';
                              }
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: '$category *',
                            labelStyle: const TextStyle(
                                color: Color(0xFF6B8E23),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                                fontFamily: "Poppins"),
                            hintText: 'Enter $category',
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
            if (isRequired && (value == null || value
                .toString()
                .isEmpty)) {
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
              fontFamily: "Poppins",
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14.0,
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
            fontSize: 14.0,
            fontFamily: "Poppins",
          ),
          readOnly: true,
        ),
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
        // Format date
        String formattedDate = '';
        if (_startDate != null) {
          formattedDate = DateFormat('yyyy-MM-dd').format(_startDate!);
        }

        // Format times
        String startTimeStr = '';
        String endTimeStr = '';

        if (_startTime != null) {
          startTimeStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute
              .toString().padLeft(2, '0')}';
        }

        if (_endTime != null) {
          endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute
              .toString().padLeft(2, '0')}';
        }

        // Calculate time in hours between start and end time
        double timeHrs = 0;
        if (_startTime != null && _endTime != null) {
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

          // If end time is before start time, assume it's the next day
          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(const Duration(days: 1));
          }

          // Calculate hours difference
          timeHrs = endDateTime
              .difference(startDateTime)
              .inMinutes / 60.0;
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
        List<Map<String, String>> sparePartsData = [];
        for (var controller in _sparePartsControllers) {
          if (controller['part']!.text.isNotEmpty ||
              controller['value']!.text.isNotEmpty) {
            sparePartsData.add({
              'spare_part': controller['part']!.text,
              'value': controller['value']!.text,
            });
          }
        }

        // Collect manpower data with category IDs
        Map<String, dynamic> manpowerData = {};
        List<Map<String, dynamic>> categoryData = [];

// Get manpower type ID
        int? manpowerTypeId;
        if (_selectedManPowerRoll != null &&
            _selectedManPowerRoll != 'Select Man Power'.tr() &&
            !_selectedManPowerRoll!.startsWith('Select')) {
          // Find the selected type ID
          final selectedType = _manpowerTypes.firstWhere(
                (type) => type['type_name'] == _selectedManPowerRoll,
            orElse: () => {},
          );

          if (selectedType.isNotEmpty) {
            manpowerTypeId = selectedType['type_id'];

            for (String categoryName in selectedCategories) {
              if (controllers[categoryName]?.text != null &&
                  controllers[categoryName]!.text.isNotEmpty) {
                // Find category ID
                final category = _filteredCategories.firstWhere(
                      (cat) => cat['category_name'] == categoryName,
                  orElse: () => {},
                );

                if (category.isNotEmpty) {
                  categoryData.add({
                    'category_id': category['category_id'],
                    'no_of_person':
                    int.tryParse(controllers[categoryName]!.text) ?? 0,
                  });
                }
              }
            }

            manpowerData['categories'] = categoryData;
          }
        }

        // Prepare data for API request
        final Map<String, dynamic> requestData = {
          'block_name': _selectedBlockId.toString(), // Send block_id instead of block_name
          'plot_name': _selectedPlotId.toString(),

          'area': _selectedArea,

          'spare_parts': sparePartsData,
          'machine_ids': machineIds, // Changed from machine_id to machine_ids
          'tractor_ids': tractorIds, // Changed from tractor_id to tractor_ids

          'area_covered': _areaController.text,
          'row_distance': _row_to_row_distance_Controller.text,
          'sowing_depth': _sowing_depth_Controller.text,
          'seed_consumption': _seed_consumption_Controller.text,
          'hsd_consumption':
          double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'sowing_date': formattedDate,
          //  'category': selectedCategories.toList(), // Convert Set to List
          'user_id': userId, // Now getting user_id from SharedPreferences

          //change new seed
          'seed_id': _selectedSeedId,
          'variety_of_seed':
          _selectedVarity == 'Select Variety' ? null : _selectedVarity,
          'seed_name':
          _selectedSeed == 'Select Seed'.tr() ? null : _selectedSeed,

// 'sowing_method': _selected_Sowing_Method == 'Select Sowing Method'
//     ? null
//     : _selected_Sowing_Method,
          'sowing_method': _selectedSowingMethodId,


          'purpose_name':
          _selectedPurpose == 'Select Purpose' ? null : _selectedPurpose,
          'sowing_source_id': _selectedSowingSource == 'Select Sowing Source'
              ? null
              : _selectedSowingSource,
        };

        // Add manpower data if selected
        if (manpowerTypeId != null) {
          requestData['manpower_type_id'] = manpowerTypeId;

          if (categoryData.isNotEmpty) {
            requestData['manpower_categories'] = categoryData;
          }
        }

        print("Request Data: ${json.encode(requestData)}");
        print("User ID being sent: $userId"); // Debug print
        // Make API call
        final response = await http.post(
          Uri.parse('${Constanst().base_url}sowing-operations'),
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );

          // Clear form fields
          _resetForm();
        } else {
          // Error handling - Parse error response
          try {
            final errorData = jsonDecode(response.body);
            String errorMessage = '';

            // Check for specific error types
            if (errorData.containsKey('error')) {
              String mainError = errorData['error'] ?? 'Failed to submit data';

              // Check for seed stock error
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
                    'Sowing'.tr(),
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

                  // Area Covered TextField
                  _buildCustomTextField(
                    labelText: 'Area Covered'.tr(),
                    hintText: 'Enter Area'.tr(),
                    controller: _areaController,
                    focusNode: _levelingFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    // Number keyboard with decimal
                    maxLength: 5, // Limit to 4 digits
                  ),

                  const SizedBox(height: 20),

                  _buildCustomDropdown(
                    labelText: 'Name of Seeds'.tr(),
                    selectedValue: _selectedSeed,
                    items: _seedName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeed = value;
                          // Update varieties when seed changes
                          _updateVarieties(value);
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildCustomDropdown(
                    labelText: 'Variety of Seeds'.tr(),
                    selectedValue: _selectedVarity,
                    items: _varietyName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedVarity = value;
                        });
                        // Add this line to set the correct seed_id
                        _onVarietySelected(value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildCustomDropdown(
                    labelText: 'Sowing Method'.tr(),
                    selectedValue: _selected_Sowing_Method,
                    items: _sowingName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selected_Sowing_Method = value;

                          // Find and store the corresponding ID
                          if (value == 'Select Sowing Method') {
                            _selectedSowingMethodId = null;
                          } else {
                            // Find the sowing method object that matches the selected name
                            final selectedMethod = _sowingMethods.firstWhere(
                                  (method) => method['sowing_method'] == value,
                              orElse: () => {},
                            );

                            if (selectedMethod.isNotEmpty) {
                              _selectedSowingMethodId = selectedMethod['id'];
                            }
                          }
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildCustomDropdown(
                    labelText: 'Purpose'.tr(),
                    selectedValue: _selectedPurpose,
                    items: _purposeName,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPurpose = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildDateTimePicker(
                    labelText: 'Sowing Date'.tr(),
                    hintText: 'dd-mm-yyyy'.tr(),
                    value: _startDate == null
                        ? null
                        : DateFormat('dd-MM-yyyy').format(_startDate!),
                    icon: Icons.calendar_today,
                    onTap: () => _selectDate(context, true),
                  ),

                  const SizedBox(height: 20),

                  _buildCustomTextField(
                      labelText: 'Seed Consumption'.tr(),
                      hintText: 'Enter Seed Consumption'.tr(),
                      controller: _seed_consumption_Controller,
                      focusNode: _seed_consumption_FocusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      // Number keyboard with decimal
                      maxLength: 3),

                  const SizedBox(height: 20),

                  _buildCustomDropdown(
                    labelText: 'Sowing Source'.tr(),
                    selectedValue: _selectedSowingSource,
                    items: _sowing_source,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSowingSource = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildCustomTextField(
                      labelText: 'Row-To-Row Distance(cm)'.tr(),
                      hintText: 'Enter Distance'.tr(),
                      controller: _row_to_row_distance_Controller,
                      focusNode: _row_to_row_FocusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      // Number keyboard with decimal
                      maxLength: 3),

                  const SizedBox(height: 20),

                  _buildCustomTextField(
                      labelText: 'Sowing Depth (cm)'.tr(),
                      hintText: 'Enter Depth'.tr(),
                      controller: _sowing_depth_Controller,
                      focusNode: _sowing_depth_FocusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      // Number keyboard with decimal
                      maxLength: 2),

                  const SizedBox(height: 20),

                  _buildMachineSelectionSection(),

                  const SizedBox(height: 20),

                  _buildTractorSelectionSection(),

                  const SizedBox(height: 20),

                  // HSD Consumption TextField
                  _buildCustomTextField(
                    labelText: 'HSD Consumption'.tr(),
                    hintText: 'Enter HSD Consumption'.tr(),
                    controller: _HSD_Consuption_Controller,
                    focusNode: _HSD_FocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    maxLength: 6,
                    // Limit to 4 digits
                    customValidator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter HSD consumption'.tr();
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number'.tr();
                      }
                      return null;
                    },
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
                    labelText: 'Type of Man Power',
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

                  _buildSparePartsSection(),

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
      _selectedBlockName = 'Select Block';
      _selectedPlotName = 'Select Plot';
      _areaText = '';
      _selectedArea = null;
      _selectedBlockId = null;
      _selectedPlotId = null;
      _selectedSeedId = null;
      _selectedSowingMethodId =
      null; // Add this line where other resets are happening


      selectedMachines.clear();
      _machineSearchController.clear();
      showMachineDropdown = false;

      selectedTractors.clear();
      _tractorSearchController.clear();
      showTractorDropdown = false;

      _sparePartsControllers.clear();

      _selectedSeed = 'Select Seed'.tr();
      _selectedVarity = 'Select Variety'.tr();

      _selected_Sowing_Method = 'Select Sowing Method'.tr();
      _selectedSowingSource = 'Select Sowing Source'.tr();
      _selectedPurpose = 'Select Purpose'.tr();

      _selectedManPowerRoll = 'Select Man Power'.tr();

      _fuelConsumptionController.clear();
      _areaController.clear();

      _HSD_Consuption_Controller.clear();
      _startDate = null;
      _startTime = null;
      _endTime = null;

      // Clear selected categories and their values
      selectedCategories = {};
      for (var controller in controllers.values) {
        controller.clear();
      }

      _filteredTractorNames = _tractorDisplayNames
          .where((tractor) => tractor != 'Select Tractor')
          .toList();
      _filteredMachineNames = _machineDisplayNames
          .where((machine) => machine != 'Select Machine')
          .toList();

      // Reset dropdowns
      _updatePlots('Select Block');

      // Reset form validation
      _formKey.currentState?.reset();
    });
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

  Future<void> fetchCategories() async {
    print('📡 Starting fetchCategories API call...');
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');

    if (token!.isEmpty) {
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
        },
      );

      print('🔁 API call completed with status code: ${response.statusCode}');
      print('📦 Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'];

        setState(() {
          // Store the complete manpower types data
          _manpowerTypes = List<Map<String, dynamic>>.from(data);

          // Extract type names for the first dropdown
          _manpowerTypeNames = ['Select Man Power'.tr()];
          for (var type in _manpowerTypes) {
            _manpowerTypeNames.add(type['type_name'].toString());
          }

          // Reset category dropdown
          _filteredCategories = [];
          _filteredCategoryNames = ['Select Category'.tr()];

          isLoading = false;
        });

        print('Manpower types loaded: $_manpowerTypeNames');
      } else {
        print('Failed to fetch categories');
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong')),
        );
      }
    } on SocketException {
      print('Error fetching categories: SocketException');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect your internet')),
      );
    } catch (e) {
      print('Error fetching categories: $e');
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
        selectedCategories.clear();
        // Clear all controllers
        for (var controller in controllers.values) {
          controller.clear();
        }
        controllers.clear();
        focusNodes.clear();
      });
      return;
    }

    // Find the selected type
    final selectedType = _manpowerTypes.firstWhere(
          (type) => type['type_name'] == selectedTypeName,
      orElse: () => {},
    );

    if (selectedType.isNotEmpty) {
      setState(() {
        // Get categories for this type
        _filteredCategories =
        List<Map<String, dynamic>>.from(selectedType['categories']);

        // Extract category names
        _filteredCategoryNames = ['Select Category'.tr()];
        categories = []; // Reset the categories list

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

        // Setup new categories
        for (var category in _filteredCategories) {
          String categoryName = category['category_name'].toString();
          _filteredCategoryNames.add(categoryName);
          categories.add(categoryName);

          // Initialize controllers and focus nodes
          controllers[categoryName] = TextEditingController();
          focusNodes[categoryName] = FocusNode();
        }
      });
    }
  }

  Future<void> _fetchSeedDetails() async {
    setState(() {
      isLoading = true;
    });

    print('📡 Starting fetchSeedDetails API call...');
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');

    if (token!.isEmpty) {
      print('⚠️ Token not found in SharedPreferences');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication token not found')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Constanst().base_url}seed-varieties'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == 'success') {
          // Store the complete seed data from API
          final List<dynamic> seedData = body['data'];
          _seedData = List<Map<String, dynamic>>.from(seedData);

          // Create seed variety mapping with IDs - GROUP BY SEED NAME
          Map<String, Map<String, dynamic>> seedVarietyMapWithIds = {};


          setState(() {
            _seedName = ['Select Seed'];
            Set<String> uniqueSeedNames = {}; // Use Set to avoid duplicates

            // Process each seed from the response
            for (var seed in _seedData) {
              String seedName = seed['seed_name'];
              int seedId = seed['seed_id'];
              String variety = seed['variety_of_seed'];

              // Add unique seed names only
              uniqueSeedNames.add(seedName);

              // Group varieties by seed name
              if (seedVarietyMapWithIds.containsKey(seedName)) {
                // Add variety to existing seed
                List<Map<String, dynamic>> existingVarieties =
                List<Map<String, dynamic>>.from(seedVarietyMapWithIds[seedName]!['varieties']);
                existingVarieties.add({
                  'seed_id': seedId,
                  'variety_name': variety,
                });
                seedVarietyMapWithIds[seedName]!['varieties'] = existingVarieties;
              } else {
                // Create new entry for this seed name
                seedVarietyMapWithIds[seedName] = {
                  'varieties': [
                    {
                      'seed_id': seedId,
                      'variety_name': variety,
                    }
                  ],
                };
              }
            }

            _seedName.addAll(uniqueSeedNames.toList());

            // Store the mapping for later use
            _seedVarietyMapWithIds = seedVarietyMapWithIds;

            // Initialize variety dropdown
            _varietyName = ['Select Variety'.tr()];
            isLoading = false;
          });

          print('Seeds loaded: ${_seedName.length - 1}');
          print('Seed mapping: $_seedVarietyMapWithIds');
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong')),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }


  Future<void> _fetchSowingMethod() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}sowing-methods'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            _sowingMethods = List<Map<String, dynamic>>.from(data['data']);

            // Clear the list and reinitialize
            _sowingName = ['Select Sowing Method'.tr()];

            // Add all items from the API (now we store the full objects)
            _sowingName.addAll(_sowingMethods
                .map<String>((method) => method['sowing_method'].toString())
                .toList());

            // Make sure selected value exists in the list
            if (!_sowingName.contains(_selected_Sowing_Method)) {
              _selected_Sowing_Method = 'Select Sowing Method';
              _selectedSowingMethodId = null; // Reset the ID as well
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong')),
          );
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


  Future<void> _fetchPurposeDetail() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}get-purpose'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // print(data);

        if (data['status'] == 'success' && data['data'] != null) {
          setState(() {
            _purposeName = ['Select Purpose'.tr()];
            _purposeName.addAll(List<String>.from(data['data']));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong')),
          );
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

  Future<void> _fetchSowingSource() async {
    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}get-sowing-source'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] is List) {
          setState(() {
            // Clear the list first
            _sowing_source = ['Select Sowing Source'.tr()];

            // Add all sources from the API
            _sowing_source.addAll(List<String>.from(responseData['data']));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Something went wrong')),
          );
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



  // Replace the _updateVarieties method with this updated version
  void _updateVarieties(String seedName) {
    if (seedName == 'Select Seed') {
      setState(() {
        _varietyName = ['Select Variety'];
        _selectedVarity = 'Select Variety';
        _selectedSeedId = null;
      });
      return;
    }

    // Get seed data for the selected seed
    Map<String, dynamic>? seedData = _seedVarietyMapWithIds[seedName];

    if (seedData != null) {
      List<Map<String, dynamic>> varieties =
      List<Map<String, dynamic>>.from(seedData['varieties']);

      setState(() {
        _varietyName = ['Select Variety'];
        // Add all varieties for this seed
        for (var variety in varieties) {
          _varietyName.add(variety['variety_name']);
        }
        _selectedVarity = 'Select Variety';
        // Don't set _selectedSeedId here, set it when variety is selected
        _selectedSeedId = null;
      });

      print('Updated varieties for $seedName: ${_varietyName.length -
          1} options');
      print('Available varieties: $_varietyName');
    }
  }


// Add this new method to handle variety selection and set the correct seed_id
  void _onVarietySelected(String selectedVariety) {
    if (selectedVariety == 'Select Variety' || _selectedSeed == null ||
        _selectedSeed == 'Select Seed') {
      setState(() {
        _selectedSeedId = _selectedSeedId; //change adarsh
      });
      return;
    }

    // Find the seed_id for the selected seed name and variety combination
    Map<String, dynamic>? seedData = _seedVarietyMapWithIds[_selectedSeed!];

    if (seedData != null) {
      List<Map<String, dynamic>> varieties =
      List<Map<String, dynamic>>.from(seedData['varieties']);

      // Find the specific variety and get its seed_id
      for (var variety in varieties) {
        if (variety['variety_name'] == selectedVariety) {
          setState(() {
            _selectedSeedId = variety['seed_id'];
          });
          print(
              'Selected seed_id: $_selectedSeedId for variety: $selectedVariety');
          break;
        }
      }
    }
  }
}
