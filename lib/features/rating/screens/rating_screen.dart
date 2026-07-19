import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../passenger/bloc/passenger_bloc.dart';
import '../../passenger/bloc/passenger_event.dart';
import '../../passenger/bloc/passenger_state.dart';

class RatingScreen extends StatefulWidget {
  final String requestId;
  final String driverName;

  const RatingScreen({
    super.key,
    required this.requestId,
    required this.driverName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      showToast(context, 'يرجى اختيار تقييم', isError: true);
      return;
    }
    context.read<PassengerBloc>().add(RateDriver(
          requestId: widget.requestId,
          rating: _rating.toDouble(),
          review: _reviewController.text.trim().isEmpty
              ? null
              : _reviewController.text.trim(),
        ));
    showToast(context, 'تم إرسال التقييم بنجاح');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PassengerBloc, PassengerState>(
      listener: (context, state) {
        if (state.error != null) {
          showToast(context, state.error!, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(title: const Text('تقييم السائق')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.account_circle,
                size: 80,
                color: AppTheme.meterPrimary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.driverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'كيف كانت تجربتك مع السائق؟',
                style: TextStyle(
                  color: AppTheme.meterMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 40,
                    onPressed: () => setState(() => _rating = starIndex),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      color: starIndex <= _rating
                          ? AppTheme.accent
                          : AppTheme.meterMuted,
                    ),
                  );
                }),
              ),
              if (_rating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _rating == 1
                        ? 'سيئ جداً'
                        : _rating == 2
                            ? 'سيئ'
                            : _rating == 3
                                ? 'مقبول'
                                : _rating == 4
                                    ? 'جيد'
                                    : 'ممتاز',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                maxLength: 500,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: 'أكتب تعليقاً (اختياري)',
                  hintTextDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text(
                    'إرسال التقييم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
