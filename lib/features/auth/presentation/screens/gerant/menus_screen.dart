import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'profil_gerant_screen.dart';

class MenusScreen extends ConsumerStatefulWidget {
  final UserEntity user;
  const MenusScreen({super.key, required this.user});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  int _selectedDay = DateTime.now().weekday - 1;
  int _weekOffset = 0;
  final _firestore = FirebaseFirestore.instance;
  final List<String> _days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];

  DateTime get _monday {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: _weekOffset * 7));
  }

  DateTime get _selectedDate => _monday.add(Duration(days: _selectedDay));

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
              if (docs.isEmpty) return _buildEmptyDay();
              return _buildMenuContent(
                docs.first.id,
                docs.first.data() as Map<String, dynamic>,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _weekOffset = 0;
                  _selectedDay = DateTime.now().weekday - 1;
                }),
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
                    if (_weekOffset != 0) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
              ),
              // ── Cloche + Avatar ──────────────────────────────────────────────
              Row(
                children: [
                  _buildNotificationBell(),
                  const SizedBox(width: 8),
                  _buildAvatarMenu(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeekBtn(
                '‹',
                () => setState(() {
                  _weekOffset--;
                  _selectedDay = 0;
                }),
              ),
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
                  Text(
                    _weekOffset == 0
                        ? 'Cette semaine'
                        : _weekOffset == -1
                        ? 'Semaine passée'
                        : _weekOffset == 1
                        ? 'Semaine prochaine'
                        : _weekOffset < 0
                        ? 'Il y a ${_weekOffset.abs()} semaines'
                        : 'Dans $_weekOffset semaines',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              _buildWeekBtn(
                '›',
                () => setState(() {
                  _weekOffset++;
                  _selectedDay = 0;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CLOCHE NOTIFICATIONS ───────────────────────────────────────────────────

  Widget _buildNotificationBell() {
    return StreamBuilder<int>(
      stream: NotificationService.compteurNonLusGerant(),
      builder: (_, snap) {
        final count = snap.data ?? 0;
        return GestureDetector(
          onTap: _showNotificationsSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white38),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
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

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: NotificationService.marquerToutesLuesGerant,
                    child: const Text(
                      'Tout lire',
                      style: TextStyle(color: Color(0xFFFF6B35)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: NotificationService.streamToutesGerant(),
                builder: (_, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🔔', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 12),
                          Text(
                            'Aucune notification',
                            style: TextStyle(color: Color(0xFF8A8A8A)),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final isRead = data['lu'] == true;
                      final ts = data['createdAt'] as Timestamp?;
                      final type = data['type'] ?? 'info';
                      return Dismissible(
                        key: Key(docs[i].id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            NotificationService.supprimer(docs[i].id),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Supprimer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              NotificationService.marquerLue(docs[i].id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.white
                                  : const Color(0xFFFFF8F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead
                                    ? const Color(0xFFEDEDED)
                                    : const Color(0xFFFFB89A),
                                width: isRead ? 0.5 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: type == 'nouvelle_commande'
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFFFF3EE),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      NotificationService.iconForType(type),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              data['titre'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: const Color(0xFF1A1A1A),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            NotificationService.timeAgo(ts),
                                            style: const TextStyle(
                                              color: Color(0xFFAAAAAA),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        data['corps'] ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6B35),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
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

  // ── AVATAR MENU ────────────────────────────────────────────────────────────

  Widget _buildAvatarMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 8,
      onSelected: (value) async {
        if (value == 'profil') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfilGerantScreen(user: widget.user),
            ),
          );
        } else if (value == 'deconnexion') {
          await ref.read(authProvider.notifier).logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profil',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFFFF6B35),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mon profil',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'deconnexion',
          height: 48,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Se déconnecter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
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
              fontSize: 15,
            ),
          ),
        ),
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

  // ── JOURS ──────────────────────────────────────────────────────────────────

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

  // ── EMPTY DAY ──────────────────────────────────────────────────────────────

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

  // ── CONTENU MENU ───────────────────────────────────────────────────────────

  Widget _buildMenuContent(String menuId, Map<String, dynamic> menuData) {
    final actif = menuData['actif'] ?? true;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isPastDay
                ? null
                : () => _firestore.collection('menus').doc(menuId).update({
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
          if (_isPastDay) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text(
                    'Jour passé — modification impossible',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '🌅',
            'Petit déjeuner',
            'petitDej',
            (menuData['petitDej'] as List?)?.cast<String>() ?? [],
            'petit_dejeuner',
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '☀️',
            'Déjeuner',
            'dejeuner',
            (menuData['dejeuner'] as List?)?.cast<String>() ?? [],
            'dejeuner',
          ),
          const SizedBox(height: 12),
          _buildSlot(
            menuId,
            '🌙',
            'Dîner',
            'diner',
            (menuData['diner'] as List?)?.cast<String>() ?? [],
            'diner',
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
              onPressed: _isPastDay ? null : () => _deleteMenu(menuId),
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

  // ── SLOT ───────────────────────────────────────────────────────────────────

  Widget _buildSlot(
    String menuId,
    String emoji,
    String titre,
    String field,
    List<String> platsIds,
    String categorie,
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
          ...platsIds.map((pid) => _buildPlatInSlot(menuId, field, pid)),
          if (!_isPastDay)
            GestureDetector(
              onTap: () =>
                  _showAddPlatToSlot(menuId, field, platsIds, categorie),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFB89A),
                    width: 1.5,
                  ),
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
        final disponible = data['disponible'] == true;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: disponible
                ? const Color(0xFFF5F0EB)
                : const Color(0xFFFEF2F2),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['nom'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!disponible)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Indispo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${data['prix'] ?? 0} FCFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: disponible
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isPastDay)
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

  // ── AJOUTER PLAT AU SLOT ───────────────────────────────────────────────────

  void _showAddPlatToSlot(
    String menuId,
    String field,
    List<String> existing,
    String categorie,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('plats')
              .where('disponible', isEqualTo: true)
              .where('categorie', isEqualTo: categorie)
              .snapshots(),
          builder: (_, snap) {
            final docs =
                snap.data?.docs
                    .where((d) => !existing.contains(d.id))
                    .toList() ??
                [];

            const labels = {
              'petit_dejeuner': '🌅 Petit déjeuner',
              'dejeuner': '☀️ Déjeuner',
              'diner': '🌙 Dîner',
            };

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ajouter au menu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              labels[categorie] ?? categorie,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB0B0B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${docs.length} plat(s)',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                if (docs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🍽️', style: TextStyle(fontSize: 40)),
                            SizedBox(height: 12),
                            Text(
                              'Aucun plat disponible\ndans cette catégorie',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF8A8A8A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () async {
                            await _firestore
                                .collection('menus')
                                .doc(menuId)
                                .update({
                                  field: FieldValue.arrayUnion([docs[i].id]),
                                });
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7F4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _getEmoji(data['categorie'] ?? ''),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['nom'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${data['prix']} FCFA',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFFF6B35),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFFF6B35),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
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

  String _getEmoji(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'petit_dejeuner':
        return '🌅';
      case 'dejeuner':
        return '☀️';
      case 'diner':
        return '🌙';
      case 'boissons':
        return '🥤';
      default:
        return '🍽️';
    }
  }
}
