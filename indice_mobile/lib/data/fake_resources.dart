import '../models/level.dart';
import '../models/resource.dart';

// Données factices en attendant l'API du backend.
const fakeResources = [
  Resource(
    title: 'Qu’est-ce qu’un ETF ?',
    description: 'Découvrez le fonctionnement des fonds indiciels cotés.',
    duration: '5 min',
    level: Level.beginner,
    isFavorite: true,
  ),
  Resource(
    title: 'Comprendre les frais',
    description: 'Les différents frais d’un ETF et leur impact dans le temps.',
    duration: '7 min',
    level: Level.beginner,
    isFavorite: false,
  ),
  Resource(
    title: 'La diversification',
    description: 'Pourquoi répartir son investissement sur plusieurs actifs.',
    duration: '4 min',
    level: Level.intermediate,
    isFavorite: false,
  ),
  Resource(
    title: 'Lire une fiche ETF',
    description: 'Indice suivi, encours, frais : les informations clés.',
    duration: '6 min',
    level: Level.intermediate,
    isFavorite: true,
  ),
  Resource(
    title: 'Réplication physique ou synthétique',
    description: 'Les deux façons pour un ETF de suivre son indice.',
    duration: '9 min',
    level: Level.experienced,
    isFavorite: false,
  ),
  Resource(
    title: 'L’écart de suivi',
    description: 'Mesurer la différence entre un ETF et son indice.',
    duration: '8 min',
    level: Level.professional,
    isFavorite: false,
  ),
];
