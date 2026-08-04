import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/theme/theme.dart';
import 'sign_in_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _showEmail = false;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? e.code);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled && mounted) {
        setState(() => _error = e.message);
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled') && !msg.contains('canceled') && mounted) {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CatspotTheme.of(context);

    return Scaffold(
      backgroundColor: tokens.colors.surfaceBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.space5,
            vertical: tokens.spacing.space6,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: tokens.spacing.space8),

                // Wordmark
                Text(
                  'Catspot',
                  textAlign: TextAlign.center,
                  style: tokens.typography.displayLarge.copyWith(
                    color: tokens.colors.brandPrimary,
                  ),
                ),
                SizedBox(height: tokens.spacing.space1),
                Text(
                  'Spot \'em. Collect \'em.',
                  textAlign: TextAlign.center,
                  style: tokens.typography.subtitle.copyWith(
                    color: tokens.colors.inkSecondary,
                  ),
                ),

                SizedBox(height: tokens.spacing.space8),

                // Apple Sign In (must appear above Google per App Store guidelines)
                SignInWithAppleButton(
                  onPressed: _busy
                      ? () {}
                      : () => _run(SignInService.withApple),
                  borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
                  height: 52,
                ),

                SizedBox(height: tokens.spacing.space3),

                // Google Sign In
                _GoogleSignInButton(
                  busy: _busy,
                  onPressed: () => _run(SignInService.withGoogle),
                  borderRadius: tokens.radius.radiusMd,
                ),

                SizedBox(height: tokens.spacing.space4),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: tokens.colors.divider)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.space3,
                      ),
                      child: Text(
                        'or',
                        style: tokens.typography.caption.copyWith(
                          color: tokens.colors.inkTertiary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: tokens.colors.divider)),
                  ],
                ),

                SizedBox(height: tokens.spacing.space4),

                if (!_showEmail) ...[
                  // Email toggle button
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _showEmail = true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: tokens.colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Continue with email',
                      style: tokens.typography.label.copyWith(
                        color: tokens.colors.inkPrimary,
                      ),
                    ),
                  ),
                ] else ...[
                  // Email form
                  _EmailForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isSignUp: _isSignUp,
                    busy: _busy,
                    onSubmit: () => _run(
                      () => SignInService.withEmail(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        isSignUp: _isSignUp,
                      ),
                    ),
                    onToggleMode: () =>
                        setState(() => _isSignUp = !_isSignUp),
                    tokens: tokens,
                  ),
                ],

                if (_error != null) ...[
                  SizedBox(height: tokens.spacing.space3),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: tokens.typography.caption.copyWith(
                      color: tokens.colors.semanticError,
                    ),
                  ),
                ],

                SizedBox(height: tokens.spacing.space6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.busy,
    required this.onPressed,
    required this.borderRadius,
  });

  final bool busy;
  final VoidCallback onPressed;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = CatspotTheme.of(context);

    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.white,
        side: BorderSide(color: tokens.colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GoogleLogo(),
          SizedBox(width: tokens.spacing.space2),
          Text(
            'Sign in with Google',
            style: tokens.typography.label.copyWith(
              color: const Color(0xFF3C4043),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Blue arc
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      -1.05,
      2.1,
      false,
      bluePaint,
    );

    // Full circle segments: Red top-left, Yellow bottom-left, Green bottom-right
    final segmentPaint = Paint()..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;

    segmentPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      -2.3,
      -1.5,
      false,
      segmentPaint,
    );

    segmentPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      2.3,
      0.9,
      false,
      segmentPaint,
    );

    segmentPaint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
      1.05,
      1.25,
      false,
      segmentPaint,
    );

    // G cut-in horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.emailController,
    required this.passwordController,
    required this.isSignUp,
    required this.busy,
    required this.onSubmit,
    required this.onToggleMode,
    required this.tokens,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSignUp;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final CatspotTokens tokens;

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: tokens.colors.surfacePaper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
        borderSide: BorderSide(color: tokens.colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
        borderSide: BorderSide(color: tokens.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
        borderSide: BorderSide(color: tokens.colors.brandPrimary, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.space3,
        vertical: tokens.spacing.space3,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailController,
          decoration: inputDecoration.copyWith(hintText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          style: tokens.typography.body.copyWith(color: tokens.colors.inkPrimary),
        ),
        SizedBox(height: tokens.spacing.space2),
        TextField(
          controller: passwordController,
          decoration: inputDecoration.copyWith(hintText: 'Password'),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => busy ? null : onSubmit(),
          style: tokens.typography.body.copyWith(color: tokens.colors.inkPrimary),
        ),
        SizedBox(height: tokens.spacing.space3),
        ElevatedButton(
          onPressed: busy ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: tokens.colors.brandPrimary,
            foregroundColor: tokens.colors.inkInverse,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radius.radiusMd),
            ),
          ),
          child: busy
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.colors.inkInverse,
                  ),
                )
              : Text(
                  isSignUp ? 'Create account' : 'Sign in',
                  style: tokens.typography.label.copyWith(
                    color: tokens.colors.inkInverse,
                  ),
                ),
        ),
        SizedBox(height: tokens.spacing.space2),
        TextButton(
          onPressed: busy ? null : onToggleMode,
          child: Text(
            isSignUp
                ? 'Already have an account? Sign in'
                : "Don't have an account? Create one",
            style: tokens.typography.caption.copyWith(
              color: tokens.colors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
