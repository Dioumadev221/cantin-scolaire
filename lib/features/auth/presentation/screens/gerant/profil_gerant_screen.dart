import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class ProfilGerantScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const ProfilGerantScreen({super.key, required this.user});

  @override
  ConsumerState<ProfilGerantScreen> createState() =>
      _ProfilGerantScreenState();
}

class _ProfilGerantScreenState extends ConsumerState<ProfilGerantScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.user.uid)
            .snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};
          final nom = d['nom'] ?? widget.user.nom;
          final prenom = d['prenom'] ?? widget.user.prenom;
          final email = d['email'] ?? widget.user.email;
          final telephone = d['telephone'] ?? '';
          final nomCantine = d['nomCantine'] ?? 'Non défini';
          final emplacement = d['emplacement'] ?? 'Non défini';
          final notifs = d['notificationsActivees'] ?? true;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(context, nom: nom, prenom: prenom),
                _buildSection('Informations personnelles', [
                  _buildRow(
                    Icons.person_outline, 'Nom complet', '$prenom $nom',
                    () => _editNomComplet(prenom, nom),
                  ),
                  _buildRow(
                    Icons.email_outlined, 'Email', email,
                    () => _showChangeEmail(email),
                  ),
                  _buildRow(
                    Icons.phone_outlined, 'Téléphone',
                    telephone.isNotEmpty ? telephone : 'Ajouter un numéro',
                    () => _editField('Téléphone', 'telephone', telephone),
                  ),
                ]),
                _buildSection('Ma cantine', [
                  _buildRow(
                    Icons.store_outlined, 'Nom de la cantine', nomCantine,
                    () => _editField('Nom de la cantine', 'nomCantine', nomCantine),
                  ),
                  _buildRow(
                    Icons.location_on_outlined, 'Emplacement', emplacement,
                    () => _editField('Emplacement', 'emplacement', emplacement),
                  ),
                ]),
                _buildSection('Sécurité & notifications', [
                  _buildRow(
                    Icons.lock_outline, 'Mot de passe',
                    'Modifier mon mot de passe',
                    () => _showChangePassword(),
                  ),
                  _buildNotifToggle(notifs),
                ]),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Se déconnecter',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── HERO ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context,
      {required String nom, required String prenom}) {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 18),
            ),
          ),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Center(
              child: Text(
                '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prenom $nom',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Text('Gérant de cantine',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTIONS ─────────────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A8A8A),
                    letterSpacing: 0.5)),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: Color(0xFFEDEDED), width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFFFF6B35)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFF8A8A8A), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifToggle(bool enabled) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: Color(0xFFEDEDED), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 16, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                Text(enabled ? 'Activées' : 'Désactivées',
                    style: TextStyle(
                        fontSize: 11,
                        color: enabled
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF8A8A8A))),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeColor: const Color(0xFFFF6B35),
            onChanged: (val) => _firestore
                .collection('users')
                .doc(widget.user.uid)
                .update({'notificationsActivees': val}),
          ),
        ],
      ),
    );
  }

  // ── MODIFIER NOM COMPLET ─────────────────────────────────────────────────────

  void _editNomComplet(String currentPrenom, String currentNom) {
    final prenomCtrl = TextEditingController(text: currentPrenom);
    final nomCtrl = TextEditingController(text: currentNom);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            const Text('Modifier le nom complet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _modalField('Prénom', prenomCtrl),
            const SizedBox(height: 12),
            _modalField('Nom de famille', nomCtrl),
            const SizedBox(height: 20),
            _saveBtn('Enregistrer', () async {
              await _firestore
                  .collection('users')
                  .doc(widget.user.uid)
                  .update({
                'prenom': prenomCtrl.text.trim(),
                'nom': nomCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  // ── MODIFIER EMAIL ────────────────────────────────────────────────────────────

  void _showChangeEmail(String currentEmail) {
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? errorMsg;
    bool isLoading = false;
    bool showPwd = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              const SizedBox(height: 16),
              const Row(children: [
                Text('📧', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Text('Changer l\'adresse email',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Text('Email actuel : $currentEmail',
                  style: const TextStyle(
                      color: Color(0xFF8A8A8A), fontSize: 12)),
              const SizedBox(height: 16),
              _modalField('Nouvel email', newEmailCtrl,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              // Mot de passe pour ré-auth
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mot de passe actuel',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: !showPwd,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F0EB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      suffixIcon: GestureDetector(
                        onTap: () => setS(() => showPwd = !showPwd),
                        child: Icon(
                          showPwd
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF8A8A8A),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                _errorBox(errorMsg!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final newEmail = newEmailCtrl.text.trim();
                          final pwd = passwordCtrl.text;
                          if (newEmail.isEmpty || pwd.isEmpty) {
                            setS(() => errorMsg =
                                'Veuillez remplir tous les champs');
                            return;
                          }
                          if (!newEmail.contains('@')) {
                            setS(() => errorMsg = 'Email invalide');
                            return;
                          }
                          setS(() {
                            isLoading = true;
                            errorMsg = null;
                          });
                          try {
                            final user = _auth.currentUser!;
                            final cred = EmailAuthProvider.credential(
                                email: user.email!, password: pwd);
                            await user.reauthenticateWithCredential(cred);
                            await user.verifyBeforeUpdateEmail(newEmail);
                            // Mise à jour Firestore immédiatement
                            await _firestore
                                .collection('users')
                                .doc(widget.user.uid)
                                .update({'email': newEmail});
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '📧 Email mis à jour. Vérifiez $newEmail pour confirmer.'),
                                  backgroundColor: const Color(0xFF22C55E),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String msg;
                            switch (e.code) {
                              case 'wrong-password':
                              case 'invalid-credential':
                                msg = 'Mot de passe incorrect';
                                break;
                              case 'email-already-in-use':
                                msg = 'Cet email est déjà utilisé';
                                break;
                              case 'invalid-email':
                                msg = 'Format d\'email invalide';
                                break;
                              default:
                                msg = e.message ?? e.code;
                            }
                            setS(() {
                              isLoading = false;
                              errorMsg = msg;
                            });
                          } catch (_) {
                            setS(() {
                              isLoading = false;
                              errorMsg = 'Une erreur est survenue';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Mettre à jour l\'email',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MODIFIER MOT DE PASSE ────────────────────────────────────────────────────

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              const SizedBox(height: 16),
              const Row(children: [
                Text('🔐', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Text('Changer le mot de passe',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              _pwdField('Mot de passe actuel', currentCtrl, showCurrent,
                  () => setS(() => showCurrent = !showCurrent)),
              const SizedBox(height: 12),
              _pwdField('Nouveau mot de passe', newCtrl, showNew,
                  () => setS(() => showNew = !showNew),
                  hint: 'Minimum 6 caractères'),
              const SizedBox(height: 12),
              _pwdField('Confirmer le nouveau mot de passe', confirmCtrl,
                  showConfirm,
                  () => setS(() => showConfirm = !showConfirm)),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                _errorBox(errorMsg!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (currentCtrl.text.isEmpty ||
                              newCtrl.text.isEmpty ||
                              confirmCtrl.text.isEmpty) {
                            setS(() => errorMsg =
                                'Veuillez remplir tous les champs');
                            return;
                          }
                          if (newCtrl.text.length < 6) {
                            setS(() => errorMsg =
                                'Minimum 6 caractères requis');
                            return;
                          }
                          if (newCtrl.text != confirmCtrl.text) {
                            setS(() => errorMsg =
                                'Les mots de passe ne correspondent pas');
                            return;
                          }
                          setS(() {
                            isLoading = true;
                            errorMsg = null;
                          });
                          try {
                            final user = _auth.currentUser!;
                            final cred = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentCtrl.text);
                            await user.reauthenticateWithCredential(cred);
                            await user.updatePassword(newCtrl.text);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      '✅ Mot de passe modifié avec succès'),
                                  backgroundColor:
                                      const Color(0xFF22C55E),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String msg;
                            switch (e.code) {
                              case 'wrong-password':
                              case 'invalid-credential':
                                msg = 'Mot de passe actuel incorrect';
                                break;
                              default:
                                msg = e.message ?? e.code;
                            }
                            setS(() {
                              isLoading = false;
                              errorMsg = msg;
                            });
                          } catch (_) {
                            setS(() {
                              isLoading = false;
                              errorMsg = 'Une erreur est survenue';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Mettre à jour',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CHAMP GÉNÉRIQUE ───────────────────────────────────────────────────────────

  void _editField(String label, String field, String currentValue) {
    final ctrl = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            Text('Modifier $label',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _modalField(label, ctrl),
            const SizedBox(height: 16),
            _saveBtn('Enregistrer', () {
              _firestore
                  .collection('users')
                  .doc(widget.user.uid)
                  .update({field: ctrl.text.trim()});
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    );
  }

  // ── HELPERS UI ────────────────────────────────────────────────────────────────

  Widget _buildHandle() => Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _modalField(
    String label,
    TextEditingController ctrl, {
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F0EB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _pwdField(String label, TextEditingController ctrl, bool show,
      VoidCallback toggle, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: !show,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFCCCCCC), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFFF5F0EB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            suffixIcon: GestureDetector(
              onTap: toggle,
              child: Icon(
                show ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF8A8A8A),
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveBtn(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFEF4444), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 12)),
            ),
          ],
        ),
      );
}