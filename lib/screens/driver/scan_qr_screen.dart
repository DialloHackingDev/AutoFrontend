import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/booking_provider.dart';
import '../../services/location_service.dart';

class ScanQrScreen extends StatefulWidget {
  final String? bookingId;

  const ScanQrScreen({super.key, this.bookingId});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _isScanning = true;
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isScanning = false);

    if (widget.bookingId == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Validation'),
          content: Text('Code scanné : $code'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      ).then((_) {
      if (mounted) Navigator.pop(context);
    });
      return;
    }

    Position? position = await _getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      setState(() => _isScanning = true);
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final success = await bookingProvider.startTrip(
      bookingId: widget.bookingId!,
      driverLatitude: position.latitude,
      driverLongitude: position.longitude,
      qrData: code,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validation'),
        content: Text(
          success
              ? 'Trajet démarré avec succès.'
              : bookingProvider.errorMessage ?? 'La validation a échoué.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      return await LocationService().getCurrentPosition();
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return null;
    }
  }

  Future<void> _submitTripStart({String? qrCode, String? otp}) async {
    if (widget.bookingId == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    Position? position = await _getCurrentPosition();
    if (position == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    if (!mounted) return;

    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final success = await bookingProvider.startTrip(
      bookingId: widget.bookingId!,
      driverLatitude: position.latitude,
      driverLongitude: position.longitude,
      otp: otp,
      qrData: qrCode,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validation'),
        content: Text(
          success
              ? 'Trajet démarré avec succès.'
              : bookingProvider.errorMessage ?? 'La validation a échoué.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Valider le passager')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.noDuplicates,
                facing: CameraFacing.back,
              ),
              onDetect: _onDetect,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                const Text('Ou saisir un code OTP manuellement', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'OTP',
                    hintText: '123456',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitTripStart(otp: _otpController.text.trim()),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Valider le trajet'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
