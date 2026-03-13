import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class InscriptionScreen extends ConsumerStatefulWidget {
  const InscriptionScreen({super.key});

  @override
  ConsumerState<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends ConsumerState<InscriptionScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B35)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1a1a1a),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rejoignez la cantine scolaire',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildField('Nom', _nomController, 'Diallo'),
              const SizedBox(height: 16),
              _buildField('Prénom', _prenomController, 'Yasmine'),
              const SizedBox(height: 16),
              _buildField(
                'Email',
                _emailController,
                'votre@email.com',
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Mot de passe',
                _passwordController,
                '••••••••',
                obscure: true,
              ),
              if (authState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  authState.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          // Sauvegarder email et password avant inscription
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();

                          await ref
                              .read(authProvider.notifier)
                              .inscription(
                                _nomController.text.trim(),
                                _prenomController.text.trim(),
                                email,
                                password,
                              );

                          // Si inscription réussie → retour vers login
                          // avec email et password déjà remplis
                          if (ref.read(authProvider).error == null) {
                            if (context.mounted) {
                              Navigator.pop(context, {
                                'email': email,
                                'password': password,
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "S'inscrire",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
