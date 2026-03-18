import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../data/services/google_auth_service.dart';
import 'home_screen.dart';
import 'admin_screen.dart';
import 'gerant_screen.dart';
import 'inscription_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connectez-vous',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  const Text('Accédez à votre espace cantine',
                      style: TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 13)),
                  const SizedBox(height: 28),

                  // ── Bouton Google ─────────────────────────────────────
                  _buildGoogleButton(),
                  const SizedBox(height: 20),

                  // ── Séparateur ────────────────────────────────────────
                  _buildDivider(),
                  const SizedBox(height: 20),

                  // ── Email ──────────────────────────────────────────────
                  _buildLabel('Email'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _emailCtrl,
                    hint: 'votre@email.com',
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // ── Mot de passe ───────────────────────────────────────
                  _buildLabel('Mot de passe'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _pwdCtrl,
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFFB0B0B0),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Erreur ─────────────────────────────────────────────
                  if (_error != null) _buildError(_error!),
                  const SizedBox(height: 8),

                  // ── Bouton connexion ───────────────────────────────────
                  _buildLoginButton(),
                  const SizedBox(height: 20),

                  // ── Lien inscription ───────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InscriptionScreen())),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Pas encore de compte ? ',
                          style: TextStyle(
                              color: Color(0xFFB0B0B0), fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'S\'inscrire',
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

  // ── HERO ──────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Cercle décoratif orange
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B35).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B35).withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                      child: Text('🍽️', style: TextStyle(fontSize: 34))),
                ),
                const SizedBox(height: 14),
                const Text('Cantine Scolaire',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const Text('Bon repas, chaque jour 🌟',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GOOGLE BUTTON ──────────────────────────────────────────────────────────

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _googleLoading ? null : _signInWithGoogle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4285F4))))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Google SVG simplifié via texte
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continuer avec Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── DIVIDER ────────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('ou',
            style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ),
      const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
    ]);
  }

  // ── FORM FIELDS ────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14),
          prefixIcon:
              Icon(icon, color: const Color(0xFFCCCCCC), size: 18),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildError(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline,
              color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    color: Color(0xFFEF4444), fontSize: 12)),
          ),
        ]),
      );

  // ── LOGIN BUTTON ───────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: _loading
              ? const Color(0xFFCCCCCC)
              : const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Se connecter',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  // ── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pwd = _pwdCtrl.text.trim();
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // login() retourne void — on lit l'utilisateur depuis le state après
      await ref.read(authProvider.notifier).login(email, pwd);
      if (!mounted) return;
      final user = ref.read(authProvider).user;
      if (user != null) _navigate(user);
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
      if (mounted) _navigate(user);
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _googleLoading = false;
          // popup_closed = l'utilisateur a fermé la fenêtre → pas une vraie erreur
          _error = (msg.contains('annulée') || msg.contains('popup_closed'))
              ? null
              : 'Erreur Google Sign-In : $msg';
        });
      }
    }
  }

  void _navigate(dynamic user) {
    Widget screen;
    switch (user.role as String) {
      case 'administrateur':
        screen = AdminScreen(user: user);
        break;
      case 'gerant_cantine':
        screen = GerantScreen(user: user);
        break;
      default:
        screen = HomeScreen(user: user);

    }
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => screen), (r) => false);
  }

  String _errorMessage(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Email ou mot de passe incorrect';
    }
    if (raw.contains('invalid-email')) return 'Adresse email invalide';
    if (raw.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard';
    }
    return 'Connexion échouée. Vérifiez vos informations';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo Google (sans image externe)
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
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

    // Fond blanc du cercle
    canvas.drawCircle(Offset(cx, cy), r,
        Paint()..color = Colors.white);

    // Arc rouge (haut)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        -1.1, 1.7, false,
        Paint()
          ..color = const Color(0xFFEA4335)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);

    // Arc bleu (gauche)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        2.6, 1.4, false,
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);

    // Arc jaune (bas)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        1.1, 1.1, false,
        Paint()
          ..color = const Color(0xFFFBBC05)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);

    // Arc vert (bas droit)
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.85),
        0.55, 0.6, false,
        Paint()
          ..color = const Color(0xFF34A853)
          ..strokeWidth = r * 0.28
          ..style = PaintingStyle.stroke);

    // Barre horizontale du G
    canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * 0.82, cy),
        Paint()
          ..color = const Color(0xFF4285F4)
          ..strokeWidth = r * 0.28
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}