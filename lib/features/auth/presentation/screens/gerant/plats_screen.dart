import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';

class PlatsScreen extends StatefulWidget {
  final UserEntity user;
  const PlatsScreen({super.key, required this.user});

  @override
  State<PlatsScreen> createState() => _PlatsScreenState();
}

class _PlatsScreenState extends State<PlatsScreen> {
  String _selectedCategorie = 'Tous';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final List<String> _categories = [
    'Tous',
    'Express',
    'Plat du jour',
    'Entrées',
    'Boissons',
  ];
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isDispo(dynamic val) {
    return val == true || val == 'true' || val == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildSearch(),
        _buildCategories(),
        Expanded(child: _buildPlatsList()),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bonjour 👋',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${widget.user.prenom} ${widget.user.nom}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white38),
                ),
                child: Center(
                  child: Text(
                    '${widget.user.prenom[0]}${widget.user.nom[0]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('plats').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final total = docs.length;
              final dispos = docs
                  .where((d) => _isDispo((d.data() as Map)['disponible']))
                  .length;
              final indispos = total - dispos;
              return Row(
                children: [
                  _buildKpi('$total', 'Total plats'),
                  const SizedBox(width: 8),
                  _buildKpi('$dispos', 'Disponibles'),
                  const SizedBox(width: 8),
                  _buildKpi('$indispos', 'Indisponibles'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpi(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              val,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFCCCCCC), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Rechercher un plat...',
                hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.close,
                color: Color(0xFF8A8A8A),
                size: 16,
              ),
            )
          else
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = cat == _selectedCategorie;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategorie = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFF6B35) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFFEDEDED),
                  width: 1.5,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF8A8A8A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlatsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('plats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('🍽️', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text(
                  'Aucun plat pour l\'instant',
                  style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
                ),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        // Filtre catégorie
        if (_selectedCategorie != 'Tous') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['categorie'] ?? '').toString().toLowerCase() ==
                _selectedCategorie.toLowerCase();
          }).toList();
        }

        // Filtre recherche
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final nom = (data['nom'] ?? '').toString().toLowerCase();
            final desc = (data['description'] ?? '').toString().toLowerCase();
            return nom.contains(_searchQuery) || desc.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Aucun résultat pour "$_searchQuery"'
                      : 'Aucun plat dans "$_selectedCategorie"',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPlatCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildPlatCard(String id, Map<String, dynamic> data) {
    final dispo = _isDispo(data['disponible']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getEmoji(data['categorie'] ?? ''),
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: dispo
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nom'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${data['categorie'] ?? ''} · ${data['tempsPreparation'] ?? 0} min',
                        style: const TextStyle(
                          color: Color(0xFF8A8A8A),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['prix'] ?? 0} FCFA',
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEDEDED), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _buildAction(
                  '✏️ Modifier',
                  const Color(0xFFFF6B35),
                  () => _showEditDialog(id, data),
                ),
                _buildActionSep(),
                _buildAction(
                  dispo ? '● Disponible' : '✕ Indispo',
                  dispo ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  () => _toggleDispo(id, dispo),
                ),
                _buildActionSep(),
                _buildAction(
                  '🗑️ Suppr.',
                  const Color(0xFFEF4444),
                  () => _deletePlat(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSep() {
    return Container(width: 0.5, height: 36, color: const Color(0xFFEDEDED));
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddDialog(),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Ajouter un nouveau plat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'express':
        return '🍳';
      case 'plat du jour':
        return '🍛';
      case 'entrées':
        return '🥗';
      case 'boissons':
        return '🥤';
      default:
        return '🍽️';
    }
  }

  void _toggleDispo(String id, bool current) {
    _firestore.collection('plats').doc(id).update({'disponible': !current});
  }

  void _deletePlat(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce plat ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _firestore.collection('plats').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() => _showPlatDialog();
  void _showEditDialog(String id, Map<String, dynamic> data) =>
      _showPlatDialog(id: id, data: data);

  void _showPlatDialog({String? id, Map<String, dynamic>? data}) {
    final nomCtrl = TextEditingController(text: data?['nom'] ?? '');
    final prixCtrl = TextEditingController(
      text: data?['prix']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(text: data?['description'] ?? '');
    final tempsCtrl = TextEditingController(
      text: data?['tempsPreparation']?.toString() ?? '',
    );
    String categorie = data?['categorie'] ?? 'express';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                id == null ? 'Nouveau plat' : 'Modifier le plat',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildModalField('Nom du plat', nomCtrl),
              const SizedBox(height: 12),
              _buildModalField('Description', descCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModalField(
                      'Prix (FCFA)',
                      prixCtrl,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModalField(
                      'Temps (min)',
                      tempsCtrl,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Catégorie',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: categorie,
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
                items: const [
                  DropdownMenuItem(value: 'express', child: Text('Express')),
                  DropdownMenuItem(
                    value: 'plat du jour',
                    child: Text('Plat du jour'),
                  ),
                  DropdownMenuItem(value: 'entrées', child: Text('Entrées')),
                  DropdownMenuItem(value: 'boissons', child: Text('Boissons')),
                ],
                onChanged: (v) => setModalState(() => categorie = v!),
              ),
              const SizedBox(height: 20),
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
                    final platData = {
                      'nom': nomCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'prix': double.tryParse(prixCtrl.text) ?? 0,
                      'categorie': categorie,
                      'tempsPreparation': int.tryParse(tempsCtrl.text) ?? 0,
                      'disponible': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    if (id == null) {
                      platData['createdAt'] = FieldValue.serverTimestamp();
                      _firestore.collection('plats').add(platData);
                    } else {
                      _firestore.collection('plats').doc(id).update(platData);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    id == null ? 'Ajouter le plat' : 'Enregistrer',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

  Widget _buildModalField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
      ],
    );
  }
}
