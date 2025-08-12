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
  // Track which date sections are expanded
  Set<DateTime> _expandedDates = {};
  
  // Daily spending limit
  static const double dailyLimit = 500.0;

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
      // Expand today's section by default
      _expandTodaySection();
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

  void _expandTodaySection() {
    if (expenses.isNotEmpty) {
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      setState(() {
        _expandedDates.add(todayKey);
      });
    }
  }

  void _toggleDateSection(DateTime date) {
    setState(() {
      if (_expandedDates.contains(date)) {
        _expandedDates.remove(date);
      } else {
        _expandedDates.add(date);
      }
    });
  }

  Future<void> _addExpense(Expense expense) async {
    try {
      // Check if adding this expense would exceed daily limit
      final todayExpenses = _getTodayExpenses();
      final todayTotal = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final newTotal = todayTotal + expense.amount;
      
      // Add the expense directly
      await _databaseHelper.insertExpense(expense);
      await _loadExpenses(); // Reload the list
      
      // Show snackbar if daily limit is exceeded
      if (newTotal > dailyLimit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Daily limit exceeded! New total: ₹${newTotal.toStringAsFixed(0)} (Limit: ₹${dailyLimit.toStringAsFixed(0)})',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
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

  // Get today's expenses
  List<Expense> _getTodayExpenses() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    return expenses.where((expense) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      return expenseDate == todayKey;
    }).toList();
  }

  // Calculate today's total spending
  double _calculateTodayTotal() {
    final todayExpenses = _getTodayExpenses();
    return todayExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get spending limit status
  Map<String, dynamic> _getSpendingLimitStatus() {
    final todayTotal = _calculateTodayTotal();
    final percentage = (todayTotal / dailyLimit * 100).clamp(0.0, 100.0);
    
    Color progressColor;
    String statusText;
    
    if (todayTotal >= dailyLimit) {
      progressColor = Colors.red;
      statusText = 'Limit exceeded!';
    } else if (todayTotal >= dailyLimit * 0.8) {
      progressColor = Colors.orange;
      statusText = 'Near limit';
    } else {
      progressColor = Colors.green;
      statusText = 'Under limit';
    }
    
    return {
      'percentage': percentage,
      'color': progressColor,
      'statusText': statusText,
      'todayTotal': todayTotal,
    };
  }

  // Group expenses by date
  Map<DateTime, List<Expense>> _groupExpensesByDate() {
    Map<DateTime, List<Expense>> groupedExpenses = {};
    
    for (Expense expense in expenses) {
      // Create a date key without time (just year, month, day)
      DateTime dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
      
      if (groupedExpenses.containsKey(dateKey)) {
        groupedExpenses[dateKey]!.add(expense);
      } else {
        groupedExpenses[dateKey] = [expense];
      }
    }
    
    // Sort the map by date (most recent first)
    Map<DateTime, List<Expense>> sortedExpenses = Map.fromEntries(
      groupedExpenses.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key))
    );
    
    return sortedExpenses;
  }

  // Calculate total amount for a specific date
  double _calculateDailyTotal(List<Expense> dailyExpenses) {
    return dailyExpenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  // Build list items for grouped expenses
  List<Widget> _buildGroupedExpenseList() {
    Map<DateTime, List<Expense>> groupedExpenses = _groupExpensesByDate();
    List<Widget> widgets = [];
    
    groupedExpenses.forEach((date, dailyExpenses) {
      final isExpanded = _expandedDates.contains(date);
      
      // Add collapsible date header with daily total
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
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
          child: Column(
            children: [
              // Date header (always visible)
              InkWell(
                onTap: () => _toggleDateSection(date),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Expand/collapse icon
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      
                      // Date and total
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatDateHeader(date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dailyExpenses.length}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${_calculateDailyTotal(dailyExpenses).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Collapsible expense list
              if (isExpanded) ...[
                const Divider(height: 1),
                ...dailyExpenses.map((expense) => _buildExpenseCard(expense)).toList(),
              ],
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }

  // Build individual expense card
  Widget _buildExpenseCard(Expense expense) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
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
          title: Text(
            expense.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatTime(expense.date),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editExpense(expense);
                  } else if (value == 'delete') {
                    _deleteExpense(expense.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        ),
        const Divider(height: 1, indent: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final spendingStatus = _getSpendingLimitStatus();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Money Tracker',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        actions: [
          IconButton(
            icon: Icon(
              Icons.analytics_outlined,
              color: Colors.grey[800],
            ),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
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
                            '₹${_calculateTotal().toStringAsFixed(0)}',
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
                
                // Daily Limit Progress
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.today,
                      size: 16,
                      color: spendingStatus['color'],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today: ₹${spendingStatus['todayTotal'].toStringAsFixed(0)} / ₹${dailyLimit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: spendingStatus['color'],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      spendingStatus['statusText'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: spendingStatus['color'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: spendingStatus['percentage'] / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: spendingStatus['color'],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: _buildGroupedExpenseList(),
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

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      // Format: "Monday, 15 Jan 2024"
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      
      return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calculateTotal() {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
} 