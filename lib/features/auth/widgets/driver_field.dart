import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';

class DriverField extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onFieldsChanged;
  final ValueChanged<Map<String, dynamic>> onFilesChanged;

  const DriverField({
    super.key,
    required this.onFieldsChanged,
    required this.onFilesChanged,
  });

  @override
  State<DriverField> createState() => _DriverFieldState();
}

class _DriverFieldState extends State<DriverField> {
  final _carModelController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _carColorController = TextEditingController();

  File? _licenceFile;
  File? _carLicenceFile;
  File? _personalIdFile;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _carModelController.dispose();
    _carPlateController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String key) async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (xFile != null) {
      final file = File(xFile.path);
      setState(() {
        switch (key) {
          case 'licence':
            _licenceFile = file;
            break;
          case 'car_licence':
            _carLicenceFile = file;
            break;
          case 'personal_id':
            _personalIdFile = file;
            break;
        }
      });
      widget.onFilesChanged({key: file});
    }
  }

  void _emitFields() {
    widget.onFieldsChanged({
      'car_model': _carModelController.text,
      'car_plate': _carPlateController.text,
      'car_color': _carColorController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'بيانات السائق',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.meterPrimary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carModelController,
          decoration: const InputDecoration(
            labelText: 'موديل السيارة',
            prefixIcon: Icon(Icons.directions_car_outlined),
          ),
          validator: Validators.model,
          onChanged: (_) => _emitFields(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carPlateController,
          decoration: const InputDecoration(
            labelText: 'رقم اللوحة',
            prefixIcon: Icon(Icons.dialpad_outlined),
          ),
          validator: Validators.plateNumber,
          onChanged: (_) => _emitFields(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _carColorController,
          decoration: const InputDecoration(
            labelText: 'لون السيارة',
            prefixIcon: Icon(Icons.palette_outlined),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'يرجى إدخال اللون';
            return null;
          },
          onChanged: (_) => _emitFields(),
        ),
        const SizedBox(height: 20),
        const Text(
          'المستندات المطلوبة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.meterMuted,
          ),
        ),
        const SizedBox(height: 8),
        _DocTile(
          label: 'رخصة القيادة',
          file: _licenceFile,
          onTap: () => _pickDocument('licence'),
          onClear: () => setState(() {
            _licenceFile = null;
            widget.onFilesChanged({'licence': null});
          }),
        ),
        const SizedBox(height: 8),
        _DocTile(
          label: 'رخصة السيارة',
          file: _carLicenceFile,
          onTap: () => _pickDocument('car_licence'),
          onClear: () => setState(() {
            _carLicenceFile = null;
            widget.onFilesChanged({'car_licence': null});
          }),
        ),
        const SizedBox(height: 8),
        _DocTile(
          label: 'بطاقة الرقم القومي',
          file: _personalIdFile,
          onTap: () => _pickDocument('personal_id'),
          onClear: () => setState(() {
            _personalIdFile = null;
            widget.onFilesChanged({'personal_id': null});
          }),
        ),
      ],
    );
  }
}

class _DocTile extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DocTile({
    required this.label,
    required this.file,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.meterCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null ? AppTheme.success : AppTheme.meterCard,
        ),
      ),
      child: Row(
        children: [
          Icon(
            file != null ? Icons.check_circle : Icons.upload_file,
            color: file != null ? AppTheme.success : AppTheme.meterMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              file?.path.split('/').last ?? label,
              style: TextStyle(
                fontSize: 13,
                color: file != null ? Colors.white : AppTheme.meterMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (file != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClear,
            )
          else
            TextButton(
              onPressed: onTap,
              child: const Text('اختيار',
                  style: TextStyle(color: AppTheme.meterPrimary)),
            ),
        ],
      ),
    );
  }
}
