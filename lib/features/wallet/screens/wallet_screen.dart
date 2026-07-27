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
    context.read<WalletBloc>().add(LoadCards());
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
                // Saved cards section
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('البطاقات البنكية', style: TextStyle(color: Color(0xFFEDF2FC), fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                if (state.cards == null || state.cards!.isEmpty)
                  _buildAddCardButton()
                else ...[
                  ...state.cards!.map((c) => _CardTile(card: c)),
                  const SizedBox(height: 8),
                  _buildAddCardButton(),
                ],
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

  Widget _buildAddCardButton() {
    return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => _showAddCardDialog(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('إضافة بطاقة', style: TextStyle(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF00E5B8),
        side: const BorderSide(color: Color.fromRGBO(0, 229, 184, 0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
  }

  void _showAddCardDialog(BuildContext context) {
    final holderCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final csvCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1628),
        title: const Text('إضافة بطاقة', style: TextStyle(color: Color(0xFFEDF2FC))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: holderCtrl, style: const TextStyle(color: Color(0xFFEDF2FC)),
              decoration: const InputDecoration(labelText: 'اسم حامل البطاقة', labelStyle: TextStyle(color: Color(0xFF526480)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5B8))))),
            const SizedBox(height: 12),
            TextField(controller: numberCtrl, style: const TextStyle(color: Color(0xFFEDF2FC)), keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'رقم البطاقة', labelStyle: TextStyle(color: Color(0xFF526480)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5B8))))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: expCtrl, style: const TextStyle(color: Color(0xFFEDF2FC)),
                decoration: const InputDecoration(labelText: 'MM/YY', labelStyle: TextStyle(color: Color(0xFF526480)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5B8)))))),

              const SizedBox(width: 12),
              Expanded(child: TextField(controller: csvCtrl, style: const TextStyle(color: Color(0xFFEDF2FC)),
                decoration: const InputDecoration(labelText: 'CVV', labelStyle: TextStyle(color: Color(0xFF526480)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5B8)))))),

            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Color(0xFF526480)))),
          TextButton(onPressed: () {
            final num = numberCtrl.text.trim();
            if (num.length < 4) return;
            final last4 = num.substring(num.length - 4);
            final expParts = expCtrl.text.trim().split('/');
            final expMonth = int.tryParse(expParts[0]) ?? 12;
            final expYear = int.tryParse(expParts.length > 1 ? expParts[1] : '30') ?? 30;
            context.read<WalletBloc>().add(SaveCard(
              cardHolder: holderCtrl.text.trim().isEmpty ? 'حامل البطاقة' : holderCtrl.text.trim(),
              last4: last4, brand: num.startsWith('4') ? 'Visa' : num.startsWith('5') ? 'MasterCard' : 'Card',
              expMonth: expMonth, expYear: expYear,
            ));
            Navigator.pop(ctx);
          }, child: const Text('حفظ', style: TextStyle(color: Color(0xFF00E5B8)))),
        ],
      ),
    );
  }
}

// ─── Card Tile ─────────────────────────────────────────────────────────────────
class _CardTile extends StatelessWidget {
  final BankCard card;
  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.credit_card, color: Color(0xFF00E5B8), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${card.brand} **** ${card.last4}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 2),
                Text('${card.cardHolder} · ${card.expMonth}/${card.expYear}', style: const TextStyle(color: Color(0xFF526480), fontSize: 12)),
              ],
            ),
          ),
          if (card.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF00E5B8).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: const Text('أساسي', style: TextStyle(color: Color(0xFF00E5B8), fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3B5C), size: 20),
            onPressed: () => context.read<WalletBloc>().add(DeleteCard(card.id)),
          ),
        ],
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
