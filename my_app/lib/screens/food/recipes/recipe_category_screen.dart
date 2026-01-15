import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/textured_background.dart';
import '../../../widgets/metal_search_bar.dart';
import '../../../widgets/metal_back_button.dart';
import '../../../widgets/metal_button.dart';
import '../../../design/ninja_spacing.dart';
import '../../../design/ninja_typography.dart';
import '../../../design/ninja_colors.dart';
import '../../../models/recipe_model.dart';
import '../../../services/recipe_service.dart';
import 'recipe_card_widget.dart';
import 'recipe_detail_screen.dart';
import 'recipe_create_screen.dart';

class RecipeCategoryScreen extends StatefulWidget {
  final String category;
  final String categoryName;

  const RecipeCategoryScreen({
    super.key,
    required this.category,
    required this.categoryName,
  });

  @override
  State<RecipeCategoryScreen> createState() => _RecipeCategoryScreenState();
}

class _RecipeCategoryScreenState extends State<RecipeCategoryScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchTimer;
  final ScrollController _scrollController = ScrollController();
  
  // Пагинация
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;
    
    if (currentScroll >= threshold &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreRecipes();
    }
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 1), () {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 1;
        _hasMore = true;
        _recipes.clear();
      });
      _loadRecipes();
    });
  }

  Future<void> _loadRecipes() async {
    if (_isLoading && _recipes.isNotEmpty) return; // Уже загружается

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final response = await RecipeService.getRecipes(
        category: widget.category,
        name: _searchQuery.isNotEmpty ? _searchQuery : null,
        actual: true,
        page: 1,
        size: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _recipes = response.items;
          // Используем totalPages для определения, есть ли еще страницы
          _hasMore = response.page < response.totalPages;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await RecipeService.getRecipes(
        category: widget.category,
        name: _searchQuery.isNotEmpty ? _searchQuery : null,
        actual: true,
        page: nextPage,
        size: _pageSize,
      );

      if (mounted) {
        setState(() {
          _recipes.addAll(response.items);
          _currentPage = nextPage;
          // Используем totalPages для определения, есть ли еще страницы
          _hasMore = response.page < response.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openRecipeDetail(Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    ).then((_) {
      _loadRecipes();
    });
  }

  void _openCreateRecipe({required bool isAdmin}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeCreateScreen(
          category: widget.category,
          isAdmin: isAdmin,
        ),
      ),
    ).then((_) {
      _loadRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    final isAdmin = userProfile?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок и кнопка назад
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: NinjaSpacing.lg,
                  vertical: NinjaSpacing.md,
                ),
                child: Row(
                  children: [
                    const MetalBackButton(),
                    const SizedBox(width: NinjaSpacing.md),
                    Expanded(
                      child: Text(
                        widget.categoryName,
                        style: NinjaText.title,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _openCreateRecipe(isAdmin: false),
                      tooltip: 'Добавить рецепт',
                      color: NinjaColors.textPrimary,
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _openCreateRecipe(isAdmin: true),
                        tooltip: 'Добавить рецепт (админ)',
                        color: NinjaColors.textPrimary,
                      ),
                  ],
                ),
              ),
              // Поиск
              Padding(
                padding: const EdgeInsets.all(NinjaSpacing.lg),
                child: MetalSearchBar(
                  controller: _searchController,
                  hint: 'Поиск рецептов...',
                  onChanged: (value) {
                    // Обработка через _onSearchChanged
                  },
                ),
              ),
              // Список рецептов
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            NinjaColors.textPrimary,
                          ),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ошибка загрузки рецептов',
                                  style: NinjaText.title,
                                ),
                                const SizedBox(height: NinjaSpacing.md),
                                Text(
                                  _error!,
                                  style: NinjaText.caption,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: NinjaSpacing.lg),
                                MetalButton(
                                  label: 'Повторить',
                                  onPressed: _loadRecipes,
                                  height: 48,
                                ),
                              ],
                            ),
                          )
                        : _recipes.isEmpty
                            ? Center(
                                child: Text(
                                  'Нет рецептов в этой категории',
                                  style: NinjaText.body,
                                ),
                              )
                            : SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: NinjaSpacing.lg,
                            ),
                            child: Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cardWidth = (constraints.maxWidth - NinjaSpacing.md) / 2;
                                    return Wrap(
                                      spacing: NinjaSpacing.md,
                                      runSpacing: NinjaSpacing.md,
                                      children: _recipes.map((recipe) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: RecipeCardWidget(
                                        recipe: recipe,
                                        onTap: () => _openRecipeDetail(recipe),
                                        onDeleted: _loadRecipes,
                                      ),
                                    );
                                      }).toList(),
                                    );
                                  },
                                ),
                                if (_isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(NinjaSpacing.lg),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        NinjaColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                if (!_hasMore && _recipes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(NinjaSpacing.lg),
                                    child: Text(
                                      'Все рецепты загружены',
                                      style: NinjaText.caption.copyWith(
                                        color: NinjaColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

