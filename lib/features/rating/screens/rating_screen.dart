import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../passenger/bloc/passenger_bloc.dart';
import '../../passenger/bloc/passenger_event.dart';
import '../../passenger/bloc/passenger_state.dart';

class RatingScreen extends StatefulWidget {
  final String requestId;
  final String driverName;

  const RatingScreen({super.key, required this.requestId, required this.driverName});

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
    if (_rating == 0) { showToast(context, 'يرجى اختيار تقييم', isError: true); return; }
    context.read<PassengerBloc>().add(RateDriver(
      requestId: widget.requestId, rating: _rating.toDouble(),
      review: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
    ));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['', 'سيئ جداً', 'سيئ', 'مقبول', 'جيد', 'ممتاز'];
    return BlocListener<PassengerBloc, PassengerState>(
      listener: (context, state) {
        if (state.error != null) showToast(context, state.error!, isError: true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('تقييم السائق', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00E5B8), Color(0xFF0088CC)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.person, size: 44, color: Color(0xFF080D18)),
              ),
              const SizedBox(height: 16),
              Text(widget.driverName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
              const SizedBox(height: 8),
              const Text('كيف كانت تجربتك مع السائق؟', style: TextStyle(fontSize: 14, color: Color(0xFF526480))),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    iconSize: 44,
                    onPressed: () => setState(() => _rating = starIndex),
                    icon: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      color: starIndex <= _rating ? const Color(0xFFFFB020) : const Color(0xFF243558),
                    ),
                  );
                }),
              ),
              if (_rating > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(labels[_rating], style: const TextStyle(color: Color(0xFFFFB020), fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                maxLength: 500,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'أكتب تعليقاً (اختياري)',
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: TextStyle(color: Color(0xFF526480)),
                  filled: true,
                  fillColor: Color(0xFF0F1628),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB020),
                    foregroundColor: const Color(0xFF080D18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('إرسال التقييم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
