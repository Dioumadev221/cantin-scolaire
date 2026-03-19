import 'package:cantine_scolaire/features/auth/presentation/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/domain/entities/user_entity.dart';

class CommandesScreen extends StatefulWidget {
  final UserEntity user;
  const CommandesScreen({super.key, required this.user});
  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  late final TabController _tabCtrl;

  // Filtres onglet "Aujourd'hui"
  String _filter = 'Toutes';
  final _filters = ['Toutes', 'Reçues', 'En cuisine', 'Prêtes', 'Récupérées', 'Annulées'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Helpers date ────────────────────────────────────────────────────────────

  bool _isToday(Timestamp? ts) {
    if (ts == null) return false;
    final dt = ts.toDate();
    final now = DateTime.now();
    return dt.day == now.day && dt.month == now.month && dt.year == now.year;
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    _buildStats(),
    // Tabs
    Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: const Color(0xFFFF6B35),
        unselectedLabelColor: const Color(0xFF8A8A8A),
        indicatorColor: const Color(0xFFFF6B35),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: "Aujourd'hui"),
          Tab(text: 'Historique'),
        ],
      ),
    ),
    Expanded(
      child: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildAujourdhuiTab(),
          _buildHistoriqueTab(),
        ],
      ),
    ),
  ]);

  // ── STATS BAR ────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('commandes').snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final todayDocs = docs.where((d) =>
            _isToday((d.data() as Map)['createdAt'] as Timestamp?)).toList();
        final actives = todayDocs.where((d) =>
            ['recue', 'en_cuisine'].contains((d.data() as Map)['statut'])).length;
        final recettes = todayDocs.fold<double>(0, (s, d) =>
            s + ((d.data() as Map)['montantTotal'] ?? 0).toDouble());

        return Container(
          color: const Color(0xFFFF6B35),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('En direct',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 10),
            _pill('$actives', 'actives'),
            const SizedBox(width: 8),
            _pill('${todayDocs.length}', "aujourd'hui"),
            const SizedBox(width: 8),
            _pill('${recettes.toStringAsFixed(0)} F', 'recettes'),
          ]),
        );
      },
    );
  }

  Widget _pill(String val, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.white12, borderRadius: BorderRadius.circular(20)),
    child: Text('$val $label',
        style: const TextStyle(color: Colors.white, fontSize: 11)),
  );

  // ══════════════════════════════════════════════════════════════════════════════
  // ONGLET AUJOURD'HUI
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildAujourdhuiTab() {
    return Column(children: [
      _buildFilters(),
      Expanded(child: _buildTodayList()),
    ]);
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final active = _filters[i] == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = _filters[i]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1a1a1a) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? const Color(0xFF1a1a1a) : const Color(0xFFEDEDED)),
              ),
              child: Text(_filters[i], style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: active ? Colors.white : const Color(0xFF6B7280))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('commandes').snapshots(),
      builder: (_, snap) {
        var docs = List.from(snap.data?.docs ?? []);

        // Filtrer aujourd'hui uniquement
        docs = docs.where((d) =>
            _isToday((d.data() as Map)['createdAt'] as Timestamp?)).toList();

        // Tri décroissant
        docs.sort((a, b) {
          final ta = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tb.compareTo(ta);
        });

        // Filtre statut
        if (_filter != 'Toutes') {
          final m = {
            'Reçues': 'recue', 'En cuisine': 'en_cuisine',
            'Prêtes': 'prete', 'Récupérées': 'recuperee', 'Annulées': 'annulee',
          };
          final s = m[_filter];
          if (s != null) docs = docs.where((d) => (d.data() as Map)['statut'] == s).toList();
        }

        if (docs.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📭', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                _filter == 'Toutes'
                    ? 'Aucune commande aujourd\'hui'
                    : 'Aucune commande "$_filter" aujourd\'hui',
                style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 14),
              ),
            ],
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _CommandeCard(
              id: docs[i].id, data: data, onChangeStatut: _changeStatut);
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // ONGLET HISTORIQUE
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildHistoriqueTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('commandes').snapshots(),
      builder: (_, snap) {
        var docs = List.from(snap.data?.docs ?? []);

        // Tout sauf aujourd'hui
        docs = docs.where((d) =>
            !_isToday((d.data() as Map)['createdAt'] as Timestamp?)).toList();

        docs.sort((a, b) {
          final ta = ((a.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = ((b.data() as Map)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tb.compareTo(ta);
        });

        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🗂️', style: TextStyle(fontSize: 52)),
              SizedBox(height: 12),
              Text('Aucun historique disponible',
                  style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 14)),
              SizedBox(height: 6),
              Text('Les commandes passées apparaîtront ici',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12)),
            ],
          ));
        }

        // Grouper par date
        final grouped = <String, List<dynamic>>{};
        for (final doc in docs) {
          final ts = (doc.data() as Map)['createdAt'] as Timestamp?;
          final key = ts != null
              ? _dateLabel(ts.toDate())
              : 'Date inconnue';
          grouped.putIfAbsent(key, () => []).add(doc);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: grouped.length,
          itemBuilder: (_, i) {
            final entry = grouped.entries.elementAt(i);
            final dayDocs = entry.value;
            final totalJour = dayDocs.fold<double>(0, (s, d) =>
                s + ((d.data() as Map)['montantTotal'] ?? 0).toDouble());

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // En-tête jour
              Padding(
                padding: EdgeInsets.only(bottom: 10, top: i == 0 ? 0 : 8),
                child: Row(children: [
                  Expanded(
                    child: Text(entry.key, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${totalJour.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                            color: Color(0xFF16A34A), fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('${dayDocs.length} cmd',
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              // Cards du jour (compactes)
              ...dayDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _HistoriqueCard(data: data);
              }),
            ]);
          },
        );
      },
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == DateTime(yesterday.year, yesterday.month, yesterday.day)) {
      return 'Hier';
    }
    const months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  // ── CHANGER STATUT ────────────────────────────────────────────────────────────

  Future<void> _changeStatut(String id, Map<String, dynamic> data,
      String nouveauStatut) async {
    final etudiantId = data['etudiantId'] as String?;
    final numero = data['numero'] ?? '?';

    if (nouveauStatut == 'annulee' && etudiantId != null) {
      final montant = (data['montantTotal'] ?? 0).toDouble();
      await _db.collection('users').doc(etudiantId).update({
        'soldeWallet': FieldValue.increment(montant),
      });
    }

    await _db.collection('commandes').doc(id).update({
      'statut': nouveauStatut,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (etudiantId != null) {
      final details = (data['platsDetails'] as List?)?.cast<Map>() ?? [];
      final nomPlat = details.isNotEmpty
          ? details.map((d) => d['nom']).join(' + ')
          : (data['nomPlat'] ?? '');

      await NotificationService.notifierStatutCommande(
        etudiantId: etudiantId,
        commandeId: id,
        commandeNumero: numero,
        nouveauStatut: nouveauStatut,
        nomPlat: nomPlat,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE COMMANDE (active — avec actions)
// ─────────────────────────────────────────────────────────────────────────────
class _CommandeCard extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  final Future<void> Function(String, Map<String, dynamic>, String) onChangeStatut;

  const _CommandeCard({
    required this.id, required this.data, required this.onChangeStatut});

  @override
  State<_CommandeCard> createState() => _CommandeCardState();
}

class _CommandeCardState extends State<_CommandeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final statut = data['statut'] ?? 'recue';
    final numero = data['numero'] ?? '—';
    final etudiantNom = data['etudiantNom'] ?? '—';
    final montant = (data['montantTotal'] ?? 0).toDouble();
    final ts = data['createdAt'] as Timestamp?;
    final isBoisson = data['isBoisson'] == true;
    final details = (data['platsDetails'] as List?)?.cast<Map>() ?? [];
    final nbArticles = data['nbArticles'] as int? ?? 1;
    final nomPlat = data['nomPlat'] ?? '—';
    final si = _statutInfo(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEDED), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                  color: isBoisson ? const Color(0xFFEFF6FF) : const Color(0xFFFFF3EE),
                  borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(isBoisson ? '🥤' : '🍽️',
                  style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('#$numero', style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: si['bg'] as Color,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(si['label'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: si['fg'] as Color))),
              ]),
              Text(etudiantNom, style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 12)),
              Text(
                details.length > 1
                    ? '$nbArticles articles · $nomPlat'
                    : nomPlat,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B35)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${montant.toStringAsFixed(0)} F',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
              if (ts != null)
                Text(_timeAgo(ts.toDate()),
                    style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA))),
            ]),
          ]),
        ),

        // Voir plus détails panier
        if (details.length > 1) ...[
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8F7F4),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Text(d['emoji'] ?? '🍽️', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d['nom'] ?? '',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600))),
                    Text('×${d['quantite'] ?? 1}', style: const TextStyle(
                        fontSize: 11, color: Color(0xFFB0B0B0))),
                    const SizedBox(width: 10),
                    Text('${(d['sousTotal'] ?? 0).toStringAsFixed(0)} F',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700, color: Color(0xFFFF6B35))),
                  ]),
                )).toList(),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  _expanded ? 'Voir moins' : 'Voir plus · ${details.length} articles',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B35))),
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16, color: const Color(0xFFFF6B35)),
              ]),
            ),
          ),
        ],

        // Barre de progression
        if (statut != 'annulee') _buildProgress(statut, isBoisson),

        // Actions
        if (statut != 'recuperee' && statut != 'annulee')
          _buildActions(statut, isBoisson),
      ]),
    );
  }

  Widget _buildProgress(String statut, bool isBoisson) {
    final steps = isBoisson
        ? ['recue', 'prete', 'recuperee']
        : ['recue', 'en_cuisine', 'prete', 'recuperee'];
    final labels = isBoisson
        ? ['Reçue', 'Prête', 'Livrée']
        : ['Reçue', 'Cuisine', 'Prête', 'Livrée'];
    final idx = steps.indexOf(statut).clamp(0, steps.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(children: [
        Row(children: List.generate(steps.length, (i) {
          final done = i <= idx;
          return Expanded(child: Row(children: [
            Container(width: 18, height: 18,
              decoration: BoxDecoration(
                  color: done ? const Color(0xFF22C55E) : const Color(0xFFEDEDED),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: done ? const Color(0xFF22C55E) : const Color(0xFFDDDDDD),
                      width: 2)),
              child: done ? const Icon(Icons.check, size: 10, color: Colors.white) : null),
            if (i < steps.length - 1)
              Expanded(child: Container(height: 2,
                  color: i < idx ? const Color(0xFF22C55E) : const Color(0xFFEEEEEE))),
          ]));
        })),
        const SizedBox(height: 4),
        Row(children: List.generate(steps.length, (i) => Expanded(
          child: Text(labels[i],
            textAlign: i == 0 ? TextAlign.left
                : i == steps.length - 1 ? TextAlign.right : TextAlign.center,
            style: TextStyle(fontSize: 8,
                fontWeight: i <= idx ? FontWeight.w700 : FontWeight.w400,
                color: i <= idx ? const Color(0xFF22C55E) : const Color(0xFFCCCCCC))),
        ))),
      ]),
    );
  }

  Widget _buildActions(String statut, bool isBoisson) {
    String? nextStatut, nextLabel;
    if (isBoisson) {
      if (statut == 'recue' || statut == 'prete') {
        nextStatut = 'recuperee'; nextLabel = '✅ Livrée';
      }
    } else {
      if (statut == 'recue') { nextStatut = 'en_cuisine'; nextLabel = '👨‍🍳 En cuisine'; }
      else if (statut == 'en_cuisine') { nextStatut = 'prete'; nextLabel = '🔔 Marquer prête'; }
      else if (statut == 'prete') { nextStatut = 'recuperee'; nextLabel = '✅ Livrée'; }
    }

    return Container(
      decoration: const BoxDecoration(border: Border(
          top: BorderSide(color: Color(0xFFEDEDED), width: 0.5))),
      child: Row(children: [
        if (statut == 'recue' || statut == 'en_cuisine')
          Expanded(child: GestureDetector(
            onTap: () => widget.onChangeStatut(widget.id, widget.data, 'annulee'),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('❌ Annuler', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444)))))),
        if (nextStatut != null && (statut == 'recue' || statut == 'en_cuisine'))
          Container(width: 0.5, height: 36, color: const Color(0xFFEDEDED)),
        if (nextStatut != null)
          Expanded(child: GestureDetector(
            onTap: () => widget.onChangeStatut(widget.id, widget.data, nextStatut!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(nextLabel!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B35)))))),
      ]),
    );
  }

  Map<String, dynamic> _statutInfo(String s) {
    switch (s) {
      case 'recue':      return {'label':'⏳ Reçue',    'bg':const Color(0xFFFEF3C7),'fg':const Color(0xFFD97706)};
      case 'en_cuisine': return {'label':'👨‍🍳 En cuisine','bg':const Color(0xFFEFF6FF),'fg':const Color(0xFF2563EB)};
      case 'prete':      return {'label':'🔔 Prête !',  'bg':const Color(0xFFF0FDF4),'fg':const Color(0xFF16A34A)};
      case 'recuperee':  return {'label':'✅ Livrée',   'bg':const Color(0xFFF5F5F5),'fg':const Color(0xFF6B7280)};
      case 'annulee':    return {'label':'❌ Annulée',  'bg':const Color(0xFFFEE2E2),'fg':const Color(0xFFDC2626)};
      default:           return {'label':s,             'bg':const Color(0xFFF5F5F5),'fg':const Color(0xFF6B7280)};
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE HISTORIQUE (compacte, lecture seule)
// ─────────────────────────────────────────────────────────────────────────────
class _HistoriqueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoriqueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final statut = data['statut'] ?? '';
    final numero = data['numero'] ?? '—';
    final etudiantNom = data['etudiantNom'] ?? '—';
    final nomPlat = data['nomPlat'] ?? '—';
    final montant = (data['montantTotal'] ?? 0).toDouble();
    final ts = data['createdAt'] as Timestamp?;
    final si = _statutInfo(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEDED), width: 0.5)),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(
              color: (si['bg'] as Color).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(
              data['isBoisson'] == true ? '🥤' : '🍽️',
              style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('#$numero', style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: si['bg'] as Color,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(si['label'] as String,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: si['fg'] as Color))),
          ]),
          Text('$etudiantNom · $nomPlat',
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${montant.toStringAsFixed(0)} F',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          if (ts != null)
            Text(_fmt(ts.toDate()),
                style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA))),
        ]),
      ]),
    );
  }

  Map<String, dynamic> _statutInfo(String s) {
    switch (s) {
      case 'recue':      return {'label':'Reçue',    'bg':const Color(0xFFFEF3C7),'fg':const Color(0xFFD97706)};
      case 'en_cuisine': return {'label':'Cuisine',  'bg':const Color(0xFFEFF6FF),'fg':const Color(0xFF2563EB)};
      case 'prete':      return {'label':'Prête',    'bg':const Color(0xFFF0FDF4),'fg':const Color(0xFF16A34A)};
      case 'recuperee':  return {'label':'Livrée',   'bg':const Color(0xFFF5F5F5),'fg':const Color(0xFF6B7280)};
      case 'annulee':    return {'label':'Annulée',  'bg':const Color(0xFFFEE2E2),'fg':const Color(0xFFDC2626)};
      default:           return {'label':s,          'bg':const Color(0xFFF5F5F5),'fg':const Color(0xFF6B7280)};
    }
  }

  String _fmt(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}