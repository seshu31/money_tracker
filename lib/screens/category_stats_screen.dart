import 'package:flutter/material.dart';
import '../models/expense.dart';

class CategoryStatsScreen extends StatelessWidget {
  final List<Expense> expenses;

  const CategoryStatsScreen({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _calculateCategoryTotals();
    final totalAmount = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Category Statistics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: Column(
        children: [
          // Total Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expenses',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${expenses.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Category Breakdown
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoryTotals.length,
              itemBuilder: (context, index) {
                final category = categoryTotals.keys.elementAt(index);
                final amount = categoryTotals[category]!;
                final percentage = totalAmount > 0 ? (amount / totalAmount * 100) : 0.0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getTypeColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getTypeIcon(category),
                            color: _getTypeColor(category),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Category Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${percentage.toStringAsFixed(1)}% of total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Progress Bar and Count
                        SizedBox(
                          width: 60,
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: totalAmount > 0 ? amount / totalAmount : 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(category),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(category).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_getExpenseCount(category)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getTypeColor(category),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> categoryTotals = {};
    
    for (final expense in expenses) {
      categoryTotals[expense.type] = (categoryTotals[expense.type] ?? 0) + expense.amount;
    }
    
    // Sort by amount (highest first)
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries);
  }

  int _getExpenseCount(String category) {
    return expenses.where((expense) => expense.type == category).length;
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'bills':
        return Colors.red;
      case 'health':
        return Colors.green;
      case 'sports':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.medical_services;
      case 'sports':
        return Icons.sports_soccer;
      default:
        return Icons.attach_money;
    }
  }
} 