import 'package:flutter/material.dart';
import 'package:deportivov1/constants/app_theme.dart';

/// Widget reutilizable para listas con paginación automática
class PaginatedListView<T> extends StatefulWidget {
  /// Función que carga los datos de forma paginada
  final Future<List<T>> Function(int page, int limit) loadData;
  
  /// Constructor del widget para cada elemento
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Widget que se muestra cuando la lista está vacía
  final Widget? emptyWidget;
  
  /// Widget que se muestra mientras carga la primera página
  final Widget? loadingWidget;
  
  /// Widget que se muestra cuando hay un error
  final Widget Function(String error, VoidCallback retry)? errorWidget;
  
  /// Número de elementos por página
  final int itemsPerPage;
  
  /// Separador entre elementos
  final Widget? separator;
  
  /// Padding de la lista
  final EdgeInsetsGeometry? padding;
  
  /// Scroll controller personalizado
  final ScrollController? scrollController;
  
  /// Callback cuando se actualiza la lista
  final VoidCallback? onRefresh;
  
  /// Habilitar pull-to-refresh
  final bool enableRefresh;
  
  /// Texto del indicador de carga
  final String loadingText;
  
  /// Clave única para el caché
  final String? cacheKey;

  const PaginatedListView({
    super.key,
    required this.loadData,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.itemsPerPage = 20,
    this.separator,
    this.padding,
    this.scrollController,
    this.onRefresh,
    this.enableRefresh = true,
    this.loadingText = 'Cargando...',
    this.cacheKey,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  late ScrollController _scrollController;
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _hasMoreData = true;
  String _errorMessage = '';
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Detecta cuando el usuario llega al final de la lista
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  /// Carga los datos iniciales
  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final newItems = await widget.loadData(0, widget.itemsPerPage);
      
      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(newItems);
          _currentPage = 0;
          _hasMoreData = newItems.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Carga más datos para la paginación
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _hasError) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newItems = await widget.loadData(nextPage, widget.itemsPerPage);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage = nextPage;
          _hasMoreData = newItems.length >= widget.itemsPerPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        
        // Mostrar error sin bloquear la UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar más datos: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// Refresca toda la lista
  Future<void> _refresh() async {
    await _loadInitialData();
    widget.onRefresh?.call();
  }

  /// Reintenta cargar después de un error
  void _retry() {
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar error si hay uno
    if (_hasError && _items.isEmpty) {
      return widget.errorWidget?.call(_errorMessage, _retry) ?? 
             _buildDefaultErrorWidget();
    }

    // Mostrar loading inicial
    if (_isLoading && _items.isEmpty) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    // Mostrar widget vacío si no hay elementos
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }

    // Construir la lista
    Widget listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: _items.length + (_hasMoreData ? 1 : 0),
      separatorBuilder: (context, index) {
        if (index >= _items.length) return const SizedBox.shrink();
        return widget.separator ?? const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        // Mostrar indicador de carga al final
        if (index >= _items.length) {
          return _buildLoadingMoreWidget();
        }
        
        return widget.itemBuilder(context, _items[index], index);
      },
    );

    // Envolver con RefreshIndicator si está habilitado
    if (widget.enableRefresh) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: listView,
      );
    }

    return listView;
  }

  /// Widget de carga por defecto
  Widget _buildDefaultLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            widget.loadingText,
            style: TextStyle(
              color: AppTheme.grayColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de error por defecto
  Widget _buildDefaultErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.grayColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget vacío por defecto
  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.grayColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay elementos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron elementos para mostrar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.grayColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de carga de más elementos
  Widget _buildLoadingMoreWidget() {
    if (!_isLoadingMore) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Cargando más...',
            style: TextStyle(
              color: AppTheme.grayColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extensión para facilitar el uso con diferentes tipos de datos
extension PaginatedListViewExtensions on PaginatedListView {
  /// Crea una lista paginada para un tipo específico con configuración común
  static PaginatedListView<T> create<T>({
    required Future<List<T>> Function(int page, int limit) loadData,
    required Widget Function(BuildContext context, T item, int index) itemBuilder,
    String emptyMessage = 'No hay elementos disponibles',
    String loadingMessage = 'Cargando...',
    int itemsPerPage = 20,
    EdgeInsetsGeometry? padding,
    bool enableRefresh = true,
  }) {
    return PaginatedListView<T>(
      loadData: loadData,
      itemBuilder: itemBuilder,
      itemsPerPage: itemsPerPage,
      padding: padding,
      enableRefresh: enableRefresh,
      loadingText: loadingMessage,
      emptyWidget: Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
} 