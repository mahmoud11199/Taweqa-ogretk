import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymobCheckoutScreen extends StatefulWidget {
  final String paymentKey;
  const PaymobCheckoutScreen({super.key, required this.paymentKey});

  @override
  State<PaymobCheckoutScreen> createState() => _PaymobCheckoutScreenState();
}

class _PaymobCheckoutScreenState extends State<PaymobCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    final url = 'https://accept.paymob.com/api/acceptance/iframes/760699?payment_token=${widget.paymentKey}';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
          _checkResult();
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
        onUrlChange: (change) => _checkUrl(change.url),
      ))
      ..loadRequest(Uri.parse(url));
  }

  void _checkUrl(String? url) {
    if (url == null || _popped) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final success = uri.queryParameters['success'];
    if (success == 'true') {
      _popped = true;
      Navigator.of(context).pop(true);
    }
  }

  void _checkResult() async {
    final url = await _controller.currentUrl();
    if (url != null) _checkUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الدفع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF080D18),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8))),
            ),
        ],
      ),
    );
  }
}
