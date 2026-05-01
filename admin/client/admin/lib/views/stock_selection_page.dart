import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stock_viewmodel.dart';

class StockSelectionPage extends StatefulWidget {
  const StockSelectionPage({super.key});

  @override
  State<StockSelectionPage> createState() => _StockSelectionPageState();
}

class _StockSelectionPageState extends State<StockSelectionPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StockViewModel>(context, listen: false);
      viewModel.clearSelections();
      viewModel.setSearchQuery("");
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select 5 Stocks',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<StockViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                onPressed: viewModel.isLoading ? null : () => viewModel.refreshFnoStocks(),
                icon: viewModel.isLoading 
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Refresh F&O List',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<StockViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => viewModel.setSearchQuery(value),
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search stocks...',
                      hintStyle: GoogleFonts.outfit(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: viewModel.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                viewModel.setSearchQuery("");
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              // Selection Tray & Info
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Selection (${viewModel.selectedStocks.length}/5)',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (viewModel.selectedStocks.isNotEmpty)
                          TextButton(
                            onPressed: () => viewModel.clearSelections(),
                            child: Text('Clear All', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final hasSelection = index < viewModel.selectedStocks.length;
                          return Container(
                            width: (MediaQuery.of(context).size.width - 80) / 5,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: hasSelection ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: hasSelection ? Colors.white24 : Colors.white10),
                            ),
                            child: Center(
                              child: hasSelection
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                          const SizedBox(height: 2),
                                          Text(
                                            viewModel.selectedStocks[index].split(' ').first,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.currentLiveStocks.isNotEmpty) ...[
                      Text(
                        'Currently Live:',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: viewModel.currentLiveStocks.map((stock) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stock.split(' ').first, // Just the first part/ticker
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11),
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (viewModel.selectedStocks.length == 5)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading 
                            ? null 
                            : () async {
                                final success = await viewModel.saveRecommendations();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Successfully updated live stocks!' : 'Failed to save'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                  if (success) Navigator.pop(context);
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                          ),
                          child: viewModel.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Publish New Recommendations', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: viewModel.filteredStocks.isEmpty && !viewModel.isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              viewModel.searchQuery.isEmpty
                                  ? 'No stocks found in database'
                                  : 'No stocks match your search',
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            if (viewModel.searchQuery.isEmpty)
                              TextButton.icon(
                                onPressed: () => viewModel.refreshFnoStocks(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Fetch from Upstox'),
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: viewModel.filteredStocks.length,
                        itemBuilder: (context, index) {
                          final stock = viewModel.filteredStocks[index];
                          final isSelected = viewModel.selectedStocks.contains(stock);
                          
                          return GestureDetector(
                            onTap: () => viewModel.toggleStockSelection(stock),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF0F172A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      (index + 1).toString(),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      stock,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
