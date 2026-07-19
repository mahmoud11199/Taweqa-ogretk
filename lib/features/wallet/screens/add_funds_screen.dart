import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
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
    if (amount == null || amount <= 0) {
      showToast(context, 'يرجى إدخال مبلغ صحيح', isError: true);
      return;
    }
    if (amount < 10) {
      showToast(context, 'الحد الأدنى للإيداع 10 جنيه', isError: true);
      return;
    }
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty || phone.isEmpty) {
      showToast(context, 'يرجى إدخال البريد الإلكتروني ورقم الهاتف', isError: true);
      return;
    }
    context.read<WalletBloc>().add(InitDeposit(
      amount: amount,
      email: email,
      phone: phone,
      method: _selectedMethod,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state.error != null) {
          showToast(context, state.error!, isError: true);
        }
        if (state.paymobPaymentKey != null && !_paymentInProgress) {
          _paymentInProgress = true;
          final walletBloc = context.read<WalletBloc>();
          final pk = state.paymobPaymentKey!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymobMockScreen(paymentKey: pk),
            ),
          ).then((success) {
            _paymentInProgress = false;
            if (success == true && mounted) {
              walletBloc.add(VerifyDeposit(pk));
            }
          });
        }
        if (state.depositSuccess) {
          showToast(context, '✅ تم إضافة الرصيد بنجاح');
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(title: const Text('إضافة رصيد')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ (جنيه)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              const Text('طريقة الدفع',
                  style: TextStyle(color: AppTheme.meterMuted, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.credit_card,
                      label: 'بطاقة',
                      isSelected: _selectedMethod == 'card',
                      onTap: () => setState(() => _selectedMethod = 'card'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.account_balance_wallet,
                      label: 'محفظة',
                      isSelected: _selectedMethod == 'wallet',
                      onTap: () => setState(() => _selectedMethod = 'wallet'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.account_balance,
                      label: 'تحويل بنكي',
                      isSelected: _selectedMethod == 'bank',
                      onTap: () => setState(() => _selectedMethod = 'bank'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _initiateDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('إيداع', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.meterPrimary.withAlpha(30) : AppTheme.meterCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.meterPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.meterPrimary : AppTheme.meterMuted, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: isSelected ? AppTheme.meterPrimary : AppTheme.meterMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
