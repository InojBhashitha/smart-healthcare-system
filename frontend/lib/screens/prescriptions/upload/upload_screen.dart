import 'package:flutter/material.dart';

import 'widgets/source_picker_sheet.dart';
import 'widgets/upload_drop_zone.dart';

import 'package:provider/provider.dart';

import '../../../providers/prescription_provider.dart';
import 'widgets/image_preview.dart';
import '../../../core/routes/app_routes.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload Prescription",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFF070B19).withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.2,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Consumer<PrescriptionProvider>(
  builder: (context, provider, child) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: provider.selectedImage == null
          ? UploadDropZone(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SourcePickerSheet(
                    onCamera: () async {
                      Navigator.pop(context);

                      await provider.pickFromCamera();
                    },
                    onGallery: () async {
                      Navigator.pop(context);

                      await provider.pickFromGallery();
                    },
                  ),
                );
              },
            )
          : ImagePreview(
  image: provider.selectedImage!,
  isUploading: provider.isUploading,

  onRemove: provider.removeImage,

  onUpload: () async {
  await provider.uploadPrescription();

  if (!context.mounted) return;

  if (provider.errorMessage != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.errorMessage!),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final response = provider.uploadResponse;

  if (response != null && response.prescriptionId != null) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.verification,
    );
  }
},
),
    );
  },
),
    );
  }
}