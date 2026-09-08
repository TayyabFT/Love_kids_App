import 'package:flutter/material.dart';
import '../models/woocommerce_models.dart';
import '../services/woocommerce_service.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import 'track_order_screen.dart';
import 'product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final WooCommerceService _wooService = WooCommerceService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isSearchVisible = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<WooProduct> _products = [];
  List<WooProduct> _filteredProducts = [];
  List<WooProductCategory> _categories = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  int _currentPage = 1;
  bool _hasMoreProducts = true;
  String? _errorMessage;
  
  // WooCommerce connection info
  int _totalProducts = 0;
  int _totalPages = 0;
  bool _isWooCommerceConnected = false;

  @override
  void initState() {
    super.initState();
    // Reset any pre-selected filters
    _selectedCategory = '';
    _searchQuery = '';
    _loadData();
    _cartService.addListener(_updateCartBadge);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cartService.removeListener(_updateCartBadge);
    super.dispose();
  }

  void _updateCartBadge() {
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMoreProducts = true;
    });

    try {
      print('🔍 Testing WooCommerce connection first...');
      
      // Test WooCommerce connection and get product count
      final connectionTest = await _wooService.testWooCommerceConnection();
      
      if (connectionTest['success'] == true) {
        setState(() {
          _isWooCommerceConnected = true;
          _totalProducts = connectionTest['totalProducts'] ?? 0;
          _totalPages = connectionTest['totalPages'] ?? 0;
        });
        
        print('✅ WooCommerce connected! Total products: $_totalProducts, Total pages: $_totalPages');
      } else {
        setState(() {
          _isWooCommerceConnected = false;
          _errorMessage = 'WooCommerce connection failed: ${connectionTest['error']}';
        });
        print('❌ WooCommerce connection failed: ${connectionTest['error']}');
        return;
      }
      
      // Try to load categories first, but don't fail if they don't load
      List<WooProductCategory> categories = [];
      try {
        categories = await _wooService.getCategories();
        print('✅ Loaded ${categories.length} categories');
      } catch (e) {
        print('⚠️ Categories failed to load: $e');
        // Continue without categories - they will be extracted from products
      }
      
      // Load first page of products (10 products per page)
      print('🔄 Loading first page of products (10 products per page)...');
      final products = await _wooService.getProducts(
        page: 1,
        perPage: 10, // Load 10 products per page
        category: '', // Load all products initially
        fetchAll: false, // Don't fetch all, just first page
      );
      
      print('✅ Loaded ${products.length} products');
      
      // Check if this is mock data (mock products have IDs starting from 10001)
      final isMockData = products.isNotEmpty && products.first.id >= 10001;
      // Removed the snackbar message since API is working fine
      
      // If we don't have categories from API, extract them from products
      if (categories.isEmpty && products.isNotEmpty) {
        print('🔄 Extracting categories from products...');
        final Set<WooProductCategory> extractedCategories = {};
        for (final product in products) {
          extractedCategories.addAll(product.categories);
        }
        categories = extractedCategories.toList();
        categories.sort((a, b) => a.name.compareTo(b.name));
        print('✅ Extracted ${categories.length} categories from products');
      }
      
      // Debug: Print product names and their categories
      for (final product in products.take(3)) {
        final categoryNames = product.categories.map((cat) => cat.name).join(', ');
        print('📦 Product: ${product.name} | Categories: $categoryNames');
      }
      
      // Debug: Print all available categories
      for (final category in categories.take(5)) {
        final productCount = products.where((product) => 
          product.categories.any((cat) => cat.id == category.id)
        ).length;
        print('📂 Category: ${category.name} (ID: ${category.id}) | Products: $productCount');
      }
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _categories = categories;
        _isLoading = false;
        _hasMoreProducts = _currentPage < _totalPages; // More pages available
      });
      
      print('🎉 Data loaded successfully: ${_products.length} products, ${_categories.length} categories');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e.toString());
      });
    }
  }

  String _cleanErrorMessage(String error) {
    if (error.contains('timeout')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (error.contains('Connection closed')) {
      return 'Connection interrupted. Please try again.';
    } else if (error.contains('Failed to load products')) {
      return error.replaceAll('Exception: Failed to load products: Exception: ', '');
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      print('🔄 Loading page $nextPage of products...');
      
      final moreProducts = await _wooService.getProducts(
        page: nextPage,
        perPage: 10, // Load 10 products per page
        category: _selectedCategory.isEmpty ? '' : _selectedCategory, // Include category filter
        fetchAll: false,
      );
      
      if (moreProducts.isNotEmpty) {
        setState(() {
          _products.addAll(moreProducts);
          _currentPage = nextPage;
          _hasMoreProducts = _currentPage < _totalPages;
          _isLoadingMore = false;
        });
        _filterProducts(); // Re-filter with new products
        print('✅ Loaded ${moreProducts.length} more products. Total: ${_products.length}');
      } else {
        setState(() {
          _hasMoreProducts = false;
          _isLoadingMore = false;
        });
        print('✅ No more products available');
      }
    } catch (e) {
      print('❌ Error loading more products: $e');
      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Failed to load more products. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty || 
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.shortDescription.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.sku.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Category filter - improved logic
        final matchesCategory = _selectedCategory.isEmpty ||
            product.categories.any((cat) => cat.id.toString() == _selectedCategory);
        
        final passes = matchesSearch && matchesCategory;
        
        // Debug logging for filtering
        if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty) {
          print('🔍 Filtering ${product.name}: search=$matchesSearch, category=$matchesCategory, passes=$passes');
          if (_selectedCategory.isNotEmpty) {
            final productCategories = product.categories.map((cat) => '${cat.name}(${cat.id})').join(', ');
            print('   Product categories: $productCategories | Looking for category ID: $_selectedCategory');
          }
        }
        
        return passes;
      }).toList();
      
      print('🔍 Filtered ${_filteredProducts.length} products from ${_products.length} total');
      if (_selectedCategory.isNotEmpty) {
        final selectedCategoryName = _categories.firstWhere(
          (cat) => cat.id.toString() == _selectedCategory,
          orElse: () => WooProductCategory(id: 0, name: 'Unknown', slug: ''),
        ).name;
        print('📂 Selected category: $selectedCategoryName (ID: $_selectedCategory)');
      }
      if (_searchQuery.isNotEmpty) {
        print('🔎 Search query: "$_searchQuery"');
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _onCategoryChanged(String categoryId) async {
    setState(() {
      _selectedCategory = categoryId;
      _isLoading = true; // Show loading when changing category
    });
    
    try {
      print('🔄 Loading products for category: $categoryId');
      
      // Load products for the selected category from API
      final products = await _wooService.getProducts(
        page: 1,
        perPage: 10,
        category: categoryId.isEmpty ? '' : categoryId,
        fetchAll: false,
      );
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _currentPage = 1;
        _hasMoreProducts = products.length >= 10; // Assume more if we got 10 products
        _isLoading = false;
      });
      
      print('✅ Loaded ${products.length} products for category: $categoryId');
      
    } catch (e) {
      print('❌ Error loading category products: $e');
      setState(() {
        _isLoading = false;
      });
      // Fallback to local filtering
      _filterProducts();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
        _filterProducts();
      }
    });
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }
  
  void _navigateToTrackOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrackOrderScreen()),
    );
  }

  void _navigateToProductDetail(WooProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _addToCart(WooProduct product) {
    _cartService.addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isOfflineMode() {
    return _products.isNotEmpty && _products.first.id >= 10001;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8D0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isSearchVisible) _buildSearchBar(),

            _buildCategoryFilter(),
            Expanded(
              child: _isLoading ? _buildLoadingWidget() : 
                     _errorMessage != null ? _buildErrorWidget() :
                     _buildProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9A826), Color(0xFFFF8C00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              const Text(
                'Our Store',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (_isWooCommerceConnected)
                Text(
                  'Connected ($_totalProducts products)',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: const Icon(Icons.local_shipping_outlined, color: Colors.white),
                onPressed: _navigateToTrackOrder,
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: _navigateToCart,
                  ),
                  if (_cartService.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_cartService.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for amazing products...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.orange.shade700,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Using sample data - API temporarily unavailable',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadData,
            child: Text(
              'Retry',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        // Products count display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isWooCommerceConnected 
                  ? 'Products: ${_filteredProducts.length} of $_totalProducts'
                  : 'Products: ${_filteredProducts.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              Row(
                children: [
                  if (_selectedCategory.isNotEmpty || _searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = '';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _loadData(); // Reload all products
                      },
                      child: Text(
                        'Clear Filters',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (_isWooCommerceConnected && _filteredProducts.length != _products.length)
                    Text(
                      '(${_products.length} loaded)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Category filter chips
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('All', ''),
              ..._categories.map((category) => 
                _buildCategoryChip(category.name, category.id.toString())
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategoryChanged(value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFF9A826).withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFFF9A826) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFFF9A826) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    // Determine the appropriate loading message based on current state
    String mainMessage;
    String subMessage;
    
    if (_selectedCategory.isNotEmpty) {
      // Loading products for a specific category
      final categoryName = _categories.firstWhere(
        (cat) => cat.id.toString() == _selectedCategory,
        orElse: () => WooProductCategory(id: 0, name: 'Selected Category', slug: ''),
      ).name;
      mainMessage = 'Loading $categoryName products...';
      subMessage = 'Fetching products from your store';
    } else if (_searchQuery.isNotEmpty) {
      // Loading search results
      mainMessage = 'Searching products...';
      subMessage = 'Looking for "$_searchQuery" in your store';
    } else if (_products.isEmpty) {
      // Initial load
      mainMessage = 'Loading Products...';
      subMessage = 'Connecting to your store and loading products';
    } else {
      // General loading
      mainMessage = 'Loading Products...';
      subMessage = 'Please wait while we fetch your products';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF9A826)),
          ),
          const SizedBox(height: 16),
          Text(
            mainMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4299E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFF9A826),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Enhanced responsive grid calculations for mobile optimization
          final screenWidth = constraints.maxWidth;
          
          int crossAxisCount = 2;
          double childAspectRatio = 0.58; 
          double spacing = 8;
          double horizontalPadding = 12;
          
          // Optimized layout for different screen sizes
          if (screenWidth > 600) {
            crossAxisCount = 3;
            childAspectRatio = 0.7;
            spacing = 16;
            horizontalPadding = 20;
          } else if (screenWidth > 450) {
            crossAxisCount = 2;
            childAspectRatio = 0.65;
            spacing = 14;
            horizontalPadding = 16;
          } else if (screenWidth > 380) {
            crossAxisCount = 2;
            childAspectRatio = 0.6;
            spacing = 12;
            horizontalPadding = 14;
          } else if (screenWidth > 340) {
            crossAxisCount = 2;
            childAspectRatio = 0.58;
            spacing = 10;
            horizontalPadding = 12;
          } else {
            crossAxisCount = 2;
            childAspectRatio = 0.55;
            spacing = 8;
            horizontalPadding = 10;
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 
                    spacing, 
                    horizontalPadding, 
                    spacing
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing + 4,
                  ),
                  itemCount: _filteredProducts.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product, screenWidth);
                  },
                ),
              ),
              
              // Load More Button (only show if there are more products to load and no filters)
              if (_hasMoreProducts && _selectedCategory.isEmpty && _searchQuery.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _isLoadingMore
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF9A826)),
                        )
                      : ElevatedButton(
                          onPressed: _loadMoreProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF9A826),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Load More Products (${_products.length}/$_totalProducts)'),
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory.isNotEmpty 
              ? 'No products found' 
              : 'No products available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory.isNotEmpty
              ? 'Try adjusting your filters or search terms'
              : 'Check back later for new items',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty) ...[
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = '';
                  _searchController.clear();
                });
                _filterProducts();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A826),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Clear Filters'),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4299E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(WooProduct product, double screenWidth) {
    final imageUrl = product.images.isNotEmpty ? product.images.first.src : '';
    final isInCart = _cartService.isInCart(product.id);
    
    // Enhanced responsive sizing based on screen width
    final cardPadding = screenWidth < 340 ? 8.0 : screenWidth < 380 ? 10.0 : 12.0;
    final titleFontSize = screenWidth < 340 ? 12.0 : screenWidth < 380 ? 13.0 : 14.0;
    final priceFontSize = screenWidth < 340 ? 13.0 : screenWidth < 380 ? 14.0 : 15.0;
    final buttonHeight = screenWidth < 340 ? 32.0 : screenWidth < 380 ? 36.0 : 40.0;
    final buttonFontSize = screenWidth < 340 ? 10.0 : screenWidth < 380 ? 11.0 : 12.0;
    final saleFontSize = screenWidth < 340 ? 8.0 : screenWidth < 380 ? 9.0 : 10.0;
    
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - 50% of card height (balanced with content)
              Expanded(
                flex: 50, // 50% for image
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: Colors.grey.shade50,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF9A826)),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholderImage(),
                      ),
                      // Sale badge
                      if (product.onSale)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              'SALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: saleFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Product Info - Content section with proper spacing
              Expanded(
                flex: 50, // More space for content to prevent overflow
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product name - exactly 2 lines (fixed height)
                      SizedBox(
                        height: titleFontSize * 2.4, // Fixed height for 2 lines
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Price section with 20px padding above and below
                      Column(
                        children: [
                          const SizedBox(height: 10), // 20px above price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (product.onSale) ...[
                                Text(
                                  '\$${product.regularPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: priceFontSize - 2,
                                    color: Colors.grey.shade600,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF9A826),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10), // 20px below price
                        ],
                      ),
                      
                      // Add to cart button - fixed at bottom
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: product.inStock ? () => _addToCart(product) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInCart 
                              ? Colors.green.shade600
                              : (product.inStock ? Colors.red.shade500 : Colors.grey.shade400),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black26,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: Text(
                            isInCart 
                              ? 'Added ✓' 
                              : (product.inStock ? 'Add to Cart' : 'Out of Stock'),
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}