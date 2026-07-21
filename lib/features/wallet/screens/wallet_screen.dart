import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../models/wallet_model.dart';
import '../bloc/wallet_state.dart';
import 'add_funds_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(LoadWallet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('المحفظة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.isLoading && state.wallet == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          }
          final wallet = state.wallet;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF001A14), Color(0xFF002E22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('الرصيد الحالي', style: TextStyle(color: Color(0xFF526480), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        wallet != null ? formatCurrency(wallet.balance) : '0.00 ج',
                        style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5B8), fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 46,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5B8),
                            foregroundColor: const Color(0xFF080D18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('إضافة رصيد', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('آخر المعاملات', style: TextStyle(color: Color(0xFFEDF2FC), fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                if (state.transactions.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.only(top: 32), child: Text('لا توجد معاملات بعد', style: TextStyle(color: Color(0xFF526480)))))
                else
                  ...state.transactions.map((t) => _TransactionTile(transaction: t)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == 'deposit';
    final color = isDeposit ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description ?? (isDeposit ? 'إيداع' : 'سحب'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                Text(timeAgo(transaction.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'}${formatCurrency((transaction.amount as num).toDouble())}',
            style: TextStyle(fontFamily: 'monospace', color: color, fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
