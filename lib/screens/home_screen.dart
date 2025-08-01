import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import 'add_expense_screen.dart';
import 'category_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final loadedExpenses = await _databaseHelper.getExpenses();
      setState(() {
        expenses = loadedExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    }
  }

  Future<void> _addExpense(Expense expense) async {
    try {
      await _databaseHelper.insertExpense(expense);
      await _loadExpenses(); // Reload the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding expense: $e')),
        );
      }
    }
  }

  Future<void> _updateExpense(Expense expense) async {
    try {
      await _databaseHelper.updateExpense(expense);
      await _loadExpenses(); // Reload the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating expense: $e')),
        );
      }
    }
  }

  Future<void> _deleteExpense(String id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _databaseHelper.deleteExpense(id);
                  await _loadExpenses(); // Reload the list
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting expense: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expense: expense),
      ),
    );
    if (result != null && result is Expense) {
      await _updateExpense(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryStatsScreen(expenses: expenses),
                ),
              );
            },
            tooltip: 'Category Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Expenses Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Expenses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${_calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expenses.length} expense${expenses.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Expenses List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : expenses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to add your first expense',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.edit, color: Colors.blue),
                                            title: const Text('Edit Expense'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _editExpense(expense);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete, color: Colors.red),
                                            title: const Text('Delete Expense'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _deleteExpense(expense.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Icon and category
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(expense.type).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getTypeIcon(expense.type),
                                        color: _getTypeColor(expense.type),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Expense details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getTypeColor(expense.type).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  expense.type,
                                                  style: TextStyle(
                                                    color: _getTypeColor(expense.type),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatDate(expense.date),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (expense.description.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              expense.description,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // Amount and actions
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${expense.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              onPressed: () => _editExpense(expense),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              onPressed: () => _deleteExpense(expense.id),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
          if (result != null && result is Expense) {
            await _addExpense(result);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateTotal() {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
} 