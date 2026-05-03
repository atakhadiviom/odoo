import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../state/app_state.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({
    super.key,
    required this.appState,
    required this.onProductFound,
  });

  final AppState appState;
  final ValueChanged<int> onProductFound;

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final product = await widget.appState.api.lookupBarcode(code);
      if (!mounted) return;
      widget.onProductFound(product.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for barcode: $code'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Wait a bit before allowing another scan
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan Barcode',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point your camera at a product barcode to view details.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isProcessing
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white24,
                width: 4,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _handleBarcode,
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                _ScannerOverlay(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filledTonal(
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on),
                padding: const EdgeInsets.all(16),
              ),
              IconButton.filledTonal(
                onPressed: () => _controller.switchCamera(),
                icon: const Icon(Icons.flip_camera_ios),
                padding: const EdgeInsets.all(16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        return Center(
          child: Container(
            width: size,
            height: size * 0.6,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                _Corner(top: 0, left: 0),
                _Corner(top: 0, right: 0, angle: 1.57),
                _Corner(bottom: 0, left: 0, angle: -1.57),
                _Corner(bottom: 0, right: 0, angle: 3.14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.angle = 0,
  });

  final double? top, bottom, left, right, angle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle!,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 4),
              left: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 4),
            ),
          ),
        ),
      ),
    );
  }
}
