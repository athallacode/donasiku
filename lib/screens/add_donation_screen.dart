import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/donation_model.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../theme.dart';

class AddDonationScreen extends StatefulWidget {
  const AddDonationScreen({super.key});

  @override
  State<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends State<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedCategory;
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  final List<String> _categories = ['Pakaian', 'Makanan', 'Buku', 'Elektronik', 'Lainnya'];
  final DonationService _donationService = DonationService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Pilih Sumber Gambar', style: AppTheme.headingSmall),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Galeri',
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          _pickImage(ImageSource.gallery);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Kamera',
                        color: AppTheme.emeraldGreen,
                        onTap: () {
                          _pickImage(ImageSource.camera);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTheme.labelBold.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan pilih foto produk'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Pengguna tidak ditemukan');

      final userName = await _authService.getUserName(user.uid);

      // 1. Upload Image
      final imageUrl = await _donationService.uploadImageFromBytes(_imageBytes!);

      // 2. Create Donation Object
      final donation = Donation(
        id: const Uuid().v4(),
        donorId: user.uid,
        donorName: userName,
        productName: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        imageUrl: imageUrl,
        location: _locationController.text,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore
      await _donationService.createDonation(donation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Donasi berhasil dikirim! 🎉'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Tambah Donasi', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.borderGrey, height: 1),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryBlue),
                  const SizedBox(height: 16),
                  Text('Mengunggah donasi...', style: AppTheme.bodyMedium),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldGreen.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.emeraldGreen.withAlpha(40)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_box_rounded,
                              color: AppTheme.emeraldGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detail Barang Donasi',
                                  style: AppTheme.headingSmall.copyWith(color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pastikan barang masih layak pakai',
                                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Image Picker ──
                    GestureDetector(
                      onTap: () => _showImagePicker(context),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderGrey,
                            width: 1.5,
                          ),
                        ),
                        child: _imageFile != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.textDark.withAlpha(200),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withAlpha(20),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 40,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Klik untuk unggah foto',
                                    style: AppTheme.labelBold.copyWith(
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'JPG, PNG (maks. 5 MB)',
                                    style: AppTheme.bodySmall,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Form Fields ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.softCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nama Produk', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: AppTheme.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Kaos Polos L',
                              prefixIcon: Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryBlue, size: 22),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Nama Produk wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 20),
                          Text('Kategori', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryBlue, size: 22),
                            ),
                            hint: Text('Pilih kategori', style: AppTheme.bodyMedium),
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                            validator: (val) =>
                                val == null ? 'Pilih kategori' : null,
                          ),
                          const SizedBox(height: 20),
                          Text('Lokasi Penjemputan', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _locationController,
                            style: AppTheme.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Kec. Sukolilo, Surabaya',
                              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue, size: 22),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Lokasi wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 20),
                          Text('Deskripsi Kondisi', style: AppTheme.labelBold),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            style: AppTheme.bodyLarge,
                            decoration: const InputDecoration(
                              hintText: 'Masih sangat bagus, jarang dipakai, bersih...',
                              prefixIcon: Padding( // Align prefix to top
                                padding: EdgeInsets.only(bottom: 56), 
                                child: Icon(Icons.notes_rounded, color: AppTheme.primaryBlue, size: 22),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Deskripsi wajib diisi'
                                    : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Submit Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submitDonation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Kirim Donasi', style: AppTheme.buttonText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
