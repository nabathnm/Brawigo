import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:brawigo/core/utils/constants/brawigo_colors.dart';
import 'package:brawigo/core/utils/constants/brawigo_sizes.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedFaculty;
  String? _selectedGender;

  final List<String> _faculties = [
    'FILKOM',
    'FEB',
    'FH',
    'FIA',
    'FP',
    'FAPET',
    'FT',
    'FK',
    'FPIK',
    'FMIPA',
    'FTP',
    'FISIP',
    'FIB',
    'FKG',
    'FKH',
    'VOKASI',
  ];

  final List<String> _genders = ['Laki-laki', 'Perempuan'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: BrawigoColors.blue800,
        fontSize: BrawigoSizes.fontSizeSm,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: BrawigoSizes.md,
        vertical: BrawigoSizes.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
        borderSide: const BorderSide(color: BrawigoColors.blue800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
        borderSide: const BorderSide(color: BrawigoColors.blue800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
        borderSide: const BorderSide(color: BrawigoColors.blue800, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
        borderSide: const BorderSide(color: BrawigoColors.redNormal),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrawigoSizes.inputFieldRadius),
        borderSide: const BorderSide(
          color: BrawigoColors.redNormal,
          width: 1.5,
        ),
      ),
    );
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
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 154, 154, 154),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
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
            stops: [0.0, 0.45],
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
              context.push('/set-photo');
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 120),
                            const Text(
                              'Lengkapi Profil Kamu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: BrawigoColors.blue900,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.sm),

                            const Text(
                              'Lengkapi data dirimu untuk pengalaman jual-beli yang lebih aman.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: BrawigoColors.blue800,
                                fontSize: BrawigoSizes.fontSizeMd,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),

                            const Spacer(),

                            const Text(
                              'Nama lengkap',
                              style: TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                fontWeight: FontWeight.bold,
                                color: BrawigoColors.blue800,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.xs),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                color: BrawigoColors.blue950,
                              ),
                              decoration: _inputDecoration('Contoh: John Doe'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Nama tidak boleh kosong'
                                  : null,
                            ),
                            const SizedBox(
                              height: BrawigoSizes.spaceBtwInputFields,
                            ),

                            const Text(
                              'Fakultas',
                              style: TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                fontWeight: FontWeight.bold,
                                color: BrawigoColors.blue800,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.xs),
                            DropdownButtonFormField<String>(
                              value: _selectedFaculty,
                              style: const TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                color: BrawigoColors.blue950,
                              ),
                              dropdownColor: Colors.white,
                              decoration: _inputDecoration('Pilih Fakultas'),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: BrawigoColors.blue800,
                              ),
                              items: _faculties.map((String faculty) {
                                return DropdownMenuItem<String>(
                                  value: faculty,
                                  child: Text(faculty),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFaculty = newValue;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Pilih fakultas terlebih dahulu'
                                  : null,
                            ),
                            const SizedBox(
                              height: BrawigoSizes.spaceBtwInputFields,
                            ),

                            const Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                fontWeight: FontWeight.bold,
                                color: BrawigoColors.blue800,
                              ),
                            ),
                            const SizedBox(height: BrawigoSizes.xs),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              style: const TextStyle(
                                fontSize: BrawigoSizes.fontSizeSm,
                                color: BrawigoColors.blue950,
                              ),
                              dropdownColor: Colors.white,
                              decoration: _inputDecoration('Pilih Gender'),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: BrawigoColors.blue800,
                              ),
                              items: _genders.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Pilih gender terlebih dahulu'
                                  : null,
                            ),

                            const Spacer(),

                            SizedBox(
                              height: 48,
                              width: double.infinity,
                              child: Container(
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
                                          if (_formKey.currentState!
                                              .validate()) {
                                            String dbGender =
                                                (_selectedGender == 'Laki-laki')
                                                ? 'male'
                                                : 'female';

                                            context.read<AuthBloc>().add(
                                              ProfileCompletionRequested(
                                                fullName: _nameController.text
                                                    .trim(),
                                                faculty: _selectedFaculty!,
                                                gender: dbGender,
                                              ),
                                            );
                                          }
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
                                          'Lanjutkan',
                                          style: TextStyle(
                                            fontSize: BrawigoSizes.fontSizeSm,
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
