import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfilEtudiantScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const ProfilEtudiantScreen({super.key, required this.user});

  @override
  ConsumerState<ProfilEtudiantScreen> createState() =>
      _ProfilEtudiantScreenState();
}

class _ProfilEtudiantScreenState
    extends ConsumerState<ProfilEtudiantScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(widget.user.uid).snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data() as Map<String, dynamic>? ?? {};
          final nom = d['nom'] ?? widget.user.nom;
          final prenom = d['prenom'] ?? widget.user.prenom;
          final email = d['email'] ?? widget.user.email;
          final telephone = d['telephone'] ?? '';
          final solde = (d['soldeWallet'] ?? 0).toDouble();
          final notifs = d['notificationsActivees'] ?? true;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(context, nom: nom, prenom: prenom,
                    email: email, solde: solde),

                _buildSection('Informations personnelles', [
                  _buildRow(Icons.person_outline, 'Nom complet',
                      '$prenom $nom',
                      () => _editNomComplet(prenom, nom)),
                  _buildRow(Icons.email_outlined, 'Email', email,
                      () => _showChangeEmail(email)),
                  _buildRow(Icons.phone_outlined, 'Téléphone',
                      telephone.isNotEmpty ? telephone : 'Ajouter un numéro',
                      () => _editField('Téléphone', 'telephone', telephone)),
                ]),

                _buildSection('Mon wallet', [
                  _buildWalletRow(solde),
                ]),

                _buildSection('Sécurité & notifications', [
                  _buildRow(Icons.lock_outline, 'Mot de passe',
                      'Modifier mon mot de passe',
                      () => _showChangePassword()),
                  _buildNotifToggle(notifs),
                ]),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── HERO ──────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, {
    required String nom,
    required String prenom,
    required String email,
    required double solde,
  }) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Row(children: [
        // Retour
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back,
                color: Colors.white, size: 18),
          ),
        ),
        // Avatar
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24, width: 2)),
          child: Center(
            child: Text(
              '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
              style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Nom + email
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$prenom $nom',
                style: const TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(email,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Bouton déconnexion
        GestureDetector(
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.logout, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('Quitter', style: TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── SECTIONS ──────────────────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFEEEEEE), width: 0.5)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8A8A),
                  letterSpacing: 0.5)),
        ),
        ...rows,
      ]),
    );
  }

  Widget _buildRow(IconData icon, String label, String value,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5))),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16,
                color: const Color(0xFFFF6B35)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
                  Text(value, style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8A8A8A))),
                ]),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right,
                color: Color(0xFF8A8A8A), size: 18),
        ]),
      ),
    );
  }

  Widget _buildWalletRow(double solde) {
    return Container(
      decoration: const BoxDecoration(border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_balance_wallet_outlined,
              size: 16, color: Color(0xFFFF6B35))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Solde disponible', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A))),
          Text('${solde.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6B35))),
        ])),
        // Bouton recharger inline
        GestureDetector(
          onTap: () => _showRecharge(),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Recharger', style: TextStyle(
                color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _buildNotifToggle(bool enabled) {
    return Container(
      decoration: const BoxDecoration(border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.notifications_outlined,
              size: 16, color: Color(0xFFFF6B35))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Notifications', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A))),
          Text(enabled ? 'Activées' : 'Désactivées',
              style: TextStyle(fontSize: 11,
                  color: enabled
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF8A8A8A))),
        ])),
        Switch(
          value: enabled,
          activeColor: const Color(0xFFFF6B35),
          onChanged: (val) => _db.collection('users')
              .doc(widget.user.uid)
              .update({'notificationsActivees': val}),
        ),
      ]),
    );
  }

  // ── RECHARGE WALLET ────────────────────────────────────────────────────────

  void _showRecharge() {
    final libreCtrl = TextEditingController();
    const montants = [500, 1000, 2000, 5000];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (c, setS) {
        int? selected; bool loading = false; String? err;

        Future<void> recharger(double montant) async {
          setS(() { loading = true; err = null; });
          try {
            await _db.collection('users').doc(widget.user.uid).update({
              'soldeWallet': FieldValue.increment(montant),
            });
            await _db.collection('recharges').add({
              'etudiantId': widget.user.uid,
              'etudiantNom': '${widget.user.prenom} ${widget.user.nom}',
              'montant': montant, 'statut': 'validee',
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (c.mounted) Navigator.pop(c);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${montant.toStringAsFixed(0)} FCFA ajoutés 🎉'),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))));
          } catch (e) { setS(() { loading = false; err = 'Erreur : $e'; }); }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(c).viewInsets.bottom + 28),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _handle(),
            const SizedBox(height: 20),
            const Row(children: [
              Text('💳', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Text('Recharger mon wallet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A))),
            ]),
            const SizedBox(height: 6),
            const Text('Choisissez un montant ou saisissez un montant libre',
                style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12)),
            const SizedBox(height: 20),
            const Text('Montants rapides', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: Color(0xFF6B6B6B))),
            const SizedBox(height: 10),
            Row(children: montants.map((m) {
              final sel = selected == m;
              return Expanded(child: GestureDetector(
                onTap: () => setS(() { selected = m; libreCtrl.clear(); }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: m != montants.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFFFF6B35) : const Color(0xFFF8F7F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? const Color(0xFFFF6B35) : const Color(0xFFEEEEEE),
                          width: sel ? 2 : 1)),
                  child: Column(children: [
                    Text('$m', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sel ? Colors.white : const Color(0xFF1A1A1A))),
                    Text('F', style: TextStyle(fontSize: 10,
                        color: sel ? Colors.white70 : const Color(0xFFB0B0B0))),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 16),
            const Text('Montant libre', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: Color(0xFF6B6B6B))),
            const SizedBox(height: 8),
            TextField(
              controller: libreCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setS(() => selected = null),
              decoration: InputDecoration(
                hintText: 'Ex : 3000',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                suffixText: 'FCFA',
                suffixStyle: const TextStyle(
                    color: Color(0xFFFF6B35), fontWeight: FontWeight.w700),
                filled: true, fillColor: const Color(0xFFF8F7F4),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: Color(0xFFFF6B35), width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14)),
            ),
            if (err != null) ...[
              const SizedBox(height: 10),
              _errorBox(err!),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))),
                onPressed: loading ? null : () {
                  final montant = selected?.toDouble()
                      ?? double.tryParse(libreCtrl.text.trim());
                  if (montant == null || montant <= 0) {
                    setS(() => err = 'Veuillez saisir un montant valide');
                    return;
                  }
                  recharger(montant);
                },
                child: loading
                    ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmer la recharge',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              )),
          ]),
        );
      }),
    );
  }

  // ── MODIFIER NOM COMPLET ──────────────────────────────────────────────────

  void _editNomComplet(String currentPrenom, String currentNom) {
    final prenomCtrl = TextEditingController(text: currentPrenom);
    final nomCtrl = TextEditingController(text: currentNom);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _handle(), const SizedBox(height: 16),
          const Text('Modifier le nom complet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _modalField('Prénom', prenomCtrl),
          const SizedBox(height: 12),
          _modalField('Nom de famille', nomCtrl),
          const SizedBox(height: 20),
          _saveBtn('Enregistrer', () async {
            await _db.collection('users').doc(widget.user.uid).update({
              'prenom': prenomCtrl.text.trim(),
              'nom': nomCtrl.text.trim(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
          }),
        ]),
      ),
    );
  }

  // ── MODIFIER EMAIL ────────────────────────────────────────────────────────

  void _showChangeEmail(String currentEmail) {
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        String? err; bool loading = false; bool showPwd = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _handle(), const SizedBox(height: 16),
            const Row(children: [
              Text('📧', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('Changer l\'adresse email',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text('Email actuel : $currentEmail',
                style: const TextStyle(
                    color: Color(0xFF8A8A8A), fontSize: 12)),
            const SizedBox(height: 16),
            _modalField('Nouvel email', newEmailCtrl,
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Mot de passe actuel',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: passwordCtrl, obscureText: !showPwd,
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFFF8F7F4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  suffixIcon: GestureDetector(
                    onTap: () => setS(() => showPwd = !showPwd),
                    child: Icon(showPwd
                        ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF8A8A8A), size: 18)),
                )),
            ]),
            if (err != null) ...[const SizedBox(height: 10), _errorBox(err!)],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: loading ? null : () async {
                  final newEmail = newEmailCtrl.text.trim();
                  if (newEmail.isEmpty || passwordCtrl.text.isEmpty) {
                    setS(() => err = 'Veuillez remplir tous les champs'); return;
                  }
                  if (!newEmail.contains('@')) {
                    setS(() => err = 'Email invalide'); return;
                  }
                  setS(() { loading = true; err = null; });
                  try {
                    final user = _auth.currentUser!;
                    await user.reauthenticateWithCredential(
                        EmailAuthProvider.credential(
                            email: user.email!,
                            password: passwordCtrl.text));
                    await user.verifyBeforeUpdateEmail(newEmail);
                    await _db.collection('users').doc(widget.user.uid)
                        .update({'email': newEmail});
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('📧 Vérifiez $newEmail pour confirmer.'),
                        backgroundColor: const Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        duration: const Duration(seconds: 4)));
                    }
                  } on FirebaseAuthException catch (e) {
                    setS(() { loading = false;
                      err = (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential')
                          ? 'Mot de passe incorrect'
                          : e.message ?? e.code;
                    });
                  }
                },
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Mettre à jour l\'email',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              )),
          ]),
        );
      }),
    );
  }

  // ── MODIFIER MOT DE PASSE ─────────────────────────────────────────────────

  void _showChangePassword() {
    final cCtrl = TextEditingController();
    final nCtrl = TextEditingController();
    final coCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        bool loading = false; String? err;
        bool showC = false, showN = false, showCo = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _handle(), const SizedBox(height: 16),
            const Row(children: [
              Text('🔐', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Text('Changer le mot de passe',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            _pwdField('Mot de passe actuel', cCtrl, showC,
                () => setS(() => showC = !showC)),
            const SizedBox(height: 12),
            _pwdField('Nouveau mot de passe', nCtrl, showN,
                () => setS(() => showN = !showN),
                hint: 'Minimum 6 caractères'),
            const SizedBox(height: 12),
            _pwdField('Confirmer', coCtrl, showCo,
                () => setS(() => showCo = !showCo)),
            if (err != null) ...[const SizedBox(height: 10), _errorBox(err!)],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: loading ? null : () async {
                  if (cCtrl.text.isEmpty || nCtrl.text.isEmpty ||
                      coCtrl.text.isEmpty) {
                    setS(() => err = 'Veuillez remplir tous les champs');
                    return;
                  }
                  if (nCtrl.text.length < 6) {
                    setS(() => err = 'Minimum 6 caractères'); return;
                  }
                  if (nCtrl.text != coCtrl.text) {
                    setS(() => err = 'Les mots de passe ne correspondent pas');
                    return;
                  }
                  setS(() { loading = true; err = null; });
                  try {
                    final user = _auth.currentUser!;
                    await user.reauthenticateWithCredential(
                        EmailAuthProvider.credential(
                            email: user.email!, password: cCtrl.text));
                    await user.updatePassword(nCtrl.text);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text(
                            '✅ Mot de passe modifié avec succès'),
                        backgroundColor: const Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))));
                    }
                  } on FirebaseAuthException catch (e) {
                    setS(() { loading = false;
                      err = (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential')
                          ? 'Mot de passe actuel incorrect'
                          : e.message ?? e.code;
                    });
                  }
                },
                child: loading
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Mettre à jour',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              )),
          ]),
        );
      }),
    );
  }

  // ── CHAMP GÉNÉRIQUE ───────────────────────────────────────────────────────

  void _editField(String label, String field, String currentValue) {
    final ctrl = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _handle(), const SizedBox(height: 16),
          Text('Modifier $label', style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _modalField(label, ctrl),
          const SizedBox(height: 16),
          _saveBtn('Enregistrer', () {
            _db.collection('users').doc(widget.user.uid)
                .update({field: ctrl.text.trim()});
            Navigator.pop(ctx);
          }),
        ]),
      ),
    );
  }

  // ── HELPERS UI ─────────────────────────────────────────────────────────────

  Widget _handle() => Center(child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(2))));

  Widget _modalField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, keyboardType: type, autofocus: true,
          decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8F7F4),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12))),
      ]);

  Widget _pwdField(String label, TextEditingController ctrl,
      bool show, VoidCallback toggle, {String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, obscureText: !show,
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: Color(0xFFCCCCCC), fontSize: 12),
              filled: true, fillColor: const Color(0xFFF8F7F4),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              suffixIcon: GestureDetector(onTap: toggle,
                  child: Icon(show
                      ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF8A8A8A), size: 18)))),
      ]);

  Widget _saveBtn(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700))));

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      const Icon(Icons.error_outline,
          color: Color(0xFFEF4444), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(
          color: Color(0xFFEF4444), fontSize: 12))),
    ]));
}