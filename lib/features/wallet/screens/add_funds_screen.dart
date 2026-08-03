import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void dispose() {
    _channel?.unsubscribe();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initiateDeposit() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) { showToast(context, 'يرجى إدخال مبلغ صحيح', isError: true); return; }
    if (amount < 10) { showToast(context, 'الحد الأدنى للإيداع 10 جنيه', isError: true); return; }
    final senderPhone = _phoneController.text.trim();
    if (senderPhone.isEmpty || !RegExp(r'^01[0-9]{9}$').hasMatch(senderPhone)) {
      showToast(context, 'يرجى إدخال رقم محفظتك بشكل صحيح (01xxxxxxxxx)', isError: true);
      return;
    }
    context.read<WalletBloc>().add(InitDeposit(amount: amount, senderPhone: senderPhone));
  }

  void _subscribeToDeposit(String depositId) {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('deposit-$depositId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'wallet_transactions',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: depositId),
          callback: (payload) {
            if (!mounted) return;
            final newRow = payload.newRecord;
            final status = newRow['status'] as String?;
            if (status == 'success') {
              context.read<WalletBloc>().add(ResetDeposit());
              showToast(context, '✅ تم إضافة الرصيد بنجاح');
              context.read<WalletBloc>().add(LoadWallet());
              Navigator.pop(context);
            } else if (status == 'failed' || status == 'unmatched') {
              context.read<WalletBloc>().add(ResetDeposit());
              showToast(context, 'لم يتم تأكيد الدفع، راجع الرقم والمبلغ', isError: true);
              setState(() {});
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state.error != null) showToast(context, state.error!, isError: true);
        if (state.depositSubmitted && state.pendingDepositId != null) {
          _subscribeToDeposit(state.pendingDepositId!);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          title: const Text('إضافة رصيد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context)),
        ),
        body: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state.depositSubmitted) return _buildPending(state);
            return _buildForm(state);
          },
        ),
      ),
    );
  }

  Widget _buildForm(WalletState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField(label: 'المبلغ (جنيه)', icon: Icons.monetization_on_outlined, controller: _amountController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildField(label: 'رقم محفظتك (فودافون/أورانج/اتصالات/وي)', icon: Icons.phone_android_outlined, controller: _phoneController, keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1628),
              border: Border.all(color: const Color(0xFF1C2B45)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF00E5B8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'حوّل المبلغ إلى رقم المحفظة ${AppConstants.adminWalletPhone} ثم انتظر تأكيد الدفع تلقائيًا',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF8EA4C8), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _initiateDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5B8),
                foregroundColor: const Color(0xFF080D18),
                disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: state.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                  : const Text('إيداع', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPending(WalletState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56, height: 56,
              child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF00E5B8)),
            ),
            const SizedBox(height: 24),
            const Text('بانتظار تأكيد الدفع...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
            const SizedBox(height: 8),
            Text(
              'المبلغ: ${state.lastDepositAmount.toStringAsFixed(2)} ج',
              style: const TextStyle(fontSize: 15, color: Color(0xFF00E5B8), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'من رقم: ${state.lastSenderPhone ?? ''}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF526480)),
            ),
            const SizedBox(height: 16),
            const Text(
              'سيُحدَّث رصيدك تلقائيًا فور استلام إشعار التحويل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8EA4C8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required IconData icon, required TextEditingController controller, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller, style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF526480)),
        prefixIcon: Icon(icon, color: const Color(0xFF526480)),
        filled: true, fillColor: const Color(0xFF0F1628),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF00E5B8))),
      ),
      keyboardType: keyboardType,
    );
  }
}