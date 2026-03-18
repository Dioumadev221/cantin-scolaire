import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../data/services/google_auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class InscriptionScreen extends ConsumerStatefulWidget {
  const InscriptionScreen({super.key});

  @override
  ConsumerState<InscriptionScreen> createState() =>
      _InscriptionScreenState();
}

class _InscriptionScreenState extends ConsumerState<InscriptionScreen> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Créer un compte',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  const Text('Rejoignez la cantine scolaire',
                      style: TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 13)),
                  const SizedBox(height: 24),

                  // ── Bouton Google ─────────────────────────────────────
                  _buildGoogleButton(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 20),

                  // ── Formulaire ────────────────────────────────────────
                  Row(children: [
                    Expanded(child: _buildField(_prenomCtrl, 'Prénom',
                        Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(_nomCtrl, 'Nom',
                        Icons.person_outline)),
                  ]),
                  const SizedBox(height: 14),
                  _buildField(_emailCtrl, 'Email',
                      Icons.email_outlined,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _buildField(_pwdCtrl, 'Mot de passe',
                      Icons.lock_outline,
                      obscure: _obscurePwd,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePwd = !_obscurePwd),
                        child: Icon(
                          _obscurePwd
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFB0B0B0),
                          size: 18,
                        ),
                      )),
                  const SizedBox(height: 14),
                  _buildField(_confirmCtrl, 'Confirmer le mot de passe',
                      Icons.lock_outline,
                      obscure: _obscureConfirm,
                      suffix: GestureDetector(
                        onTap: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFB0B0B0),
                          size: 18,
                        ),
                      )),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _buildError(_error!),
                  ],
                  const SizedBox(height: 20),

                  // ── Bouton inscription ────────────────────────────────
                  _buildSubmitButton(),
                  const SizedBox(height: 20),

                  // ── Lien connexion ────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Déjà un compte ? ',
                          style: TextStyle(
                              color: Color(0xFFB0B0B0), fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✨ Inscription', style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Compte étudiant', style: TextStyle(
                      color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GOOGLE ─────────────────────────────────────────────────────────────────

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _googleLoading ? null : _signInWithGoogle,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _googleLoading
            ? const Center(
                child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4285F4))))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _GoogleLogo(),
                const SizedBox(width: 12),
                const Text('Continuer avec Google',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
              ]),
      ),
    );
  }

  Widget _buildDivider() => Row(children: [
    const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text('ou avec email',
          style: TextStyle(
              color: Colors.grey.shade400, fontSize: 12,
              fontWeight: FontWeight.w500)),
    ),
    const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
  ]);

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType type = TextInputType.text,
      bool obscure = false,
      Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5)),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFFCCCCCC), size: 18),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12), child: suffix)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildError(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))),
    ]),
  );

  Widget _buildSubmitButton() => GestureDetector(
    onTap: _loading ? null : _inscrire,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 54,
      decoration: BoxDecoration(
          color: _loading
              ? const Color(0xFFCCCCCC)
              : const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: _loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Créer mon compte',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w800)),
      ),
    ),
  );

  // ── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _inscrire() async {
    final prenom = _prenomCtrl.text.trim();
    final nom = _nomCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (prenom.isEmpty || nom.isEmpty || email.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }
    if (pwd != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier)
          .inscription(nom, prenom, email, pwd, 'etudiant');
      final user = ref.read(authProvider).user;
      if (mounted && user != null) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
            (r) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _errorMessage(e.toString());
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final user = await GoogleAuthService.signIn();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
            (r) => false);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _googleLoading = false;
          _error = (msg.contains('annulée') || msg.contains('popup_closed'))
              ? null
              : 'Erreur Google : $msg';
        });
      }
    }
  }

  String _errorMessage(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'Cet email est déjà utilisé';
    }
    if (raw.contains('invalid-email')) return 'Adresse email invalide';
    if (raw.contains('weak-password')) return 'Mot de passe trop faible';
    return 'Inscription échouée. Réessayez';
  }
}

// ── Logo Google (réutilisé depuis login_screen) ──────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 22, height: 22,
        child: CustomPaint(painter: _GoogleLogoPainter()));
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        -1.1, 1.7, false,
        Paint()
          ..color = const Color(0xFFEA4335)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        2.6, 1.4, false,
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        1.1, 1.1, false,
        Paint()
          ..color = const Color(0xFFFBBC05)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        0.55, 0.6, false,
        Paint()
          ..color = const Color(0xFF34A853)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.82, cy),
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = r * 0.28
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}