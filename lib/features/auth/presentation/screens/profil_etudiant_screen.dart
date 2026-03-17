import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _firestore = FirebaseFirestore.instance;
  int _tab = 0; // 0 = Profil, 1 = Historique

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
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
          final solde = d['soldeWallet'] ?? 0;

          return Column(
            children: [
              _buildHero(context, prenom: prenom, nom: nom, solde: solde),
              _buildTabs(),
              Expanded(
                child: _tab == 0
                    ? _buildProfilTab(prenom, nom, email, telephone)
                    : _buildHistoriqueTab(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HERO ─────────────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context,
      {required String prenom,
      required String nom,
      required dynamic solde}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A2E), Color(0xFF1A1A5E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Étudiant',
                          style: TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wallet card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('💰',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde wallet',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11)),
                        Text('$solde FCFA',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TABS ─────────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTab(0, 'Mon profil', Icons.person_outline),
          _buildTab(1, 'Historique', Icons.history),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isActive = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive
                    ? const Color(0xFF0A0A2E)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive
                      ? const Color(0xFF0A0A2E)
                      : const Color(0xFF8A8A8A)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF0A0A2E)
                          : const Color(0xFF8A8A8A))),
            ],
          ),
        ),
      ),
    );
  }

  // ── ONGLET PROFIL ─────────────────────────────────────────────────────────────

  Widget _buildProfilTab(
      String prenom, String nom, String email, String telephone) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('Informations personnelles', [
            _buildRow(Icons.person_outline, 'Nom complet', '$prenom $nom',
                () => _editNomComplet(prenom, nom)),
            _buildRow(Icons.email_outlined, 'Email', email, null),
            _buildRow(
              Icons.phone_outlined,
              'Téléphone',
              telephone.isNotEmpty ? telephone : 'Ajouter un numéro',
              () => _editField('Téléphone', 'telephone', telephone),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Se déconnecter',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                color: const Color(0xFFF5F0EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF0A0A2E)),
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

  // ── ONGLET HISTORIQUE ─────────────────────────────────────────────────────────

  Widget _buildHistoriqueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('commandes')
          .where('etudiantId', isEqualTo: widget.user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('📦', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('Aucune commande',
                    style: TextStyle(
                        color: Color(0xFF8A8A8A), fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _buildCommandeCard(data);
          },
        );
      },
    );
  }

  Widget _buildCommandeCard(Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? _formatDate(ts.toDate()) : '';
    final isActive =
        ['recue', 'en_cuisine', 'prete'].contains(statut);

    Color statusColor;
    String statusLabel;
    switch (statut) {
      case 'recue':
        statusColor = const Color(0xFF1E40AF);
        statusLabel = '⏳ Reçue';
        break;
      case 'en_cuisine':
        statusColor = const Color(0xFF92400E);
        statusLabel = '👨‍🍳 En cuisine';
        break;
      case 'prete':
        statusColor = const Color(0xFF065F46);
        statusLabel = '✅ Prête';
        break;
      case 'recuperee':
        statusColor = const Color(0xFF6B7280);
        statusLabel = '✓ Récupérée';
        break;
      default:
        statusColor = const Color(0xFF991B1B);
        statusLabel = '✕ Annulée';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF0A0A2E).withOpacity(0.2)
              : const Color(0xFFEDEDED),
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFF5F0EB)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                data['isBoisson'] == true ? '🥤' : '🍽️',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['numero'] ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(time,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF8A8A8A))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data['montantTotal'] ?? 0} FCFA',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B35))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── EDIT HELPERS ─────────────────────────────────────────────────────────────

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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Modifier le nom complet',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _mField('Prénom', prenomCtrl),
            const SizedBox(height: 12),
            _mField('Nom de famille', nomCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _firestore
                      .collection('users')
                      .doc(widget.user.uid)
                      .update({
                    'prenom': prenomCtrl.text.trim(),
                    'nom': nomCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Modifier $label',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _mField(label, ctrl),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A2E),
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
                  Navigator.pop(ctx);
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

  Widget _mField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
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

  String _formatDate(DateTime date) {
    final months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month]} · ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
  }
}