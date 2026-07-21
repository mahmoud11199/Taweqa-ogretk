import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import 'paymob_mock_screen.dart';

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedMethod = 'card';
  bool _paymentInProgress = false;

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initiateDeposit() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) { showToast(context, 'يرجى إدخال مبلغ صحيح', isError: true); return; }
    if (amount < 10) { showToast(context, 'الحد الأدنى للإيداع 10 جنيه', isError: true); return; }
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty || phone.isEmpty) { showToast(context, 'يرجى إدخال البريد الإلكتروني ورقم الهاتف', isError: true); return; }
    context.read<WalletBloc>().add(InitDeposit(amount: amount, email: email, phone: phone, method: _selectedMethod));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state.error != null) showToast(context, state.error!, isError: true);
        if (state.paymobPaymentKey != null && !_paymentInProgress) {
          _paymentInProgress = true;
          final walletBloc = context.read<WalletBloc>();
          final pk = state.paymobPaymentKey!;
          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymobMockScreen(paymentKey: pk))).then((success) {
            _paymentInProgress = false;
            if (success == true && mounted) walletBloc.add(VerifyDeposit(pk));
          });
        }
        if (state.depositSuccess) { showToast(context, '✅ تم إضافة الرصيد بنجاح'); Navigator.pop(context); }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          title: const Text('إضافة رصيد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(label: 'المبلغ (جنيه)', icon: Icons.monetization_on_outlined, controller: _amountController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField(label: 'البريد الإلكتروني', icon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField(label: 'رقم الهاتف', icon: Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              const Text('طريقة الدفع', style: TextStyle(fontSize: 14, color: Color(0xFF526480))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MethodCard(icon: Icons.credit_card, label: 'بطاقة', isSelected: _selectedMethod == 'card', onTap: () => setState(() => _selectedMethod = 'card'))),
                  const SizedBox(width: 8),
                  Expanded(child: _MethodCard(icon: Icons.account_balance_wallet, label: 'محفظة', isSelected: _selectedMethod == 'wallet', onTap: () => setState(() => _selectedMethod = 'wallet'))),
                  const SizedBox(width: 8),
                  Expanded(child: _MethodCard(icon: Icons.account_balance, label: 'تحويل بنكي', isSelected: _selectedMethod == 'bank', onTap: () => setState(() => _selectedMethod = 'bank'))),
                ],
              ),
              const SizedBox(height: 32),
              BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  return SizedBox(
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
                  );
                },
              ),
            ],
          ),
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

class _MethodCard extends StatelessWidget {
  final IconData icon; final String label; final bool isSelected; final VoidCallback onTap;
  const _MethodCard({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromRGBO(0, 229, 184, 0.1) : const Color(0xFF0F1628),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF00E5B8) : const Color(0xFF1C2B45), width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF00E5B8) : const Color(0xFF526480), size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFF00E5B8) : const Color(0xFF526480), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
