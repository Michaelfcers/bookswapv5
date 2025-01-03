import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Books/add_book_manual_screen.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';
import '../../styles/colors.dart';

class AddBookDialog extends StatefulWidget {
  const AddBookDialog({super.key});

  @override
  _AddBookDialogState createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();

  String? _thumbnailUrl;
  bool _isLoading = false;
  final List<Book> _searchResults = [];
  final List<File> _uploadedPhotos = [];

  Future<void> _fetchBookDetails(Book book) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _genreController.text = book.genre ?? '';
      _descriptionController.text = book.description ?? '';
      _thumbnailUrl = book.thumbnail;
      _isLoading = false;
    });
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final books = await _googleBooksService.fetchBooks(query);
      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _searchResults.addAll(books);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar libros: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _uploadedPhotos.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _navigateToManualAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBookManualScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Agregar Libro",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildThumbnail(),
            const SizedBox(height: 24),
            _buildTitleAutocomplete(),
            const SizedBox(height: 10),
            _buildReadOnlyField(_authorController, 'Autor'),
            const SizedBox(height: 10),
            _buildReadOnlyField(_genreController, 'Género'),
            const SizedBox(height: 10),
            _buildTextField(_descriptionController, 'Descripción / Sinopsis'),
            const SizedBox(height: 10),
            _buildTextField(_conditionController, 'Condición'),
            const SizedBox(height: 10),
            _buildPhotoPicker(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 24),
            Divider(color: AppColors.iconSelected.withOpacity(0.5)),
            const SizedBox(height: 16),
            _buildManualAddOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.shadow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_thumbnailUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Icon(
                Icons.book,
                size: 50,
                color: AppColors.textPrimary.withOpacity(0.7),
              ),
            ),
    );
  }

  Widget _buildManualAddOption() {
    return Column(
      children: [
        Text(
          "¿No encuentras tu libro?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _navigateToManualAdd,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Agregar Manualmente"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.iconSelected,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPicker() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.upload_file),
          label: const Text("Subir Imágenes"),
        ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _uploadedPhotos
              .map((photo) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      photo,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.iconSelected,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _isLoading ? null : () {}, // Agregar la lógica de envío
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              "Agregar Libro",
              style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
            ),
    );
  }

  Widget _buildTitleAutocomplete() {
    return Autocomplete<Book>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Book>.empty();
        }
        await _searchBooks(textEditingValue.text);
        return _searchResults;
      },
      displayStringForOption: (Book book) => book.title,
      onSelected: (Book selectedBook) {
        _fetchBookDetails(selectedBook);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _titleController.text = controller.text;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (value) {
            _searchBooks(value);
          },
          decoration: InputDecoration(
            labelText: 'Título',
            labelStyle: TextStyle(color: AppColors.iconSelected),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.iconSelected),
            ),
          ),
          style: const TextStyle(color: Colors.black),
        );
      },
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.iconSelected),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.iconSelected),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.iconSelected),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.iconSelected),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}
