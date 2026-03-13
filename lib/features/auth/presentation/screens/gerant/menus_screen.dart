import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';

class MenusScreen extends StatefulWidget {
  final UserEntity user;
  const MenusScreen({super.key, required this.user});

  @override
  State<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends State<MenusScreen> {
  int _selectedDay = DateTime.now().weekday - 1;
  int _weekOffset =
      0; // 0 = semaine actuelle, -1 = semaine passée, +1 = semaine suivante
  final _firestore = FirebaseFirestore.instance;
  final List<String> _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];

  DateTime get _monday {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: _weekOffset * 7));
  }

  DateTime get _selectedDate {
    return _monday.add(Duration(days: _selectedDay));
  }

  String get _selectedDateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isPastDay {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return selected.isBefore(todayOnly);
  }

  bool get _isPastWeek {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final friday = _monday.add(const Duration(days: 4));
    return friday.isBefore(todayOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildDaysRow(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('menus')
                .where('date', isEqualTo: _selectedDateStr)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              final hasMenu = docs.isNotEmpty;

              if (!hasMenu) return _buildEmptyDay();

              final menuDoc = docs.first;
              final menuData = menuDoc.data() as Map<String, dynamic>;
              return _buildMenuContent(menuDoc.id, menuData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    final friday = _monday.add(const Duration(days: 4));
    final weekLabel =
        '${_monday.day} ${months[_monday.month]} - ${friday.day} ${months[friday.month]} ${friday.year}';

    return Container(
      color: const Color(0xFFFF6B35),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _weekOffset = 0;
                _selectedDay = DateTime.now().weekday - 1;
              });
            },
            child: Row(
              children: [
                const Text(
                  'Menus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                if (_weekOffset != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '↩ Aujourd\'hui',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flèche gauche - semaine précédente
              _buildWeekBtn('‹', () {
                setState(() {
                  _weekOffset--;
                  _selectedDay = 0;
                });
              }),
              // Label semaine
              Column(
                children: [
                  Text(
                    weekLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_weekOffset == 0)
                    const Text(
                      'Cette semaine',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    )
                  else if (_weekOffset == -1)
                    const Text(
                      'Semaine passée',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    )
                  else if (_weekOffset == 1)
                    const Text(
                      'Semaine prochaine',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    )
                  else
                    Text(
                      _weekOffset < 0
                          ? 'Il y a ${_weekOffset.abs()} semaines'
                          : 'Dans $_weekOffset semaines',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              // Flèche droite - semaine suivante
              _buildWeekBtn('›', () {
                setState(() {
                  _weekOffset++;
                  _selectedDay = 0;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaysRow() {
    final now = DateTime.now();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(5, (i) {
          final day = _monday.add(Duration(days: i));
          final isActive = i == _selectedDay;
          final isToday =
              day.day == now.day &&
              day.month == now.month &&
              day.year == now.year;
          final isPast = day.isBefore(DateTime(now.year, now.month, now.day));

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF6B35)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFF6B35)
                        : isToday
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFFEDEDED),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white70
                            : isPast
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF8A8A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? Colors.white
                            : isPast
                            ? const Color(0xFFCCCCCC)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Column(
      children: [
        const Spacer(),
        Text(_isPastDay ? '🔒' : '📅', style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          _isPastDay ? 'Jour passé' : 'Aucun menu pour ce jour',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isPastDay
              ? 'Impossible de créer un menu pour un jour passé'
              : 'Créez le menu de la journée',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 13),
        ),
        const Spacer(),
        if (!_isPastDay)
          GestureDetector(
            onTap: _createMenu,
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
                    'Créer le menu du jour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_isPastDay) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuContent(String menuId, Map<String, dynamic> menuData) {
    final actif = menuData['actif'] ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Statut actif/inactif
          GestureDetector(
            onTap: () => _firestore.collection('menus').doc(menuId).update({
              'actif': !actif,
            }),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: actif
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: actif
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEDEDED),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: actif
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF8A8A8A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    actif
                        ? 'Menu actif — visible par les étudiants'
                        : 'Menu inactif — invisible pour les étudiants',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actif
                          ? const Color(0xFF065F46)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    actif ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: actif
                        ? const Color(0xFF065F46)
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '🌅',
            'Petit déjeuner',
            'petitDej',
            (menuData['petitDej'] as List?)?.cast<String>() ?? [],
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '☀️',
            'Déjeuner',
            'dejeuner',
            (menuData['dejeuner'] as List?)?.cast<String>() ?? [],
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '🌙',
            'Dîner',
            'diner',
            (menuData['diner'] as List?)?.cast<String>() ?? [],
          ),
          const SizedBox(height: 16),
          SizedBox(
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
              onPressed: () => _deleteMenu(menuId),
              child: const Text(
                'Supprimer le menu du jour',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSlot(
    String menuId,
    String emoji,
    String titre,
    String field,
    List<String> platsIds,
  ) {
    return Container(
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
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${platsIds.length} plat(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ),
          if (platsIds.isNotEmpty)
            ...platsIds.map(
              (platId) => _buildPlatInSlot(menuId, field, platId),
            ),
          GestureDetector(
            onTap: () => _showAddPlatToSlot(menuId, field, platsIds),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFB89A), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '+ Ajouter un plat',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatInSlot(String menuId, String field, String platId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('plats').doc(platId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0EB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                _getEmoji(data['categorie'] ?? ''),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['nom'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${data['prix'] ?? 0} FCFA',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _removePlatFromSlot(menuId, field, platId),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF8A8A8A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPlatToSlot(String menuId, String field, List<String> existing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('plats').snapshots(),
        builder: (context, snapshot) {
          final docs =
              snapshot.data?.docs
                  .where((d) => !existing.contains(d.id))
                  .toList() ??
              [];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisir un plat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucun plat disponible',
                        style: TextStyle(color: Color(0xFF8A8A8A)),
                      ),
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: Text(
                          _getEmoji(data['categorie'] ?? ''),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          data['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${data['prix']} FCFA'),
                        onTap: () async {
                          await _firestore
                              .collection('menus')
                              .doc(menuId)
                              .update({
                                field: FieldValue.arrayUnion([doc.id]),
                              });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _removePlatFromSlot(String menuId, String field, String platId) {
    _firestore.collection('menus').doc(menuId).update({
      field: FieldValue.arrayRemove([platId]),
    });
  }

  void _createMenu() {
    _firestore.collection('menus').add({
      'date': _selectedDateStr,
      'actif': true,
      'petitDej': [],
      'dejeuner': [],
      'diner': [],
      'creePar': widget.user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _deleteMenu(String menuId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le menu ?'),
        content: const Text('Le menu de ce jour sera supprimé.'),
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
              _firestore.collection('menus').doc(menuId).delete();
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final months = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
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
}
