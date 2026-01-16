import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/asset.dart';
import '../../../models/price.dart';
import '../../../services/prices_service.dart';

class TickerSearchField extends StatefulWidget {
  final TextEditingController controller;
  final AssetType assetType;
  final Function(String ticker, String name) onTickerSelected;

  const TickerSearchField({
    super.key,
    required this.controller,
    required this.assetType,
    required this.onTickerSelected,
  });

  @override
  State<TickerSearchField> createState() => _TickerSearchFieldState();
}

class _TickerSearchFieldState extends State<TickerSearchField> {
  final _pricesService = PricesService();
  List<TickerSearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounce;
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(widget.controller.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _pricesService.searchTickers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
        if (results.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    dense: true,
                    title: Text(result.symbol),
                    subtitle: Text(
                      result.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      result.type,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      widget.onTickerSelected(result.symbol, result.name);
                      _removeOverlay();
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    String hint;
    switch (widget.assetType) {
      case AssetType.stock:
      case AssetType.etf:
        hint = 'e.g., AAPL, MSFT, SPY';
        break;
      case AssetType.crypto:
        hint = 'e.g., BTC, ETH, SOL';
        break;
      case AssetType.commodity:
        hint = 'e.g., XAU (Gold), XAG (Silver)';
        break;
      default:
        hint = 'Enter ticker symbol';
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: 'Ticker Symbol',
          hintText: hint,
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a ticker symbol';
          }
          return null;
        },
      ),
    );
  }
}
