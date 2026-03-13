import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class ProfilGerantScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const ProfilGerantScreen({super.key, required this.user});

  @override
  ConsumerState<ProfilGerantScreen> createState() => _ProfilGerantScreenState();
}

class _ProfilGerantScreenState extends ConsumerState<ProfilGerantScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, userSnapshot) {
        final userData =
            userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final nom = userData['nom'] ?? widget.user.nom;
        final prenom = userData['prenom'] ?? widget.user.prenom;
        final email = userData['email'] ?? widget.user.email;
        final telephone = userData['telephone'] ?? '';
        final nomCantine = userData['nomCantine'] ?? 'Non défini';
        final emplacement = userData['emplacement'] ?? 'Non défini';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(nom: nom, prenom: prenom),
              _buildSection('Informations personnelles', [
                _buildRow(
                  Icons.person_outline,
                  'Nom complet',
                  '$prenom $nom',
                  () => _editField('Nom complet', 'nom', nom),
                ),
                _buildRow(Icons.email_outlined, 'Email', email, null),
                _buildRow(
                  Icons.phone_outlined,
                  'Téléphone',
                  telephone.isNotEmpty ? telephone : 'Ajouter un numéro',
                  () => _editField('Téléphone', 'telephone', telephone),
                ),
              ]),
              _buildSection('Sécurité', [
                _buildRow(
                  Icons.lock_outline,
                  'Mot de passe',
                  'Changer le mot de passe',
                  () {},
                ),
                _buildRow(
                  Icons.notifications_outlined,
                  'Notifications',
                  'Activées',
                  () {},
                ),
              ]),
              _buildSection('Ma cantine', [
                _buildRow(
                  Icons.store_outlined,
                  'Nom de la cantine',
                  nomCantine,
                  () =>
                      _editField('Nom de la cantine', 'nomCantine', nomCantine),
                ),
                _buildRow(
                  Icons.location_on_outlined,
                  'Emplacement',
                  emplacement,
                  () => _editField('Emplacement', 'emplacement', emplacement),
                ),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero({required String nom, required String prenom}) {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF6B35),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text('📷', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$prenom $nom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Gérant de cantine',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Text(
                      '★★★★★',
                      style: TextStyle(color: Color(0xFFFCD34D), fontSize: 12),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8A8A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildRow(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEDEDED), width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF8A8A8A),
                size: 18,
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
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEDED),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Modifier $label',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F0EB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _firestore.collection('users').doc(widget.user.uid).update({
                    field: ctrl.text.trim(),
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
