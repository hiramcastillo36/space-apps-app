import 'package:flutter/material.dart';


/// --- Datos (en español) ---
const List<String> actividades = [
  "Fútbol",
  "Correr al aire libre",
  "Ciclismo",
  "Caminatas o senderismo",
  "Voleibol (de playa o cancha)",
  "Yoga al aire libre",
  "Tai chi",
  "Picnic en el parque",
  "Leer al aire libre",
  "Meditación en la naturaleza",
  "Pasear al perro",
  "Jugar con frisbee",
  "Volar cometas",
  "Juegos infantiles (escondidas, atrapadas, etc.)",
  "Observación de aves",
  "Fotografía de naturaleza",
  "Ejercicio funcional (lagartijas, abdominales, etc.)",
  "Bailar en exteriores",
  "Estiramientos o calentamiento",
  "Jardinería comunitaria",
  "Reuniones familiares en parques",
  "Fogatas o parrilladas",
  "Ver el amanecer o atardecer",
  "Contemplación de paisajes",
  "Clases grupales en plazas (zumba, fitness)",
  "Eventos comunitarios al aire libre",
  "Cine al aire libre (proyecciones vecinales)",
  "Tocar instrumentos o cantar al aire libre",
  "Pintar o dibujar en la naturaleza",
  "Turismo o caminatas urbanas"
];

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final Set<int> _favoritos = {};
  int _currentTab = 1;

  @override
  Widget build(BuildContext context) {
    final topGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFEAF0FF),
        const Color(0xFFDFF3FF).withOpacity(0.85),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: Stack(
        children: [
          // --- “burbujas” decorativas al fondo (quedan detrás del ListView) ---
          Positioned(
            top: -80,
            left: -60,
            child: _bubble(160, const Color(0xFFBFD4FF).withOpacity(.25)),
          ),
          Positioned(
            top: 140,
            right: -40,
            child: _bubble(110, const Color(0xFFC8F0FF).withOpacity(.25)),
          ),
          Positioned(
            bottom: 110,
            left: -30,
            child: _bubble(90, const Color(0xFFDAC7FF).withOpacity(.22)),
          ),

          // --- Contenido scrollable ---
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          "Más actividades",
                          style: TextStyle(
                            color: const Color(0xFF2E7CE6),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: actividades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final actividad = actividades[index];
                    final isFav = _favoritos.contains(index);
                    return _GradientCardTile(
                      title: actividad,
                      gradient: topGradient,
                      icon: _iconForActivity(actividad),
                      isFavorite: isFav,
                      onTap: () {
                        // Aquí podrías navegar a detalle si lo deseas.
                      },
                      onFavoriteToggle: () {
                        setState(() {
                          if (isFav) {
                            _favoritos.remove(index);
                          } else {
                            _favoritos.add(index);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              // espacio para que no lo tape la barra inferior
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),

      // --- Barra inferior redondeada con degradado ---
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEAF0FF), Color(0xFFDFF3FF)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  selected: _currentTab == 0,
                  onTap: () => setState(() => _currentTab = 0),
                ),
                _NavItem(
                  label: 'Oliv',
                  icon: Icons.circle_outlined,
                  selected: _currentTab == 1,
                  onTap: () => setState(() => _currentTab = 1),
                ),
                _NavItem(
                  label: 'Profile',
                  icon: Icons.person_rounded,
                  selected: _currentTab == 2,
                  onTap: () => setState(() => _currentTab = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ícono aproximado según el texto (no requiere dependencias externas)
  IconData _iconForActivity(String name) {
    final n = name.toLowerCase();

    if (n.contains('fútbol')) return Icons.sports_soccer;
    if (n.contains('correr')) return Icons.directions_run_rounded;
    if (n.contains('cicl')) return Icons.directions_bike_rounded;
    if (n.contains('sender') || n.contains('caminatas')) return Icons.hiking_rounded;
    if (n.contains('voleibol')) return Icons.sports_volleyball_rounded;
    if (n.contains('yoga') || n.contains('meditación')) return Icons.self_improvement_rounded;
    if (n.contains('tai chi')) return Icons.balance_rounded;
    if (n.contains('picnic')) return Icons.outdoor_grill_rounded;
    if (n.contains('leer')) return Icons.menu_book_rounded;
    if (n.contains('perro')) return Icons.pets_rounded;
    if (n.contains('frisbee')) return Icons.sports_handball_rounded;
    if (n.contains('cometas') || n.contains('volar')) return Icons.air_rounded;
    if (n.contains('juegos infantiles')) return Icons.sports_kabaddi_rounded;
    if (n.contains('aves')) return Icons.visibility_rounded;
    if (n.contains('fotografía')) return Icons.photo_camera_rounded;
    if (n.contains('ejercicio')) return Icons.fitness_center_rounded;
    if (n.contains('bailar')) return Icons.music_note_rounded;
    if (n.contains('estiramientos') || n.contains('calentamiento')) return Icons.accessibility_new_rounded;
    if (n.contains('jardinería')) return Icons.local_florist_rounded;
    if (n.contains('reuniones familiares')) return Icons.groups_rounded;
    if (n.contains('fogatas') || n.contains('parrilladas')) return Icons.local_fire_department_rounded;
    if (n.contains('amanecer') || n.contains('atardecer')) return Icons.wb_twighlight; // puede no estar en todas las versiones
    if (n.contains('paisajes')) return Icons.terrain_rounded;
    if (n.contains('zumba') || n.contains('clases grupales'))return Icons.sports_gymnastics_rounded;
    if (n.contains('eventos comunitarios')) return Icons.event_rounded;
    if (n.contains('cine')) return Icons.movie_rounded;
    if (n.contains('instrumentos') || n.contains('cantar')) return Icons.mic_rounded;
    if (n.contains('pintar') || n.contains('dibujar')) return Icons.brush_rounded;
    if (n.contains('turismo') || n.contains('urbanas')) return Icons.directions_walk_rounded;

    return Icons.sports_rounded;
  }

  Widget _bubble(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.35),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
      );
}

/// --- Tarjeta con degradado + corazón ---
class _GradientCardTile extends StatelessWidget {
  const _GradientCardTile({
    required this.title,
    required this.gradient,
    required this.icon,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final String title;
  final Gradient gradient;
  final IconData icon;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: const Color(0xFF444B59)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444B59),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onFavoriteToggle,
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? const Color(0xFF444B59) : const Color(0xFF444B59),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// --- Item de navegación inferior ---
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2E7CE6) : const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
