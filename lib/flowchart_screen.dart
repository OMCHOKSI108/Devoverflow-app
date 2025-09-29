import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'image_viewer_dialog.dart';

class FlowchartScreen extends StatefulWidget {
  const FlowchartScreen({super.key});

  @override
  State<FlowchartScreen> createState() => _FlowchartScreenState();
}

class _FlowchartScreenState extends State<FlowchartScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  String? _currentFlowId;
  Map<String, dynamic>? _flowchartData;
  String? _renderStatus;
  String? _imageUrl;
  String? _mermaidCode;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateFlowchart() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _flowchartData = null;
      _renderStatus = null;
      _imageUrl = null;
      _mermaidCode = null;
    });

    try {
      final response = await ApiService().createFlowchart(
        prompt,
        render: true,
        output: 'png',
      );
      // Response is expected to be a Map<String, dynamic> (ApiService signature)
      if (response['success'] == true) {
        // Normalize data location
        Map<String, dynamic> data = {};
        if (response['data'] is Map<String, dynamic>) {
          data = Map<String, dynamic>.from(response['data'] as Map);
        } else if (response['flowchart'] is Map<String, dynamic>) {
          data = Map<String, dynamic>.from(response['flowchart'] as Map);
        } else {
          // Fallback: use the response map itself
          data = Map<String, dynamic>.from(response);
        }

        // Extract fields safely
        final renderField = data['render'];
        String? statusFromRender;
        if (renderField is Map) {
          statusFromRender = renderField['status']?.toString();
        }

        setState(() {
          _currentFlowId = data['id']?.toString();
          _flowchartData = data;
          _mermaidCode =
              (data['mermaid'] ??
                      data['graph'] ??
                      data['mermaid_code'] ??
                      data['mermaidCode'] ??
                      '')
                  ?.toString()
                  .replaceAll('Hello user', 'Hi user')
                  .replaceAll('hello user', 'hi user');
          _renderStatus = statusFromRender ?? data['status']?.toString();

          if (_renderStatus == 'done') {
            _imageUrl = (renderField is Map)
                ? (renderField['pngUrl'] ?? data['pngUrl'])
                : data['pngUrl'];
          }
        });

        // If render is pending, start polling
        if ((_renderStatus == 'pending' || _renderStatus == 'queued') &&
            _currentFlowId != null) {
          _pollRenderStatus();
        }
        // If mermaid code exists, schedule a scroll to the bottom (mermaid code)
        if (_mermaidCode != null && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () async {
              try {
                await _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } catch (_) {}
            });
          });
        }
      } else if (response['success'] == false) {
        final msg = response['message'] ?? 'Failed to generate flowchart';
        final errors = response['errors'] ?? [];
        _showError('$msg ${errors is List ? errors.join(', ') : errors}');
      } else {
        _showError('Unexpected response shape from flowchart API');
      }
    } catch (e) {
      // ApiException includes message/status; surface it if possible
      if (e is ApiException) {
        _showError(
          'Failed to generate flowchart: ${e.message} (Status: ${e.statusCode})',
        );
      } else {
        _showError('Failed to generate flowchart: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pollRenderStatus() async {
    if (_currentFlowId == null) return;

    while (_renderStatus == 'pending' || _renderStatus == 'queued') {
      if (!mounted) return; // Stop polling if widget is not mounted

      await Future.delayed(const Duration(milliseconds: 500)); // Faster polling

      try {
        final response = await ApiService().getFlowchartRender(_currentFlowId!);

        if (!mounted) return; // Check again before processing response

        if (response['success'] == true) {
          final data = response['data'] as Map<String, dynamic>? ?? {};
          final newStatus = data['status']?.toString();

          setState(() {
            _renderStatus = newStatus;
            if (newStatus == 'done') {
              _imageUrl = data['pngUrl']?.toString();
            }
          });

          if (newStatus == 'done') {
            // When image becomes available, scroll to it so user can see
            if (mounted) {
              // small delay to allow the widget tree to update
              Future.delayed(const Duration(milliseconds: 200), () async {
                try {
                  await _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent * 0.25,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } catch (_) {}
              });
            }
            break;
          } else if (newStatus == 'failed') {
            _showError('Flowchart rendering failed');
            break;
          }
        }
      } catch (e) {
        // Continue polling on error, but add a timeout
        continue;
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Flowchart Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Prompt input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Describe your flowchart:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g., Create a flowchart showing a login process with success and failure paths',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateFlowchart,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Generate Flowchart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading && _flowchartData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating your flowchart...'),
          ],
        ),
      );
    }

    if (_flowchartData == null) {
      return const Center(
        child: Text(
          'Enter a prompt above to generate a flowchart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render status
          if (_renderStatus != null)
            Card(
              color: _renderStatus == 'done'
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _renderStatus == 'done'
                          ? Icons.check_circle
                          : Icons.hourglass_top,
                      color: _renderStatus == 'done'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _renderStatus == 'done'
                          ? 'Flowchart ready!'
                          : 'Rendering image...',
                      style: TextStyle(
                        color: _renderStatus == 'done'
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Image display: make it larger and centered; when image becomes available auto-scroll to it
          if (_imageUrl != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generated Flowchart:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => ImageViewerDialog.show(
                        context,
                        _imageUrl!,
                        title: 'Generated Flowchart',
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.95,
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.contain,
                            cacheWidth:
                                (MediaQuery.of(context).size.width * 0.95)
                                    .toInt(),
                            cacheHeight:
                                (MediaQuery.of(context).size.height * 0.5)
                                    .toInt(),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Failed to load image'),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap image to view and zoom',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Mermaid code
          if (_mermaidCode != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mermaid Code:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () async {
                            try {
                              await Clipboard.setData(
                                ClipboardData(text: _mermaidCode!),
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Code copied to clipboard'),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to copy code'),
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Copy code',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          _mermaidCode!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
