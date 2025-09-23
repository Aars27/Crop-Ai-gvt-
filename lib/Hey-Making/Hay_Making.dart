import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Dashboard/dashboard_screen.dart';
import '../widget/Constants.dart';

class Hay_Making extends StatefulWidget {
  const Hay_Making({super.key});

  @override
  State<Hay_Making> createState() => Hay_making();
}

class Hay_making extends State<Hay_Making> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';

  // Text Controllers
  final TextEditingController _fuelConsumptionController =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _yieldController = TextEditingController();
/*
  final TextEditingController _majorMaintenanceController = TextEditingController();
*/
  final TextEditingController _HSD_Consuption_Controller =
      TextEditingController();

  List<Map<String, TextEditingController>> _sparePartsControllers = [];

  // Focus nodes to track focus state
  final _levelingFocusNode = FocusNode();
  final _majorMaintenanceFocusNode = FocusNode();
  final _HSD_FocusNode = FocusNode();

  // Dropdown Values with default options
  final String _selectedSiteName = 'Select Site';
  String? _selectedBlockName = 'Select Block'.tr();
  String? _selectedPlotName = 'Select Plot'.tr();
  final String _selectedAreaName = 'Select Area';

  String? _selectedMethodHayMaking = 'Select Method'.tr();
  String? _selectedManPowerRoll = 'Select ManPower';

  String? _selectedSeedName = 'Select Seed Name'.tr();

  List<String> _seedName = ['Select Seed Name'.tr()];

  String? _selectedLandQuality = 'Select Land Quality';

//  String? _selectedManPower = 'Select Man Power';

  List<Map<String, dynamic>> _seedsWithIds = [];
  int? _selectedSeedId;

  List<Map<String, dynamic>> _tractorData = [];
  List<Map<String, dynamic>> _machineData = [];
  List<String> _tractorDisplayNames = ['Select Tractor'];
  List<String> _machineDisplayNames = ['Select Machine'];

  // ID storage for API communication
  int? _selectedSiteId;
  int? _selectedBlockId;
  int? _selectedPlotId;
  double? _selectedArea;

  // Date and Time Controllers
  DateTime? _startDate= DateTime.now();
  TimeOfDay? _startTime= TimeOfDay.now() ;
  TimeOfDay? _endTime = TimeOfDay.fromDateTime
  (DateTime.now().add(const Duration(hours:4)));

  bool _formFieldsEnabled = false;

  String yieldMt = '';

  // API Data
  final List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _blocks = [];
  List<Map<String, dynamic>> _plots = [];

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'.tr()];
  List<String> _plotNames = ['Select Plot'.tr()];
  final List<String> _areaOptions = ['Select Area'];




  String? _selectedTractor = 'Select Tractor';
  Set<String> selectedTractors = {};
  final List<String> _tractorName = ['Select Tractor'];
  bool showTractorDropdown = false;
  final TextEditingController _tractorSearchController =
      TextEditingController();
  List<String> _filteredTractorNames = [];

  String? _selectedMachine = 'Select Machine';
  Set<String> selectedMachines = {};
  final List<String> _machineName = ['Select Machine'];
  bool showMachineDropdown = false;
  final TextEditingController _machineSearchController =
      TextEditingController();
  List<String> _filteredMachineNames = [];

//  List<String> _manPowerName = ['Select Man Power'];

// Add these variables at the top with other declarations
  final List<Map<String, dynamic>> _manpowerTypes = [];
  List<String> _manpowerTypeNames = ['Select Man Power'.tr()];
    final Map<String, List<Map<String, dynamic>>> _categoriesByType = {};

  
  
  
  List<Map<String, dynamic>> _filteredCategories = [];
  List<String> _filteredCategoryNames = ['Select Category'.tr()];

  final List<String> _methodHaymakingName = [
    'Select Method',
    'Manual',
    'Mechanical-Sun Drying',
    'Tedding & Raking',
    'Baling',
    'Silage',
    'Windrow',
    'Haylage'
  ];

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

    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });
    /* _majorMaintenanceFocusNode.addListener(() {
      setState(() {});
    });*/
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

  Future<void> _fetchBlocksAndPlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${Constanst().base_url}check-Hay-Making'),
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

            // Process blocks data with IDs
            for (var block in blocksData) {
              _blocks.add({
                'block_id': block['block_id'], // Store block ID
                'block_name': block['block_name'],
                'plots': block['plots'],
              });
              _blockNames.add(block['block_name'].toString());
            }

            // Initialize plot dropdown with just the default option
            _plots = [];
            _plotNames = ['Select Plot'];

            // Initialize seed dropdown with just the default option
            _seedName = ['Select Seed Name'];
            _selectedSeedName = 'Select Seed Name';
            _seedsWithIds = []; // Reset seeds with IDs
            _selectedSeedId = null; // Reset selected seed ID

            // Reset area text
            _areaText = '';
            _selectedArea = null;

            // Initial state is disabled
            _formFieldsEnabled = false;

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
    // Check if "Select Block" is chosen
    if (blockName == 'Select Block') {
      setState(() {
        // Reset plot dropdown
        _plots = [];
        _plotNames = ['Select Plot'];
        _selectedPlotName = 'Select Plot';

        // Reset seed dropdown
        _seedName = ['Select Seed Name'];
        _selectedSeedName = 'Select Seed Name';
        _seedsWithIds = [];
        _selectedSeedId = null;

        // Reset area field
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;
        _selectedBlockId = null; // Reset block ID

        // Disable form fields
        _formFieldsEnabled = false;
      });
      return;
    }

    // Find selected block with ID
    final selectedBlock = _blocks.firstWhere(
          (block) => block['block_name'] == blockName,
      orElse: () => {},
    );

    if (selectedBlock.isNotEmpty) {
      setState(() {
        _selectedBlockId = selectedBlock['block_id']; // Store actual block ID

        // Reset subsequent selections
        _selectedPlotName = 'Select Plot';
        _selectedPlotId = null;
        _selectedArea = null;
        _areaText = ''; // Clear area text

        // Reset seed dropdown
        _seedName = ['Select Seed Name'];
        _selectedSeedName = 'Select Seed Name';
        _seedsWithIds = [];
        _selectedSeedId = null;

        // Disable form fields when changing blocks
        _formFieldsEnabled = false;

        // Update plots for the selected block
        final List<dynamic> plotsData = selectedBlock['plots'];
        _plots = List<Map<String, dynamic>>.from(plotsData.map((plot) => {
          'plot_id': plot['plot_id'], // Store plot ID
          'plot_name': plot['plot_name'],
          'area': plot['area'],
          'is_fodder_crop': plot['is_fodder_crop'],
          'seed_name': plot['seed_name'],
          'yield_mt': plot['yield_mt'],
          'seed_id': plot['seed_id'], // Add seed_id
        }));

        // Update plot names dropdown - use unique plot names to avoid duplicates
        _plotNames = ['Select Plot'];
        final uniquePlotNames = <String>{};
        for (var plot in _plots) {
          uniquePlotNames.add(plot['plot_name'].toString());
        }
        _plotNames.addAll(uniquePlotNames);

        // Collect all unique seed names from all plots in this block
        _updateSeedNamesForBlock();

        // Print the plots data for debugging
        print('Plots loaded for block $blockName: $_plots');
        print('Selected Block ID: $_selectedBlockId');
      });
    }
  }




  void _updateSeedNamesForBlock() {
    setState(() {
      // Reset seed dropdown with default option
      _seedName = ['Select Seed Name'.tr()];
      _seedsWithIds = [];

      // Collect all unique seeds with IDs from all plots
      final Map<String, int> uniqueSeeds = {}; // seed_name -> seed_id

      for (var plot in _plots) {
        if (plot['seed_name'] != null &&
            plot['seed_name'].toString().isNotEmpty) {
          uniqueSeeds[plot['seed_name'].toString()] = plot['seed_id'];
        }
      }

      // Add unique seed names to dropdown and store seeds with IDs
      uniqueSeeds.forEach((seedName, seedId) {
        _seedName.add(seedName);
        _seedsWithIds.add({
          'seed_id': seedId,
          'seed_name': seedName,
        });
      });

      print('Available seed names with IDs: $_seedsWithIds');
    });
  }

// Update area text based on selected plot

  // 5. Update the _updateAreaText method
  void _updateAreaText(String plotName) {
    // Check if "Select Plot" is chosen
    if (plotName == 'Select Plot') {
      setState(() {
        _areaText = '';
        _selectedArea = null;
        _selectedPlotId = null;

        // Reset seed selection but keep all available seed names
        _selectedSeedName = 'Select Seed Name';
        _selectedSeedId = null;

        // Don't disable form fields here - let seed selection control it
        _resetFormFieldsOnly(); // Reset just the form fields, not the selections
      });
      return;
    }

    // Find plot with matching name and get the first occurrence with its ID
    final matchingPlot = _plots.firstWhere(
          (plot) => plot['plot_name'] == plotName,
      orElse: () => {},
    );

    if (matchingPlot.isNotEmpty) {
      setState(() {
        _selectedPlotId = matchingPlot['plot_id']; // Store actual plot ID
        _selectedArea = double.tryParse(matchingPlot['area'].toString());
        // Set the area text directly
        _areaText = '${matchingPlot['area']} ';

        // Keep all seed names available but reset selection
        _selectedSeedName = 'Select Seed Name';
        _selectedSeedId = null;

        // Don't enable/disable form here - let seed selection control it
        // Reset form fields but keep the plot selection
        _resetFormFieldsOnly();

        print('Selected Plot ID: $_selectedPlotId for plot: $plotName');
      });
    }
  }



  void _resetFormFieldsOnly() {
    // Reset all form field values but keep plot and block selections
    _fuelConsumptionController.clear();
    _areaController.clear();
    _yieldController.clear();

    _HSD_Consuption_Controller.clear();
    _selectedTractor = 'Select Tractor';
    _selectedMachine = 'Select Machine';
    _selectedMethodHayMaking = 'Select Method';
    _selectedManPowerRoll = 'Select ManPower';
    _selectedLandQuality = 'Select Land Quality';
    _startDate = null;
    _startTime = null;
    _endTime = null;

    selectedMachines.clear();
    _machineSearchController.clear();
    showMachineDropdown = false;

    selectedTractors.clear();
    _tractorSearchController.clear();
    showTractorDropdown = false;

    // Reset filtered lists with new variable names
    _filteredTractorNames = _tractorDisplayNames // Changed from _tractorName
        .where((tractor) => tractor != 'Select Tractor')
        .toList();
    _filteredMachineNames = _machineDisplayNames // Changed from _machineName
        .where((machine) => machine != 'Select Machine')
        .toList();

    // Clear selected categories and their values
    selectedCategories = {};
    for (var controller in controllers.values) {
      controller.clear();
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    _fuelConsumptionController.dispose();
    _areaController.dispose();
    _yieldController.dispose();
    _levelingFocusNode.dispose();

    for (var controllerMap in _sparePartsControllers) {
      controllerMap['part']?.dispose();
      controllerMap['value']?.dispose();
    }

    for (var controller in controllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    super.dispose();
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
              icon: const Icon(Icons.add, size: 14,color: Colors.white,),
              label: Text('Add Spare'.tr()),
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
              onPressed: _formFieldsEnabled ? _addNewSparePart : null,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Display all spare parts fields
        ..._sparePartsControllers.asMap().entries.map((entry) {
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
                  onPressed:
                      _formFieldsEnabled ? () => _removeSparePart(index) : null,
                ),
              ],
            ),
          );
        }),
      ],
    );
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
        if (_formFieldsEnabled && (value == null || value.isEmpty)) {
          return 'Please select at least one machine';
        }
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _machineSearchController,
              readOnly: !showMachineDropdown || !_formFieldsEnabled,
              enabled: _formFieldsEnabled,
              onTap: _formFieldsEnabled
                  ? () {
                      // Only open dropdown if it's not already open
                      if (!showMachineDropdown) {
                        _closeAllDropdowns();
                        setState(() {
                          showMachineDropdown = true;
                          // Clear search text when opening dropdown
                          _machineSearchController.clear();
                          // Reset filtered list when opening dropdown
                          _filteredMachineNames =
                              _machineDisplayNames // Changed from _machineName
                                  .where(
                                      (machine) => machine != 'Select Machine')
                                  .toList();
                        });
                      }
                    }
                  : null,
              onChanged: _formFieldsEnabled
                  ? (value) {
                      setState(() {
                        _filteredMachineNames =
                            _machineDisplayNames // Changed from _machineName
                                .where((machine) =>
                                    machine != 'Select Machine' &&
                                    machine
                                        .toLowerCase()
                                        .contains(value.toLowerCase()))
                                .toList();
                      });
                    }
                  : null,
              decoration: InputDecoration(
                labelText: 'Machine *'.tr(),
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
                fillColor:
                    _formFieldsEnabled ? Colors.white : Colors.grey.shade100,
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
                              // In the toggle dropdown section:
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
                height: 200,
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
        if (_formFieldsEnabled && (value == null || value.isEmpty)) {
          return 'Please select at least one tractor';
        }
        return null;
      },
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _tractorSearchController,
              readOnly: !showTractorDropdown || !_formFieldsEnabled,
              enabled: _formFieldsEnabled,
              onTap: _formFieldsEnabled
                  ? () {
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
                    }
                  : null,
              onChanged: _formFieldsEnabled
                  ? (value) {
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
                    }
                  : null,
              decoration: InputDecoration(
                labelText: 'Tractor *'.tr(),
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
                fillColor:
                    _formFieldsEnabled ? Colors.white : Colors.grey.shade100,
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
    if (!_formFieldsEnabled) {
      return; // Prevent date selection if fields are disabled
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

  // Time Picker Method
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    if (!_formFieldsEnabled) {
      return; // Prevent time selection if fields are disabled
    }

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
    TextEditingController? controller,
    FocusNode? focusNode,
    bool isRequired = true,
    String? Function(String?)? customValidator,
    int? maxLength,
    bool enabled = true,
    String? initialText,
  }) {
    final textController = controller ??
        TextEditingController(
          text: initialText ?? '',
        );

    // ✅ If you pass a controller but don't want prefill, clear it
    if (controller == null && initialText != null) {
      textController.text = initialText;
    }

    // All form fields follow the same enable/disable logic
    final bool isFieldEnabled = enabled && _formFieldsEnabled;

    return TextFormField(
      onTap: () {
        setState(() {
          _closeAllDropdowns();
        });
      },
      enabled: isFieldEnabled,
      controller: textController,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter: (context,
              {required currentLength, required isFocused, maxLength}) =>
          null,
      validator: (value) {
        // Only validate if form fields are enabled
        if (!_formFieldsEnabled) return null;
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $labelText';
        }
        if (maxLength != null && value != null && value.length > maxLength) {
          return '$labelText cannot exceed $maxLength characters';
        }
        if (customValidator != null) {
          return customValidator(value);
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText + (isRequired && _formFieldsEnabled ? ' *' : ''),
        labelStyle: TextStyle(
          color: isFieldEnabled ? const Color(0xFF6B8E23) : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14.0,
          fontFamily: "Poppins",
        ),
        hintText: hintText ?? 'Enter $labelText',
        hintStyle: const TextStyle(
          fontFamily: "Poppins",
          fontSize: 14.0,
          color: Colors.grey,
        ),
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
              color:
                  isFieldEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
        ),
        filled: true,
        fillColor: isFieldEnabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }

// 1. Update your _buildCustomDropdown method to handle seed name specially
  Widget _buildCustomDropdown({
    required String labelText,
    required String? selectedValue,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = true,
  }) {
    // Ensure items list doesn't have duplicates
    final uniqueItems = items.toSet().toList();

    // Check if selectedValue exists in the uniqueItems list
    final bool valueInItems =
        selectedValue != null && uniqueItems.contains(selectedValue);

    // If the selected value isn't in the items list, use the first item or null
    final String? validatedValue = valueInItems
        ? selectedValue
        : (uniqueItems.isNotEmpty ? uniqueItems[0] : null);

    // Check if this is Type of Man Power field to make it optional
    final bool isTypeOfManPower =
        labelText == 'Type of Man Power' || labelText == 'Type of Man Power ';
    final bool fieldRequired = isTypeOfManPower ? false : isRequired;

    // Always enabled fields: Block Name, Plot Name, Seed Name
    final bool isAlwaysEnabled = labelText == 'Block Name' ||
        labelText == 'Plot Name' ||
        labelText == 'Seed Name' ||
        labelText == 'Seed Name ';

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
        // Make Type of Man Power optional
        if (isTypeOfManPower) {
          return null; // No validation for Type of Man Power
        }

        // For always enabled fields (Block, Plot, Seed), always validate
        if (isAlwaysEnabled &&
            fieldRequired &&
            (value == null || value.startsWith('Select'))) {
          return 'Please select $labelText';
        }

        // For other fields, only validate when form is enabled
        if (_formFieldsEnabled &&
            fieldRequired &&
            (value == null || value.startsWith('Select'))) {
          return 'Please select $labelText';
        }
        return null;
      },
      decoration: InputDecoration(
        // Remove asterisk (*) for Type of Man Power, keep for others
        labelText: labelText + (fieldRequired ? ' *' : ''),
        labelStyle: TextStyle(
            color: (_formFieldsEnabled || isAlwaysEnabled)
                ? const Color(0xFF6B8E23)
                : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
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
            color: (_formFieldsEnabled || isAlwaysEnabled)
                ? Colors.grey.shade400
                : Colors.grey.shade300,
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
        fillColor: (_formFieldsEnabled || isAlwaysEnabled)
            ? Colors.white
            : Colors.grey.shade100,
        suffixIcon: Icon(
          Icons.keyboard_arrow_down,
          color: (_formFieldsEnabled || isAlwaysEnabled)
              ? const Color(0xFF6B8E23)
              : Colors.grey,
        ),
      ),
      value: validatedValue,
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
      onChanged: (_formFieldsEnabled || isAlwaysEnabled) ? onChanged : null,
      icon: const SizedBox.shrink(), // Remove default dropdown icon
      dropdownColor: Colors.white,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: "Poppins",
      ),
    );
  }

  Widget _buildManpowerSection() {
    bool isTypeSelected = _selectedManPowerRoll != null &&
        _selectedManPowerRoll != 'Select Man Power'.tr() &&
        !_selectedManPowerRoll!.startsWith('Select');

    return FormField<Set<String>>(
      initialValue: selectedCategories,
      validator: null, // No validation required since it's optional
      builder: (FormFieldState<Set<String>> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _closeAllDropdowns();
                if (!_formFieldsEnabled) {
                  return; // Prevent interaction if disabled
                }
                setState(() {
                  showCheckboxes = !showCheckboxes;
                });
              },
              child: InputDecorator(
                decoration: InputDecoration(
                    labelText:
                        'Category of Man Power'.tr(), // Removed asterisk (*) since it's optional
                    errorText: state.errorText,
                    labelStyle: TextStyle(
                      color: _formFieldsEnabled
                          ? const Color(0xFF6B8E23)
                          : Colors.grey,
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
                      borderSide:
                          const BorderSide(color: Colors.grey, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(
                          color: _formFieldsEnabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade300,
                          width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B8E23), width: 2),
                    ),
                    filled: true,
                    fillColor: _formFieldsEnabled
                        ? Colors.white
                        : Colors.grey.shade100,
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
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (showCheckboxes && _formFieldsEnabled)
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
                          // Clear the text field value when category is unselected
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
            if (selectedCategories.isNotEmpty && _formFieldsEnabled)
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
                        child: _buildCustomTextField(
                          labelText: category,
                          controller: controllers[category]!,
                          focusNode: focusNodes[category],
                          keyboardType: TextInputType.number,
                          maxLength: 3, // Add maximum length limit
                          customValidator: (value) {
                            // Validation sirf tab hai jab category selected hai
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

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: SizedBox(
        width: 100,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            // Check basic requirements first
            if (_selectedBlockName == 'Select Block' ||
                _selectedPlotName == 'Select Plot' ||
                _selectedSeedName == 'Select Seed Name') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Please select Block, Plot, and Seed Name first'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              return;
            }

            // If form fields are disabled (is_fodder_crop == 0), submit with basic data only
            if (!_formFieldsEnabled) {
              _submitBasicForm();
            } else {
              // If form fields are enabled, do full validation and submit
              _submitForm();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B8E23),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Submit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: "Poppins",
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitBasicForm() async {
    // Validate Area Covered since it's always enabled
    if (_areaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill Area Covered field'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token') ?? '';
      int? userId = prefs.getInt('user_id');

      if (token.isEmpty) {
        throw Exception('Authentication data not found');
      }

      final Map<String, dynamic> requestData = {
        'block_name': _selectedBlockId,
        'plot_name': _selectedPlotId,
        'area': _selectedArea,
        'area_covered': _areaController.text, // Include area covered
        'seed_name': _selectedSeedName,
        'seed_id': _selectedSeedId, // Add this line to send seed_id
        'user_id': userId,
        'is_basic_submission': true, // Flag to indicate this is a basic submission
      
      };


      final response = await http.post(
        Uri.parse('${Constanst().base_url}store-hay-making'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Basic details submitted successfully'),
            backgroundColor: Color(0xFF6B8E23),
            duration: Duration(seconds: 3),
          ),
        );
        _resetForm();
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit basic details'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
              '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
        }

        if (_endTime != null) {
          endTimeStr =
              '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';
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

          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(const Duration(days: 1));
          }

          timeHrs = endDateTime.difference(startDateTime).inMinutes / 60.0;
        }

       List<String> machineIds = [];
if (selectedMachines.isNotEmpty) {
  for (String machineDisplayName in selectedMachines) {
    // Find the machine data by display name
    for (var machine in _machineData) {
      String displayName = '${machine['machine_name']} - ${machine['machine_no']}';
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
      String displayName = '${tractor['tractor_name']} - ${tractor['tractor_type']}';
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

        
        
// Prepare manpower data for API
int? manpowerTypeId;
List<Map<String, dynamic>> manpowerCategories = [];

// Get manpower type ID
if (_selectedManPowerRoll != null &&
    _selectedManPowerRoll != 'Select Man Power'.tr() &&
    !_selectedManPowerRoll!.startsWith('Select')) {
  
  // Find the type ID from _manpowerTypes list
  var selectedType = _manpowerTypes.firstWhere(
    (type) => type['type_name'] == _selectedManPowerRoll,
    orElse: () => {},
  );

  if (selectedType.isNotEmpty) {
    manpowerTypeId = selectedType['type_id'];
    
    print("Selected manpower type ID: $manpowerTypeId");
    
    // Prepare categories data if any categories are selected
    if (selectedCategories.isNotEmpty) {
      // Get categories for the selected type
      List<Map<String, dynamic>>? availableCategories = _categoriesByType[_selectedManPowerRoll];
      
      if (availableCategories != null) {
        for (String selectedCategoryName in selectedCategories) {
          // Find the category data with ID
          var categoryData = availableCategories.firstWhere(
            (cat) => cat['category_name'] == selectedCategoryName,
            orElse: () => {},
          );

          if (categoryData.isNotEmpty) {
            // Get the person count from controller
            String? personCountText = controllers[selectedCategoryName]?.text;
            
            if (personCountText!.isNotEmpty) {
              int personCount = int.tryParse(personCountText) ?? 0;
              
              if (personCount > 0) {
                manpowerCategories.add({
                  'category_id': categoryData['category_id'],
                  'no_of_person': personCount,
                });
                
                print("Added category: ${categoryData['category_name']} (ID: ${categoryData['category_id']}) with $personCount persons");
              }
            }
          }
        }
      }
    }
  }
}


        final Map<String, dynamic> requestData = {
          'block_name': _selectedBlockId.toString(),
          'plot_name': _selectedBlockId.toString(),
          'area': _selectedArea,
          'machine_ids': machineIds, // Include machine IDs
  'tractor_ids': tractorIds, // Include tractor IDs
          'spare_parts': sparePartsData,
          'area_covered': _areaController.text,
          'yield_mt': _yieldController.text,
          'hay_making_method': _selectedMethodHayMaking == 'Select Method'
              ? null
              : _selectedMethodHayMaking,
          'seed_name': _selectedSeedName == 'Select Seed Name'
              ? null
              : _selectedSeedName,
          'seed_id': _selectedSeedId, // Add this line to send seed_id
          'hsd_consumption':
          double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'date': formattedDate,
          'user_id': userId,
        };





// Add manpower data to request only if type is selected
if (manpowerTypeId != null) {
  requestData['manpower_type_id'] = manpowerTypeId;
  
  // Only add categories if there are any
  if (manpowerCategories.isNotEmpty) {
    requestData['manpower_categories'] = manpowerCategories;
  }
}
       
        print("Request Data: ${json.encode(requestData)}");
        print("User ID being sent: $userId");

        final response = await http.post(
          Uri.parse('${Constanst().base_url}store-hay-making'),
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
          try {
            final errorData = jsonDecode(response.body);
            String errorMessage = '';

            if (errorData.containsKey('error')) {
              String mainError = errorData['error'] ?? 'Failed to submit data';

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
                duration: const Duration(seconds: 4),
              ),
            );
          } catch (parseError) {
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
                expandedHeight: 158.0,
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
                    'Hay Making'.tr(),
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
                              return 'Please select a plot first';
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
                          maxLength: 5,
                          customValidator: (value) {
                            if (!_formFieldsEnabled) {
                              return null; // Skip validation if disabled
                            }

                            if (value == null || value.isEmpty) {
                              return 'Please enter area covered'.tr();
                            }

                            // Check if the value is a valid number
                            double? enteredArea = double.tryParse(value);
                            if (enteredArea == null) {
                              return 'Please enter a valid number'.tr();
                            }

                            // Check if _selectedArea (total area) has a value to compare against
                            if (_selectedArea != null &&
                                enteredArea > _selectedArea!) {
                              return 'Area covered cannot exceed total area (${_selectedArea!.toStringAsFixed(2)})';
                            }

                            // Check for negative values
                            if (enteredArea < 0) {
                              return 'Area covered cannot be negative';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        _buildCustomDropdown(
                          labelText: 'Seed Name'.tr(),
                          selectedValue: _selectedSeedName,
                          items: _seedName,
                          onChanged: (value) {
                            if (value != null && value != 'Select Seed Name') {
                              // Find and store the corresponding seed_id
                              var selectedSeed = _seedsWithIds.firstWhere(
                                    (seed) => seed['seed_name'] == value,
                                orElse: () => {},
                              );

                              if (selectedSeed.isNotEmpty) {
                                _selectedSeedId = selectedSeed['seed_id'];
                                print('Selected seed: $value with ID: $_selectedSeedId');
                              }

                              _updateFormBasedOnSeed(value); // Call this method when seed is selected
                            } else {
                              setState(() {
                                _selectedSeedName = value;
                                _selectedSeedId = null;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 20),

                        _buildCustomTextField(
                          enabled: false,
                          labelText: 'Total Green Fodder Yield (MT)'.tr(),
                          hintText: 'Total Yield'.tr(),
                          initialText: yieldMt,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true), // Number keyboard with decimal
                        ),

                        const SizedBox(height: 20),

                        // Yield TextField

                        _buildCustomTextField(
                          isRequired: true,
                          enabled:
                              _formFieldsEnabled, // Add this line to make it disable/enable with other fields
                          labelText: 'Yield (MT)'.tr(),
                          hintText: 'Enter a Yield'.tr(),
                          controller: _yieldController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          customValidator: (value) {
                            if (!_formFieldsEnabled) {
                              return null; // Skip validation if disabled
                            }

                            if (value == null || value.isEmpty) {
                              return 'Please enter yield value';
                            }

                            // Check if the value is a valid number
                            double? enteredYield = double.tryParse(value);
                            if (enteredYield == null) {
                              return 'Please enter a valid number';
                            }

                            // Check if yieldMt (total yield) has a value to compare against
                            if (yieldMt.isNotEmpty) {
                              double? totalYield = double.tryParse(yieldMt);
                              if (totalYield != null &&
                                  enteredYield > totalYield) {
                                return 'Yield cannot exceed total yield ($yieldMt MT)';
                              }
                            }

                            // Check for negative values
                            if (enteredYield < 0) {
                              return 'Yield cannot be negative';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        // Date Picker
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

                        // Method Of Hay Making Dropdown
                        _buildCustomDropdown(
                          labelText: 'Method Of Hay Making'.tr(),
                          selectedValue: _selectedMethodHayMaking,
                          items: _methodHaymakingName,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMethodHayMaking = value;
                              });
                            }
                          },
                        ),

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
                          maxLength: 6, // Add this line

                          customValidator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter HSD consumption';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Time Pickers Row
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

                        // Type of Man Power Dropdown
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

                        _buildSparePartsSection(),

                        const SizedBox(height: 20),

                        // Submit Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: SizedBox(
                            width: 100,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _formFieldsEnabled
                                  ? _submitForm
                                  : null, // Only enable if _formFieldsEnabled is true
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _formFieldsEnabled
                                    ? const Color(0xFF6B8E23)
                                    : Colors
                                        .grey, // Change color based on enabled state
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(
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

//////////////////////////////////////////////////////////////////////////////////////////////////

  void _resetForm() {
    setState(() {
      _selectedBlockName = 'Select Block';
      _selectedPlotName = 'Select Plot';
      _areaText = '';
      _selectedArea = null;
      _selectedBlockId = null;
      _selectedPlotId = null;

      // Clear machine and tractor selections
      _selectedTractor = 'Select Tractor';
      _selectedMachine = 'Select Machine';
      selectedTractors.clear(); // Add this
      selectedMachines.clear(); // Add this
      showTractorDropdown = false;
      showMachineDropdown = false;
      _tractorSearchController.clear();
      _machineSearchController.clear();

      _selectedSeedId = null;
      _seedsWithIds = [];

      _selectedLandQuality = 'Select Land Quality';
      _selectedSeedName = 'Select Seed Name'.tr();
      _fuelConsumptionController.clear();
      _areaController.clear();
      _yieldController.clear();

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

      // Ensure form fields are disabled
      _formFieldsEnabled = false;
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


  Future<void> fetchCategories() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  if (token!.isEmpty) {
    print("No auth token found");
    return;
  }

  try {
    print("Making API call to fetch categories...");
    final response = await http.post(
      Uri.parse('${Constanst().base_url}manpower/categories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    print("Response status code: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      
      print("Decoded response: $body");

      if (body['status'] == 'success') {
        final List<dynamic> data = body['data'];
        
        print("Data from API: $data");

        setState(() {
          _manpowerTypes.clear();
          _manpowerTypeNames = ['Select Man Power'.tr()]; // Fixed this line
          _categoriesByType.clear();

          // Store complete type data with IDs
          for (var typeData in data) {
            int typeId = typeData['type_id'];
            String typeName = typeData['type_name'];
            List<dynamic> categoriesData = typeData['categories'];

            print("Processing type: $typeName with ID: $typeId");
            print("Categories for $typeName: $categoriesData");

            // Store type with ID
            _manpowerTypes.add({
              'type_id': typeId,
              'type_name': typeName,
            });
            _manpowerTypeNames.add(typeName); // Fixed this line

            // Store categories with IDs
            List<Map<String, dynamic>> typeCategories = [];
            for (var categoryData in categoriesData) {
              typeCategories.add({
                'category_id': categoryData['category_id'],
                'category_name': categoryData['category_name'],
                'no_of_person': categoryData['no_of_person'],
              });
            }
            _categoriesByType[typeName] = typeCategories;
            
            print("Stored categories for $typeName: $typeCategories");
          }

          print("Final _manpowerTypeNames: $_manpowerTypeNames");
          print("Final _manpowerTypes: $_manpowerTypes");
          print("Final _categoriesByType: $_categoriesByType");

          isLoading = false;
        });
      } else {
        print("API response status is not success: ${body['status']}");
      }
    } else {
      print("HTTP error: ${response.statusCode}");
    }
  } catch (e) {
    print("Error in fetchCategories: $e");
    setState(() => isLoading = false);
  }
}

// Also update the _updateCategoriesForType method:
void _updateCategoriesForType(String selectedTypeName) {
  print("_updateCategoriesForType called with: $selectedTypeName");
  
  if (selectedTypeName == 'Select Man Power'.tr()) {
    setState(() {
      _filteredCategories = [];
      _filteredCategoryNames = ['Select Category'.tr()];
      selectedCategories.clear();
      categories = []; // Clear the categories list
      // Clear all controllers
      for (var controller in controllers.values) {
        controller.clear();
      }
      controllers.clear();
      focusNodes.clear();
    });
    return;
  }

  // Check if we have categories for this type
  if (!_categoriesByType.containsKey(selectedTypeName)) {
    print("No categories found for type: $selectedTypeName");
    print("Available types in _categoriesByType: ${_categoriesByType.keys}");
    return;
  }

  List<Map<String, dynamic>> typeCategories = _categoriesByType[selectedTypeName]!;
  print("Found ${typeCategories.length} categories for $selectedTypeName: $typeCategories");

  setState(() {
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

    // Reset categories list
    categories = [];
    _filteredCategoryNames = ['Select Category'.tr()];

    // Setup new categories
    for (var category in typeCategories) {
      String categoryName = category['category_name'].toString();
      _filteredCategoryNames.add(categoryName);
      categories.add(categoryName);

      // Initialize controllers and focus nodes
      controllers[categoryName] = TextEditingController();
      focusNodes[categoryName] = FocusNode();
      
      print("Added category: $categoryName");
    }
    
    print("Final categories list: $categories");
    print("Final controllers keys: ${controllers.keys}");
  });
}


// Method to handle seed selection and form enabling/disabling
  void _updateFormBasedOnSeed(String seedName) {
    final selectedEntry = _plots.firstWhere(
          (plot) =>
      plot['plot_name'] == _selectedPlotName &&
          plot['seed_name'] == seedName,
      orElse: () => {},
    );

  

    // Find the specific plot-seed combination

    if (selectedEntry.isNotEmpty) {
      bool enableFields = selectedEntry['is_fodder_crop'] == 1;
      yieldMt = selectedEntry['yield_mt']?.toString() ?? '';

      print('Seed selected: $seedName');
      print('Seed ID: $_selectedSeedId');
      print('total_yield: $yieldMt');
      print('is_fodder_crop: ${selectedEntry['is_fodder_crop']}');
      print('Form fields will be: ${enableFields ? 'enabled' : 'disabled'}');

      setState(() {
        _selectedSeedName = seedName;
        _formFieldsEnabled = enableFields; // Enable/disable form based on is_fodder_crop

        // If fields are disabled, reset form fields but keep the selections
        if (!_formFieldsEnabled) {
          _resetFormFieldsOnly();
        }
      });

      // Show a message to the user based on the fodder crop status
      if (!enableFields) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Hay making is not enabled for $seedName. Form fields are disabled.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
