import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_repository_provider.dart';
import '../../data/datasources/app_database.dart';

// Riverpod භාවිතා කරන බැවින් StatelessWidget වෙනුවට ConsumerWidget භාවිතා කරයි
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Repository එක Provider එක හරහා ලබා ගැනීම
    final accountRepo = ref.watch(accountRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accounts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<Account>>(
        // Database එකෙන් සජීවීව (Live) දත්ත ලබා ගැනීම
        stream: accountRepo.watchAllAccounts(),
        builder: (context, snapshot) {
          // දත්ත load වන තෙක් loading indicator එක පෙන්වීම
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // දෝෂයක් ඇත්නම් එය පෙන්වීම
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final accounts = snapshot.data ?? [];

          // Database එකේ ගිණුම් නොමැති නම්
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts found.'));
          }

          // ගිණුම් ලැයිස්තුව UI එකේ පෙන්වීම
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet),
                  ),
                  title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(account.type.toUpperCase()),
                  trailing: Text(
                    'Rs. ${account.initialBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}