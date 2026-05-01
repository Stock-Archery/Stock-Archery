import 'package:client/viewmodels/stocks_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StocksView extends ConsumerWidget {
  const StocksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final String formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Stock Recommendations",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1)),
            onPressed: () => ref.refresh(recommendationsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: recommendationsAsync.when(
        data: (stocks) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(recommendationsProvider.future),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 📅 Date & Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, 
                            size: 16, color: Color(0xFF6366F1)),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "The top 5 stocks which will show most movement tomorrow are:",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                if (stocks.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "No recommendations yet",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...stocks.asMap().entries.map((entry) {
                    return _StockCard(symbol: entry.value, index: entry.key + 1);
                  }).toList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => RefreshIndicator(
          onRefresh: () => ref.refresh(recommendationsProvider.future),
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        "Oops! Something went wrong",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString().replaceAll("Exception: ", ""),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(recommendationsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _StockCard extends StatelessWidget {
  final String symbol;
  final int index;

  const _StockCard({required this.symbol, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF6366F1).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "$index",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          symbol,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        subtitle: Text(
          "Featured Recommendation",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }
}
