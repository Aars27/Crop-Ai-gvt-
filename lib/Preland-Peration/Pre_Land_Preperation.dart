import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for input formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Dashboard/dashboard_screen.dart';
import '../widget/Constants.dart';

class Pre_Land_Preperation extends StatefulWidget {
  const Pre_Land_Preperation({super.key});

  @override
  State<Pre_Land_Preperation> createState() => PreLandPreperation();
}

class PreLandPreperation extends State<Pre_Land_Preperation> {
  // Form Key
  final _formKey = GlobalKey<FormState>();
  String _areaText = '';

  // Text Controllers
  final TextEditingController _fuelConsumptionController =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  /* final TextEditingController _majorMaintenanceController = TextEditingController();*/
  final TextEditingController _HSD_Consuption_Controller =
      TextEditingController();

  List<Map<String, TextEditingController>> _sparePartsControllers = [];

  // Focus nodes to track focus state
  final _levelingFocusNode = FocusNode();
  final _majorMaintenanceFocusNode = FocusNode();
  final _HSD_FocusNode = FocusNode();

  // Dropdown Values with default options
  final String _selectedSiteName = 'Select Site';
  String? _selectedBlockName = 'Select Block';
  String? _selectedPlotName = 'Select Plot';
  final String _selectedAreaName = 'Select Area';

  String? _selectedManPowerRoll = 'Select ManPower';

  String? _selectedLandQuality = 'Select Land Quality';

//  String? _selectedManPower = 'Select Man Power';

  final List<Map<String, dynamic>> _manpowerTypes = [];
  final List<String> _manpowerTypeNames = ['Select Man Power'];
  final Map<String, List<Map<String, dynamic>>> _categoriesByType = {};

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

  // Lists for dropdown items
  final List<String> _siteNames = ['Select Site'];
  List<String> _blockNames = ['Select Block'];
  List<String> _plotNames = ['Select Plot'];
  final List<String> _areaOptions = ['Select Area'];

  final String _selectedTractor = 'Select Tractor';
  Set<String> selectedTractors = {};
  final List<String> _tractorName = ['Select Tractor'];
final List<Map<String, dynamic>> _tractors = []; // Store full tractor data



  bool showTractorDropdown = false;
  final TextEditingController _tractorSearchController =
      TextEditingController();
  List<String> _filteredTractorNames = [];

  String? _selectedMachine = 'Select Machine';
  Set<String> selectedMachines = {};
  List<String> _machineName = ['Select Machine'];
  bool showMachineDropdown = false;
  final TextEditingController _machineSearchController =
      TextEditingController();
  List<String> _filteredMachineNames = [];

  final List<String> _machines = [
    'Select Machine',
    'Rotavator',
    'Cultivator',
    'Spring Harrow'
  ];

  List<String> _manPowerRoll = ['Select ManPower'];

  final List<Map<String, dynamic>> _machineData =
      []; // Store complete machine data
  List<String> _machineDisplayNames = [
    'Select Machine'
  ]; // For dropdown display
  Map<String, Map<String, dynamic>> selectedMachineData = {};

// For Tractor data structure
  final List<Map<String, dynamic>> _tractorData =
      []; // Store complete tractor data
  List<String> _tractorDisplayNames = [
    'Select Tractor'
  ]; // For dropdown display
  Map<String, Map<String, dynamic>> selectedTractorData = {};

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
      for (int i = 1; i < _sparePartsControllers.length; i++) {
        _sparePartsControllers[i]['part']?.dispose();
        _sparePartsControllers[i]['value']?.dispose();
      }
      _sparePartsControllers = [firstController];
    }

    _fetchBlocksAndPlots();
    _fetchTractorDetails();
    fetchCategories();
    _machineName = ['Select Machine'];
    _selectedMachine = 'Select Machine'; // Initialize with the default value
    _fetchMachineDetails();
    // Add listeners to focus nodes
    _levelingFocusNode.addListener(() {
      setState(() {});
    });
    _majorMaintenanceFocusNode.addListener(() {
      setState(() {});
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
              onPressed: _addNewSparePart,
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
                  onPressed: () => _removeSparePart(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
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
    /*  _majorMaintenanceController.dispose();*/
    _levelingFocusNode.dispose();
    _majorMaintenanceFocusNode.dispose();

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

  void _closeAllDropdowns() {
    setState(() {
      showMachineDropdown = false;
      showTractorDropdown = false;
      showCheckboxes = false;
    });
  }

// Update the machine selection widget (replace _buildMachineSelectionSection)
  Widget _buildMachineSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedMachines,
      validator: (value) {
        if (value == null || value.isEmpty) {
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
              readOnly: !showMachineDropdown,
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showMachineDropdown = true;
                  _machineSearchController.clear();
                  _filteredMachineNames = _machineDisplayNames
                      .where((machine) => machine != 'Select Machine')
                      .toList();
                });
              },
              onChanged: (value) {
                setState(() {
                  _filteredMachineNames = _machineDisplayNames
                      .where((machine) =>
                          machine != 'Select Machine' &&
                          machine.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Machine *',
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
                    ? 'Search or select machine'
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
                          setState(() {
                            showMachineDropdown = !showMachineDropdown;
                            if (showMachineDropdown) {
                              _machineSearchController.clear();
                              _filteredMachineNames = _machineDisplayNames
                                  .where(
                                      (machine) => machine != 'Select Machine')
                                  .toList();
                            } else {
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
                    final machineDisplayName = _filteredMachineNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        machineDisplayName,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedMachines.contains(machineDisplayName),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedMachines.add(machineDisplayName);

                            // Find the corresponding machine data by display name
                            int dataIndex = _machineDisplayNames
                                    .indexOf(machineDisplayName) -
                                1;
                            if (dataIndex >= 0 &&
                                dataIndex < _machineData.length) {
                              selectedMachineData[machineDisplayName] = {
                                'id': _machineData[dataIndex]['id'],
                                'machine_name': _machineData[dataIndex]
                                    ['machine_name'],
                                'machine_no': _machineData[dataIndex]
                                    ['machine_no'],
                              };
                            }
                          } else {
                            selectedMachines.remove(machineDisplayName);
                            selectedMachineData.remove(machineDisplayName);
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

// Update the tractor selection widget (replace _buildTractorSelectionSection)
  Widget _buildTractorSelectionSection() {
    return FormField<Set<String>>(
      initialValue: selectedTractors,
      validator: (value) {
        if (value == null || value.isEmpty) {
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
              readOnly: !showTractorDropdown,
              onTap: () {
                _closeAllDropdowns();
                setState(() {
                  showTractorDropdown = true;
                  _tractorSearchController.clear();
                  _filteredTractorNames = _tractorDisplayNames
                      .where((tractor) => tractor != 'Select Tractor')
                      .toList();
                });
              },
              onChanged: (value) {
                setState(() {
                  _filteredTractorNames = _tractorDisplayNames
                      .where((tractor) =>
                          tractor != 'Select Tractor' &&
                          tractor.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Tractor *',
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
                    ? 'Search or select tractor'
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
                          setState(() {
                            showTractorDropdown = !showTractorDropdown;
                            if (showTractorDropdown) {
                              _tractorSearchController.clear();
                              _filteredTractorNames = _tractorDisplayNames
                                  .where(
                                      (tractor) => tractor != 'Select Tractor')
                                  .toList();
                            } else {
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
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredTractorNames.length,
                  itemBuilder: (context, index) {
                    final tractorDisplayName = _filteredTractorNames[index];
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 4),
                      title: Text(
                        tractorDisplayName,
                        style: const TextStyle(fontFamily: "Poppins"),
                      ),
                      value: selectedTractors.contains(tractorDisplayName),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            selectedTractors.add(tractorDisplayName);

                            // Find the corresponding tractor data by display name
                            int dataIndex = _tractorDisplayNames
                                    .indexOf(tractorDisplayName) -
                                1;
                            if (dataIndex >= 0 &&
                                dataIndex < _tractorData.length) {
                              selectedTractorData[tractorDisplayName] = {
                                'id': _tractorData[dataIndex]['id'],
                                'tractor_name': _tractorData[dataIndex]
                                    ['tractor_name'],
                                'tractor_no': _tractorData[dataIndex]
                                    ['tractor_no'],
                              };
                            }
                          } else {
                            selectedTractors.remove(tractorDisplayName);
                            selectedTractorData.remove(tractorDisplayName);
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
        if (labelText == 'Type of Man Power') {
          return null;
        }
        // For all other dropdowns, keep existing validation
        if (value == null || value.startsWith('Select')) {
          return 'Please select $labelText'.tr();
        }
        return null;
      },
      decoration: InputDecoration(
        labelText:
            (labelText + (labelText == 'Type of Man Power' ? '' : ' *')).tr(),
        labelStyle: const TextStyle(
            color: Color(0xFF6B8E23),
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
      items: items.map((name) {
        return DropdownMenuItem<String>(
          value: name,
          child: Text(
            name.toString().tr(), // Apply .tr() only here for display
            style: TextStyle(
              color: name.toString().startsWith('Select')
                  ? Colors.grey
                  : Colors.black,
              fontFamily: "Poppins",
              fontSize: 14.0,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        onChanged(value);
        // If this is the manpower type dropdown, update categories
        if (labelText == 'Type of Man Power' &&
            value != null &&
            value != 'Select Man Power') {
          _updateCategoriesForType(value);
        }
      },
      icon: const SizedBox.shrink(),
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
          fontSize: 14.0,
        ),
      ),
    );
  }

// Updated _updateCategoriesForType method
  void _updateCategoriesForType(String typeName) {
    setState(() {
      // Clear previous selections
      selectedCategories.clear();
      showCheckboxes = false; // Close the dropdown when type changes

      // Clear existing controllers and focus nodes
      for (var controller in controllers.values) {
        controller.dispose();
      }
      for (var node in focusNodes.values) {
        node.dispose();
      }
      controllers.clear();
      focusNodes.clear();

      // Get categories for the selected type
      if (_categoriesByType.containsKey(typeName)) {
        List<Map<String, dynamic>> typeCategories =
            _categoriesByType[typeName]!;

        categories = typeCategories
            .map((cat) => cat['category_name'].toString())
            .toList();

        // Initialize controllers and focus nodes for new categories
        for (String category in categories) {
          controllers[category] = TextEditingController();
          focusNodes[category] = FocusNode();
        }

        print('🔄 Updated categories for $typeName: $categories');
      } else {
        categories = [];
        print('⚠️ No categories found for type: $typeName');
      }
    });
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
                    fontSize: 14,
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
                          maxLength: 3, // Added 3 digit limitation
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

          // If end time is before start time, assume it's the next day
          if (endDateTime.isBefore(startDateTime)) {
            endDateTime = endDateTime.add(const Duration(days: 1));
          }

          // Calculate hours difference
          timeHrs = endDateTime.difference(startDateTime).inMinutes / 60.0;
        }

        List<String> machineIds = [];
        if (selectedMachines.isNotEmpty) {
          for (String machineDisplayName in selectedMachines) {
            if (selectedMachineData.containsKey(machineDisplayName)) {
              int id = selectedMachineData[machineDisplayName]!['id'];
              machineIds.add(id.toString()); // Convert to string
            }
          }
        }

        List<String> tractorIds = [];
        if (selectedTractors.isNotEmpty) {
          for (String tractorDisplayName in selectedTractors) {
            if (selectedTractorData.containsKey(tractorDisplayName)) {
              int id = selectedTractorData[tractorDisplayName]!['id'];
              tractorIds.add(id.toString()); // Convert to string
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
            _selectedManPowerRoll != 'Select ManPower' &&
            !_selectedManPowerRoll!.startsWith('Select')) {
          // Find the type ID
          var selectedType = _manpowerTypes.firstWhere(
            (type) => type['type_name'] == _selectedManPowerRoll,
            orElse: () => {},
          );

          if (selectedType.isNotEmpty) {
            manpowerTypeId = selectedType['type_id'];
          }

          // Prepare categories data
          if (selectedCategories.isNotEmpty &&
              _categoriesByType.containsKey(_selectedManPowerRoll)) {
            List<Map<String, dynamic>> availableCategories =
                _categoriesByType[_selectedManPowerRoll!]!;

            for (String selectedCategoryName in selectedCategories) {
              // Find the category data
              var categoryData = availableCategories.firstWhere(
                (cat) => cat['category_name'] == selectedCategoryName,
                orElse: () => {},
              );

              if (categoryData.isNotEmpty &&
                  controllers[selectedCategoryName]?.text != null &&
                  controllers[selectedCategoryName]!.text.isNotEmpty) {
                int personCount =
                    int.tryParse(controllers[selectedCategoryName]!.text) ?? 0;
                if (personCount > 0) {
                  manpowerCategories.add({
                    'category_id': categoryData['category_id'],
                    'no_of_person': personCount,
                  });
                }
              }
            }
          }
        }
        // Prepare data for API request
        final Map<String, dynamic> requestData = {
          'block_name': _selectedBlockId?.toString(), // Send block_id instead of block_name
          'plot_name': _selectedPlotId?.toString(),
          'area': _selectedArea,
          /* 'machine_id': machineId,
          'tractor_id': tractorId,*/
          'spare_parts': sparePartsData,
          'machine_ids': machineIds, // Changed from machine_id to machine_ids
          'tractor_ids': tractorIds, // Changed from tractor_id to tractor_ids

          'area_covered': _areaController.text,
          'hsd_consumption':
              double.tryParse(_HSD_Consuption_Controller.text) ?? 0.0,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
          'date': formattedDate,
          'user_id': userId, // Now getting user_id from SharedPreferences
        };


        if (manpowerTypeId != null) {
          requestData['manpower_type_id'] = manpowerTypeId;
        }

        if (manpowerCategories.isNotEmpty) {
          requestData['manpower_categories'] = manpowerCategories;
        }

        print("Request Data: ${json.encode(requestData)}");
        print("User ID being sent: $userId"); // Debug print

        // Make API call
        final response = await http.post(
          Uri.parse('${Constanst().base_url}pre-land-preparation/store'),
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
                    'Pre Land Preparation'.tr(),
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
                          height: 50,
                        ),
                        const SizedBox(height: 5),
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
                              decimal: true), // Number keyboard with decimal
                          maxLength: 5, // Limit to 4 digits
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
                          maxLength: 6, // Limit to 4 digits
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

                        _buildCustomDropdown(
                          labelText: 'Type of Man Power'.tr(),
                          selectedValue: _selectedManPowerRoll,
                          items: _manPowerRoll,
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
      /* _selectedTractor = 'Select Tractor';
      _selectedMachine = 'Select Machine';*/

      selectedTractors.clear();
      selectedTractorData.clear();
      _tractorSearchController.clear();
      showTractorDropdown = false;

      selectedMachines.clear();
      selectedMachineData.clear();
      _machineSearchController.clear();
      showMachineDropdown = false;

      _sparePartsControllers.clear();

      _selectedLandQuality = 'Select Land Quality';

      // Clear manpower selections
      _selectedManPowerRoll = 'Select ManPower';
      selectedCategories.clear();
      showCheckboxes = false;
      for (var controller in controllers.values) {
        controller.clear();
      }

      _fuelConsumptionController.clear();
      _areaController.clear();
      /*  _majorMaintenanceController.clear();*/
      _HSD_Consuption_Controller.clear();
      _startDate = null;
      _startTime = null;
      _endTime = null;

      // Clear selected categories and their values
      selectedCategories = {};
      for (var controller in controllers.values) {
        controller.clear();
      }

      // Reset dropdowns
      _updatePlots('Select Block');

      // Reset form validation
      _formKey.currentState?.reset();
    });
  }

Future<void> _fetchTractorDetails() async {
  try {
    // Get token from SharedPreferences
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

    print('🚜 Tractor API Status: ${response.statusCode}');
    print('🚜 Tractor Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      print('🚜 Parsed Response Data: $responseData');

      // Check for different possible response structures
      bool isSuccess = false;
      List<dynamic> tractorApiData = [];

      // Try different success indicators
      if (responseData.containsKey('status') &&
          responseData['status'] == 'success') {
        isSuccess = true;
        tractorApiData = responseData['data'] ?? [];
      } else if (responseData.containsKey('success') &&
          responseData['success'] == true) {
        isSuccess = true;
        tractorApiData = responseData['data'] ?? [];
      } else if (responseData.containsKey('data')) {
        // Sometimes API might return data directly without success flag
        isSuccess = true;
        tractorApiData = responseData['data'] ?? [];
      }

      if (isSuccess && tractorApiData.isNotEmpty) {
        print('🚜 Processing ${tractorApiData.length} tractors');

        setState(() {
          // Clear existing data
          _tractorData.clear();
          _tractorDisplayNames = ['Select Tractor']; // Use _tractorDisplayNames instead of _tractorName

          // Process each tractor - handle different possible field names
          for (var tractor in tractorApiData) {
            print('🚜 Processing tractor: $tractor');

            // Try different possible field name combinations
            String tractorName = '';
            String tractorNo = '';
            dynamic tractorId = '';

            // Check for different field name variations
            if (tractor.containsKey('tractor_name')) {
              tractorName =
                  tractor['tractor_name']?.toString() ?? 'Unknown Tractor';
            } else if (tractor.containsKey('name')) {
              tractorName = tractor['name']?.toString() ?? 'Unknown Tractor';
            } else if (tractor.containsKey('tractor_model')) {
              tractorName =
                  tractor['tractor_model']?.toString() ?? 'Unknown Tractor';
            }

            if (tractor.containsKey('tractor_no')) {
              tractorNo = tractor['tractor_no']?.toString() ?? 'N/A';
            } else if (tractor.containsKey('number')) {
              tractorNo = tractor['number']?.toString() ?? 'N/A';
            } else if (tractor.containsKey('tractor_number')) {
              tractorNo = tractor['tractor_number']?.toString() ?? 'N/A';
            } else if (tractor.containsKey('registration_no')) {
              tractorNo = tractor['registration_no']?.toString() ?? 'N/A';
            }

            if (tractor.containsKey('id')) {
              tractorId = tractor['id'];
            } else if (tractor.containsKey('tractor_id')) {
              tractorId = tractor['tractor_id'];
            }

            // Only add if we have at least a name
            if (tractorName.isNotEmpty && tractorName != 'Unknown Tractor') {
              // Store complete tractor data
              _tractorData.add({
                'id': tractorId,
                'tractor_name': tractorName,
                'tractor_no': tractorNo,
              });

              // Create display name - only show number if it's not empty/N/A
              String displayName = tractorName;
              if (tractorNo.isNotEmpty && tractorNo != 'N/A') {
                displayName = '$tractorName ($tractorNo)';
              }
              _tractorDisplayNames.add(displayName); // Use _tractorDisplayNames
            }
          }

          // Update filtered list using the correct variable name
          _filteredTractorNames = _tractorDisplayNames
              .where((tractor) => tractor != 'Select Tractor')
              .toList();
        });

        print('🚜 Successfully loaded ${_tractorData.length} tractors');
        print('🚜 Tractor display names: $_tractorDisplayNames');
      } else {
        print('❌ No tractor data found or API returned false success status');
        print('❌ Response structure: $responseData');

        // Show user-friendly message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No tractors available at the moment')),
        );
      }
    } else {
      print('❌ Tractor API failed with status: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load tractors: ${response.statusCode}')),
      );
    }
  } on SocketException {
    print('❌ Network error while fetching tractors');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please connect your internet')),
    );
  } catch (e) {
    print('❌ Error fetching tractors: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error loading tractors')),
    );
  }
}


  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token!.isEmpty) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${Constanst().base_url}manpower/categories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == 'success') {
          final List<dynamic> data = body['data'];

          setState(() {
            _manpowerTypes.clear();
            _manPowerRoll = ['Select ManPower'];
            _categoriesByType.clear();

            // Store complete type data with IDs
            for (var typeData in data) {
              int typeId = typeData['type_id'];
              String typeName = typeData['type_name'];
              List<dynamic> categoriesData = typeData['categories'];

              // Store type with ID
              _manpowerTypes.add({
                'type_id': typeId,
                'type_name': typeName,
              });
              _manPowerRoll.add(typeName);

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
            }

            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  

// Update the _fetchMachineDetails method (replace the existing one)
  Future<void> _fetchMachineDetails() async {
    try {
      // Get token from SharedPreferences
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
            _machineData.clear();
            _machineDisplayNames = ['Select Machine'];

            // Process the API data
            for (var machine in machineApiData) {
              // Store complete data
              _machineData.add({
                'id': machine['id'],
                'machine_name': machine['machine_name'],
                'machine_no': machine['machine_no'],
              });

              // Create display name (machine_name + machine_no)
              String displayName =
                  '${machine['machine_name']} (${machine['machine_no']})';
              _machineDisplayNames.add(displayName);
            }

            // Initialize filtered names
            _filteredMachineNames = _machineDisplayNames
                .where((machine) => machine != 'Select Machine')
                .toList();
          });

          print('Processed machine data: $_machineData');
          print('Machine display names: $_machineDisplayNames');
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





  // showmachine drop down value

void _showMachineBottomSheet(FormFieldState<Set<String>> state) {
  TextEditingController searchController = TextEditingController();
  List<String> filteredMachines = _machineName.where((machine) => machine != 'Select Machine').toList();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setBottomSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B8E23),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.precision_manufacturing,
                       color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Select Machines'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Poppins",
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon:  const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Search Box
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setBottomSheetState(() {
                        filteredMachines = _machineName
                            .where((machine) =>
                                machine != 'Select Machine' &&
                                machine.toLowerCase().contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search machines...'.tr(),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6B8E23)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6B8E23), width: 2),
                      ),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredMachines.length,
                    itemBuilder: (context, index) {
                      final machine = filteredMachines[index];
                      final isSelected = selectedMachines.contains(machine);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF6B8E23).withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        
                        ),
                        child: CheckboxListTile(
                          checkboxShape: const CircleBorder(),
                          title: Text(
                            machine,
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? const Color(0xFF6B8E23) : Colors.black87,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? selected) {
                            setBottomSheetState(() {
                              if (selected == true) {
                                selectedMachines.add(machine);
                              } else {
                                selectedMachines.remove(machine);
                              }
                            });
                            setState(() {
                              state.didChange(selectedMachines);
                            });
                          },
                          activeColor: const Color(0xFF6B8E23),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}














}
