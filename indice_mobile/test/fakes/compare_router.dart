import 'package:go_router/go_router.dart';
import 'package:indice_mobile/screens/compare/etf_comparison_screen.dart';
import 'package:indice_mobile/screens/compare/etf_picker_screen.dart';

GoRouter buildCompareRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/compare/comparison',
      builder: (_, state) =>
          EtfComparisonScreen(etfA: state.uri.queryParameters['etfA']),
      routes: [
        GoRoute(
          path: 'etf-picker',
          builder: (_, state) => EtfPickerScreen(
            slot: EtfSlot.values.byName(state.uri.queryParameters['slot']!),
            excludedTicker: state.uri.queryParameters['exclude'],
          ),
        ),
      ],
    ),
  ],
);
