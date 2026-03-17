import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const AdminScreen({super.key, required this.user});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildActionsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bonjour 👋',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                '${widget.user.prenom} ${widget.user.nom}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('ADMINISTRATEUR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ),
            ],
          ),
          // ── Avatar + popup ─────────────────────────────────────────────────
          PopupMenuButton<String>(
            offset: const Offset(0, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            elevation: 8,
            onSelected: (value) async {
              if (value == 'profil') {
                _showProfilAdmin();
              } else if (value == 'mdp') {
                _showChangePassword();
              } else if (value == 'deconnexion') {
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              _menuItem('profil', Icons.person_outline, 'Mon profil',
                  const Color(0xFFF5F5F5), const Color(0xFF1a1a1a)),
              _menuItem('mdp', Icons.lock_outline, 'Changer le mot de passe',
                  const Color(0xFFF5F5F5), const Color(0xFF1a1a1a)),
              const PopupMenuDivider(height: 1),
              _menuItem('deconnexion', Icons.logout, 'Se déconnecter',
                  const Color(0xFFFEE2E2), const Color(0xFFEF4444),
                  labelColor: const Color(0xFFEF4444)),
            ],
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  '${widget.user.prenom[0]}${widget.user.nom[0]}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color iconBg,
    Color iconColor, {
    Color? labelColor,
  }) {
    return PopupMenuItem(
      value: value,
      height: 48,
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  // ── STATS ────────────────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vue d\'ensemble',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('commandes').snapshots(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data?.docs ?? [];
              final todayDocs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                if (ts == null) return false;
                final date = ts.toDate();
                return date.day == today.day &&
                    date.month == today.month &&
                    date.year == today.year;
              }).toList();
              final recettes = todayDocs.fold<double>(0, (sum, d) {
                final data = d.data() as Map<String, dynamic>;
                return sum + (data['montantTotal'] ?? 0).toDouble();
              });
              final enCours = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return ['recue', 'en_cuisine', 'prete']
                    .contains(data['statut'] ?? '');
              }).length;

              return Column(
                children: [
                  Row(
                    children: [
                      _statCard('${todayDocs.length}',
                          'Commandes aujourd\'hui', '📦',
                          const Color(0xFF1a1a1a)),
                      const SizedBox(width: 10),
                      _statCard(
                          '${recettes.toStringAsFixed(0)} F',
                          'Recettes du jour',
                          '💰',
                          const Color(0xFFFF6B35)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _statCard('$enCours', 'En cours', '🔥',
                          const Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('users')
                            .where('role', isEqualTo: 'etudiant')
                            .snapshots(),
                        builder: (context, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          return _statCard('$count',
                              'Étudiants inscrits', '🎓',
                              const Color(0xFF22C55E));
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, String emoji, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFEDEDED), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF8A8A8A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────────────────────────

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestion',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          _menuCard(
            icon: Icons.person_add,
            titre: 'Créer un gérant',
            description: 'Ajouter un nouveau compte gérant',
            onTap: () => _showCreerGerantDialog(),
          ),
          const SizedBox(height: 10),
          _menuCard(
            icon: Icons.people_outline,
            titre: 'Liste des gérants',
            description: 'Voir et supprimer les comptes gérants',
            trailing: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'gerant_cantine')
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                );
              },
            ),
            onTap: () => _showGerantsList(),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String titre,
    required String description,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFEDEDED), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, color: const Color(0xFF1a1a1a), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: const TextStyle(
                          color: Color(0xFF8A8A8A), fontSize: 11)),
                ],
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFF8A8A8A), size: 14),
          ],
        ),
      ),
    );
  }

  // ── PROFIL ADMIN ─────────────────────────────────────────────────────────────

  void _showProfilAdmin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data =
              snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final nom = data['nom'] ?? widget.user.nom;
          final prenom = data['prenom'] ?? widget.user.prenom;
          final email = data['email'] ?? widget.user.email;
          final telephone = data['telephone'] ?? '';

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('$prenom $nom',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1a1a1a).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Administrateur',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a1a1a))),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _profilRow(ctx, Icons.person_outline, 'Nom complet',
                          '$prenom $nom',
                          () => _editAdminField(
                              ctx, 'Nom', 'nom', nom)),
                      _profilRow(ctx, Icons.email_outlined, 'Email',
                          email, null),
                      _profilRow(
                        ctx,
                        Icons.phone_outlined,
                        'Téléphone',
                        telephone.isNotEmpty
                            ? telephone
                            : 'Ajouter un numéro',
                        () => _editAdminField(
                            ctx, 'Téléphone', 'telephone', telephone),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profilRow(BuildContext ctx, IconData icon, String label,
      String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: Colors.grey.shade200, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF8A8A8A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF8A8A8A))),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Color(0xFF8A8A8A), size: 16),
          ],
        ),
      ),
    );
  }

  void _editAdminField(BuildContext sheetCtx, String label, String field,
      String currentValue) {
    final ctrl = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: sheetCtx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier $label',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1a1a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _firestore
                      .collection('users')
                      .doc(widget.user.uid)
                      .update({field: ctrl.text.trim()});
                  Navigator.pop(context);
                },
                child: const Text('Enregistrer',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MOT DE PASSE ─────────────────────────────────────────────────────────────

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;
    bool sc = false, sn = false, sf = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(children: [
                Text('🔐', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Text('Changer le mot de passe',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              _pwdField('Mot de passe actuel', currentCtrl, sc,
                  () => setS(() => sc = !sc)),
              const SizedBox(height: 12),
              _pwdField('Nouveau mot de passe', newCtrl, sn,
                  () => setS(() => sn = !sn),
                  hint: 'Minimum 6 caractères'),
              const SizedBox(height: 12),
              _pwdField('Confirmer', confirmCtrl, sf,
                  () => setS(() => sf = !sf)),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(errorMsg!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a1a1a),
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
                            setS(() =>
                                errorMsg = 'Minimum 6 caractères requis');
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
                                      '✅ Mot de passe modifié'),
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
                            setS(
                                () {isLoading = false; errorMsg = msg;});
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
            fillColor: const Color(0xFFF5F5F5),
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
                color: const Color(0xFF8A8A8A), size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── LISTE GÉRANTS ─────────────────────────────────────────────────────────────

  void _showGerantsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gérants de cantine',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetCtx),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF8A8A8A)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'gerant_cantine')
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('👤',
                              style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Aucun gérant enregistré',
                              style: TextStyle(
                                  color: Color(0xFF8A8A8A),
                                  fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      return _gerantCard(
                          docs[i].id, data, sheetCtx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gerantCard(
      String uid, Map<String, dynamic> data, BuildContext sheetCtx) {
    final nom = data['nom'] ?? '';
    final prenom = data['prenom'] ?? '';
    final email = data['email'] ?? '';
    final nomCantine = data['nomCantine'] ?? 'Cantine non définie';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$prenom $nom',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(email,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 11, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(nomCantine,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmerSuppression(
                uid, '$prenom $nom', sheetCtx),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(
      String uid, String nomComplet, BuildContext sheetCtx) {
    showDialog(
      context: sheetCtx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ce gérant ?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Le compte de $nomComplet sera supprimé définitivement.',
            style: const TextStyle(color: Color(0xFF8A8A8A))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(sheetCtx),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF8A8A8A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await _firestore.collection('users').doc(uid).delete();
              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ── CRÉER GÉRANT ─────────────────────────────────────────────────────────────

  void _showCreerGerantDialog() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer un gérant',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dField(nomCtrl, 'Nom'),
              const SizedBox(height: 12),
              _dField(prenomCtrl, 'Prénom'),
              const SizedBox(height: 12),
              _dField(emailCtrl, 'Email',
                  type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _dField(pwdCtrl, 'Mot de passe', obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.isEmpty ||
                  prenomCtrl.text.isEmpty ||
                  emailCtrl.text.isEmpty ||
                  pwdCtrl.text.isEmpty) return;
              await ref.read(authProvider.notifier).inscription(
                    nomCtrl.text.trim(),
                    prenomCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    pwdCtrl.text.trim(),
                    'gerant_cantine',
                  );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Compte gérant créé avec succès ✅')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Widget _dField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F0EB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}