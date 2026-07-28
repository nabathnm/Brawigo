import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class SetPhotoPage extends StatefulWidget {
  const SetPhotoPage({super.key});

  @override
  State<SetPhotoPage> createState() => _SetPhotoPageState();
}

class _SetPhotoPageState extends State<SetPhotoPage> {
  Uint8List? _imageBytes;
  String _imageExtension = 'jpg';
  final ImagePicker _picker = ImagePicker();

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(BrawigoSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    BrawigoSizes.buttonRadius,
                  ),
                  gradient: const LinearGradient(
                    colors: [BrawigoColors.blue400, BrawigoColors.blue600],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickAndCropImage(ImageSource.gallery);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        BrawigoSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Pilih dari Galeri',
                    style: TextStyle(
                      fontSize: BrawigoSizes.fontSizeSm,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.camera);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BrawigoColors.blue800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BrawigoSizes.buttonRadius,
                    ),
                  ),
                ),
                child: const Text(
                  'Buka Kamera',
                  style: TextStyle(
                    fontSize: BrawigoSizes.fontSizeSm,
                    color: BrawigoColors.blue800,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();

          setState(() {
            _imageBytes = bytes;
            final parts = pickedFile.path.split('.');
            _imageExtension = parts.length > 1 ? parts.last : 'jpg';
          });
          return;
        }

        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Sesuaikan Foto',
              toolbarColor: BrawigoColors.blue800,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: true,
            ),
            IOSUiSettings(
              title: 'Sesuaikan Foto',
              aspectRatioLockEnabled: true,
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();

          setState(() {
            _imageBytes = bytes;
            final parts = pickedFile.path.split('.');
            _imageExtension = parts.length > 1 ? parts.last : 'jpg';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses gambar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(255, 154, 154, 154),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: const EdgeInsets.only(right: 2),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: BrawigoColors.blue800,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BrawigoColors.blue200, Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: BrawigoColors.redNormal,
                ),
              );
            } else if (state is AuthAuthenticated) {
              context.push('/onboarding-success');
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrawigoSizes.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 120),

                          const Text(
                            'Atur Foto Profil',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: BrawigoColors.blue800,
                            ),
                          ),
                          const SizedBox(height: BrawigoSizes.sm),

                          const Text(
                            'Tambahkan foto profil agar akunmu lebih\nmudah dikenali dan terpercaya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: BrawigoColors.blue800,
                              fontSize: BrawigoSizes.fontSizeMd,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),

                          const Spacer(),

                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: BrawigoColors.blue800
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      image: _imageBytes != null
                                          ? DecorationImage(
                                              image: MemoryImage(_imageBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: _imageBytes == null
                                        ? const Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 44,
                                            color: BrawigoColors.blue800,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: BrawigoSizes.md),
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: const Text(
                                    'Ketuk untuk mengunggah',
                                    style: TextStyle(
                                      fontSize: BrawigoSizes.fontSizeSm,
                                      fontWeight: FontWeight.bold,
                                      color: BrawigoColors.blue800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: _imageBytes == null
                                ? OutlinedButton(
                                    onPressed: () =>
                                        context.push('/onboarding-success'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: BrawigoColors.blue800,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          BrawigoSizes.buttonRadius,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Lewati',
                                      style: TextStyle(
                                        fontSize: BrawigoSizes.fontSizeSm,
                                        color: BrawigoColors.blue800,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        BrawigoSizes.buttonRadius,
                                      ),
                                      gradient: LinearGradient(
                                        colors: state is AuthLoading
                                            ? [
                                                BrawigoColors.blue300,
                                                BrawigoColors.blue300,
                                              ]
                                            : [
                                                BrawigoColors.blue400,
                                                BrawigoColors.blue600,
                                              ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: state is AuthLoading
                                          ? null
                                          : () {
                                              context.read<AuthBloc>().add(
                                                ProfilePhotoUploadRequested(
                                                  imageBytes: _imageBytes!,
                                                  fileExtension:
                                                      _imageExtension,
                                                ),
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: BrawigoSizes.md,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            BrawigoSizes.buttonRadius,
                                          ),
                                        ),
                                      ),
                                      child: state is AuthLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Simpan & Lanjutkan',
                                              style: TextStyle(
                                                fontSize:
                                                    BrawigoSizes.fontSizeSm,
                                                color: Colors.white,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 64),
                        ],
                      ),
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
}
