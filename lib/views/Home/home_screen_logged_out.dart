import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/book_model.dart';
import '../../services/google_books_service.dart';
import '../Notifications/notifications_screen.dart';
import '../Messages/messages_screen.dart';
import '../Books/book_details_screen.dart';
import '../../styles/colors.dart';
import '../Layout/layout.dart'; // Importamos Layout

class HomeScreenLoggedOut extends StatefulWidget { 
  const HomeScreenLoggedOut({super.key});

  @override
  _HomeScreenLoggedOutState createState() => _HomeScreenLoggedOutState();
}

class _HomeScreenLoggedOutState extends State<HomeScreenLoggedOut> {
  final GoogleBooksService booksService = GoogleBooksService();
  List<Book> featuredBooks = [];
  List<Book> recommendedBooks = [];
  List<Book> popularBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final featured = await booksService.fetchBooks('flutter');
      final recommended = await booksService.fetchBooks('dart programming');
      final popular = await booksService.fetchBooks('technology');

      if (!mounted) return;

      setState(() {
        featuredBooks = featured;
        recommendedBooks = recommended;
        popularBooks = popular;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      body: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
       appBar: AppBar(
  elevation: 0,
  backgroundColor: AppColors.primary,
  title: Text(
    "BookSwap",
    style: GoogleFonts.poppins(
      color: AppColors.tittle,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.message, color: AppColors.textPrimary),
      onPressed: () {
        // Mostrar cuadro de diálogo en lugar de navegar
        _showLoginPrompt(context);
      },
    ),
    IconButton(
      icon: Icon(Icons.notifications, color: AppColors.textPrimary),
      onPressed: () {
        // Mostrar cuadro de diálogo en lugar de navegar
        _showLoginPrompt(context);
      },
    ),
  ],
),

        body: Container(
          color: AppColors.scaffoldBackground,
          child: isLoading
              ? _buildSkeletonLoader()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: fetchBooks,
                  child: ListView(
  padding: const EdgeInsets.all(16.0),
  children: [
    _buildSectionTitle("Libros Destacados"),
    const SizedBox(height: 10),
    _buildCarousel(featuredBooks, "featured"),
    const SizedBox(height: 20),
    _buildSectionTitle("Recomendados para Ti"),
    const SizedBox(height: 10),
    _buildCarousel(recommendedBooks, "recommended"),
    const SizedBox(height: 20),
    _buildSectionTitle("Libros Populares"),
    const SizedBox(height: 10),
    _buildCarousel(popularBooks, "popular"),
  ],
),

                ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () {
            _showLoginPrompt(context);
          },
          child: Icon(Icons.add, color: AppColors.textPrimary),
        ),
      ),
      currentIndex: 0, // Se asegura de mostrar la pestaña de Home
    );
  }

  void _showLoginPrompt(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: AppColors.dialogBackground,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Inicia Sesión",
                style: TextStyle(
                  color: AppColors.dialogTitleText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Debes iniciar sesión para acceder a esta funcionalidad.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.dialogBodyText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancelar",
                      style: TextStyle(
                        color: AppColors.dialogSecondaryButtonText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dialogPrimaryButton,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        color: AppColors.dialogPrimaryButtonText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCarousel(List<Book> books, String sectionName) {
  return CarouselSlider(
    options: CarouselOptions(
      height: 280,
      enlargeCenterPage: true,
      viewportFraction: 0.6,
      autoPlay: true,
      autoPlayInterval: const Duration(seconds: 5),
      autoPlayAnimationDuration: const Duration(milliseconds: 800),
      autoPlayCurve: Curves.fastOutSlowIn,
    ),
    items: books.asMap().entries.map((entry) {
      final index = entry.key;
      final book = entry.value;

      // Genera un tag único usando el nombre de la sección, el título del libro y el índice
      final heroTag = '$sectionName-${book.id ?? book.title}-$index';

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(
                book: book,
                heroTag: heroTag, // Pasa el tag único a la pantalla de detalles
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: heroTag, // Usa el tag único aquí
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(book.thumbnail),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Cambiado a negro explícitamente
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}



  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('Libros Destacados'),
        const SizedBox(height: 10),
        _buildSkeletonCarousel(),
        const SizedBox(height: 20),
        _buildSectionTitle('Recomendados para Ti'),
        const SizedBox(height: 10),
        _buildSkeletonCarousel(),
        const SizedBox(height: 20),
        _buildSectionTitle('Libros Populares'),
        const SizedBox(height: 10),
        _buildSkeletonCarousel(),
      ],
    );
  }

  Widget _buildSkeletonCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 280,
        enlargeCenterPage: true,
        viewportFraction: 0.6,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
      items: List.generate(5, (index) {
        return Shimmer.fromColors(
          baseColor: AppColors.shadow,
          highlightColor: AppColors.cardBackground,
          period: const Duration(seconds: 1),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.cardBackground,
            ),
          ),
        );
      }),
    );
  }
}
