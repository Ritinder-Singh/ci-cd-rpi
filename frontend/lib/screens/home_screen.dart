import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _helloData;
  Map<String, dynamic>? _systemInfo;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final hello = await apiService.getHello();
      final info = await apiService.getSystemInfo();

      setState(() {
        _helloData = hello;
        _systemInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CI/CD Platform Dashboard'),
        elevation: 2,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? _buildErrorWidget()
                : _buildSuccessWidget(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          if (_helloData != null) ...[
            Text(
              _helloData!['message'] ?? 'No message',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version: ${_helloData!['version'] ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
          ],
          if (_systemInfo != null) ...[
            SizedBox(
              width: 600,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.computer, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'System Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(
                        'CPU Usage',
                        '${_systemInfo!['cpu_percent']}%',
                        _getUsageColor(_systemInfo!['cpu_percent']),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Memory Usage',
                        '${_systemInfo!['memory_percent']}%',
                        _getUsageColor(_systemInfo!['memory_percent']),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Disk Usage',
                        '${_systemInfo!['disk_percent']}%',
                        _getUsageColor(_systemInfo!['disk_percent']),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Environment',
                        _systemInfo!['environment'] ?? 'Unknown',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Hostname',
                        _systemInfo!['hostname'] ?? 'Unknown',
                        Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getUsageColor(dynamic percent) {
    if (percent is! num) return Colors.grey;
    if (percent < 50) return Colors.green;
    if (percent < 80) return Colors.orange;
    return Colors.red;
  }
}
