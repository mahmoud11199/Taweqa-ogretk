import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/bloc/wallet_event.dart';
import '../../wallet/bloc/wallet_state.dart';
import '../../wallet/models/wallet_model.dart';
import '../../wallet/screens/add_funds_screen.dart';

class DriverWalletScreen extends StatefulWidget {
  final bool inTab;
  const DriverWalletScreen({super.key, this.inTab = false});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
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
        leading: widget.inTab ? const SizedBox.shrink() : IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('المحفظة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          final balance = state.wallet?.balance ?? 0;
          final transactions = state.transactions;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            child: Column(
              children: [
                _buildBalanceCard(balance),
                const SizedBox(height: 14),
                _buildActionsCard(),
                const SizedBox(height: 18),
                const Text('آخر المعاملات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55)),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('لا توجد معاملات بعد', style: TextStyle(color: Color(0xFF526480), fontSize: 13)),
                  )
                else
                  ...List.generate(transactions.length, (i) => _buildTransactionRow(transactions[i])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    final whole = balance.toInt();
    final fraction = ((balance - whole) * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001A14), Color(0xFF002E22), Color(0xFF001E30)],
        ),
        border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الرصيد', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$whole', style: const TextStyle(fontFamily: 'monospace', fontSize: 42, fontWeight: FontWeight.w800, color: Color(0xFF00E5B8), height: 1)),
              Text('.${fraction.toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: 'monospace', fontSize: 22, color: Color(0xFF00B896))),
              const SizedBox(width: 6),
              const Text('EGP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF526480))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFundsScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5B8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('+ شحن', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF080D18))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 229, 184, 0.1),
                border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.25)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('سحب', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF00E5B8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction txn) {
    final isCredit = txn.amount >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1C2B45))),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color.fromRGBO(0, 229, 184, 0.1)
                  : const Color.fromRGBO(255, 59, 92, 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isCredit ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: isCredit ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.description ?? txn.type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 2),
                Text(_formatDate(txn.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFF3A5070))),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${txn.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isCredit ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}