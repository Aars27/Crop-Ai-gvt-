import 'package:cropai/Dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';



class HistoryPage extends StatelessWidget {
  final List<dynamic> historyData;

  const HistoryPage({super.key, required this.historyData});
  


  @override
  Widget build(BuildContext context) {

    // Check if there are any records
    if (historyData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF6B8E23) ,
          title: const Center(child: Text('History Records',style: TextStyle(color: Colors.white))),
          centerTitle: true,
        ),
        body: const Center(child: Text('No records found')),
      );
    }


 Future<bool> onWillPop() async {
    // Clear the entire navigation stack and go to dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
    return false; // Prevents default back behavior
  }


    // Extract the activity name from the first record for the app bar
    final String activityName = historyData[0]['activity_name'] ?? 'History Records';

    return WillPopScope(
      onWillPop: onWillPop, // Connect to the back button handler
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF6B8E23),
          title: Text('$activityName History',style: const TextStyle(color: Colors.white),),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: historyData.length,
          itemBuilder: (context, index) {
            final record = historyData[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text('Block: ${record['block_name']} - Plot: ${record['plot_name']}'),
                subtitle: Text('Date: ${record['date']}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Area', '${record['area']} sq ft'),
                        _buildInfoRow('Area (Acre)', '${record['area_acre']} acre'),
                        _buildInfoRow('Machine', record['machine_id']),
                        _buildInfoRow('Tractor', record['tractor_id']),
                        _buildInfoRow('Seed Name', record['seed_name']),
                        _buildInfoRow('HSD Cost', '₹${record['hsd_cost']}'),
                        _buildInfoRow('Manpower Cost', '₹${record['manpower_cost']}'),
                          _buildInfoRow('Total Cost', '₹${record['total_cost']}'),

                        // Other fields can be added as needed
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  
}
