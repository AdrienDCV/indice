import '../models/level.dart';
import '../models/resource.dart';
import '../models/resource_type.dart';

// Données factices en attendant l'API du backend.
// Vidéos de démonstration publiques (Flutter et MDN), sans lien avec les titres.
const fakeResources = [
  Resource(
    title: 'Qu’est-ce qu’un ETF ?',
    description: 'Découvrez le fonctionnement des fonds indiciels cotés.',
    content:
        'Cette vidéo présente le principe d’un ETF (Exchange Traded Fund), '
        'ou fonds indiciel coté.\n\n'
        'Vous y verrez comment un ETF réplique la performance d’un indice, '
        'comme le CAC 40 ou le MSCI World, et comment il s’échange en Bourse '
        'tout au long de la journée, à la manière d’une action.',
    type: ResourceType.video,
    duration: '5 min',
    level: Level.beginner,
    isFavorite: true,
    videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
  ),
  Resource(
    title: 'Comprendre les frais',
    description: 'Les différents frais d’un ETF et leur impact dans le temps.',
    content:
        'Lorsqu’on découvre les ETF, on entend souvent qu’ils sont « peu '
        'chers ». C’est généralement vrai par rapport à d’autres fonds, '
        'mais un ETF n’est pas gratuit pour autant. Plusieurs frais '
        's’appliquent, à des moments différents, et il est utile de savoir '
        'les distinguer.\n\n'
        'Les premiers sont les frais courants, souvent désignés par leur '
        'abréviation anglaise TER (Total Expense Ratio). Ils couvrent la '
        'gestion du fonds, le calcul de l’indice, la conservation des '
        'titres ou encore les frais administratifs. Ils s’expriment en '
        'pourcentage annuel de l’encours : un TER de 0,20 % signifie que '
        '0,20 % de la valeur du fonds est prélevé chaque année.\n\n'
        'Ces frais ne sont jamais facturés directement : ils sont déduits '
        'progressivement de la valeur de l’ETF. On ne les voit donc pas '
        'passer sur son relevé de compte, mais ils réduisent la performance '
        'obtenue, jour après jour.\n\n'
        'Viennent ensuite les frais de courtage. Ils ne dépendent pas de '
        'l’ETF lui-même mais de l’intermédiaire utilisé pour acheter ou '
        'vendre en Bourse. Selon les cas, il peut s’agir d’un montant fixe '
        'par ordre, d’un pourcentage du montant échangé, ou d’une '
        'combinaison des deux.\n\n'
        'Il faut aussi tenir compte de la fourchette de prix, appelée « '
        'spread ». À un instant donné, le prix auquel on peut acheter une '
        'part est légèrement supérieur au prix auquel on peut la vendre. '
        'Cet écart représente un coût implicite à chaque transaction. Il '
        'est en général plus faible pour les ETF dont les volumes d’échange '
        'sont importants.\n\n'
        'Enfin, certains intermédiaires appliquent des frais de tenue de '
        'compte ou de garde, facturés chaque année quel que soit le nombre '
        'd’opérations. Ils varient fortement d’un établissement à l’autre '
        'et selon le type de compte.\n\n'
        'Pourquoi tous ces frais comptent-ils ? Parce que leur effet '
        's’accumule dans le temps. Prenons un exemple purement illustratif '
        ': 10 000 € placés pendant 20 ans sur un indice qui progresserait '
        'de 5 % par an. Avec 0,20 % de frais annuels, le capital '
        'atteindrait environ 25 500 €. Avec 0,70 % de frais, il atteindrait '
        'environ 23 200 €. Une différence de 0,5 point par an représente '
        'ainsi plus de 2 000 € au bout de 20 ans.\n\n'
        'Les frais ne sont toutefois qu’un critère parmi d’autres. L’indice '
        'suivi, la méthode de réplication ou la qualité du suivi de '
        'l’indice sont tout aussi importants pour comprendre un ETF. Ces '
        'notions sont présentées dans les autres ressources du module '
        'Apprendre.',
    type: ResourceType.article,
    duration: '7 min',
    level: Level.beginner,
    isFavorite: false,
  ),
  Resource(
    title: 'La diversification',
    description: 'Pourquoi répartir son investissement sur plusieurs actifs.',
    content:
        'Cette vidéo explique la notion de diversification : répartir un '
        'investissement entre plusieurs entreprises, secteurs ou zones '
        'géographiques.\n\n'
        'Elle montre comment un ETF, en regroupant de nombreux titres, '
        'permet d’obtenir cette répartition avec un seul produit.',
    type: ResourceType.video,
    duration: '4 min',
    level: Level.intermediate,
    isFavorite: false,
    videoUrl:
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  ),
  Resource(
    title: 'Lire une fiche ETF',
    description: 'Indice suivi, encours, frais : les informations clés.',
    content:
        'Chaque ETF dispose d’une fiche descriptive, publiée par la société '
        'qui le gère. On y trouve, en une ou deux pages, l’essentiel de ce '
        'qu’il faut savoir sur le fonds. Au premier abord, elle peut '
        'paraître dense : voici comment la lire, rubrique par rubrique.\n\n'
        'Le premier élément est le nom de l’ETF, souvent long et codé. Il '
        'contient en général le nom de l’émetteur, l’indice suivi et '
        'quelques indications techniques, comme « Acc » pour un fonds '
        'capitalisant ou « Dist » pour un fonds distribuant. Pour '
        'identifier un ETF sans ambiguïté, on utilise plutôt son code ISIN, '
        'une suite de 12 caractères unique à chaque fonds.\n\n'
        'Vient ensuite l’indice de référence : c’est ce que l’ETF cherche à '
        'reproduire. Un ETF sur le MSCI World suit ainsi plusieurs '
        'centaines de grandes entreprises de pays développés, tandis qu’un '
        'ETF sur le CAC 40 suit les 40 principales capitalisations de la '
        'Bourse de Paris. Comprendre l’indice, c’est comprendre dans quoi '
        'l’on est exposé.\n\n'
        'L’encours, aussi appelé actif sous gestion, indique le montant '
        'total investi dans le fonds. C’est un indicateur de la taille de '
        'l’ETF : un encours élevé est souvent associé à des échanges plus '
        'nombreux sur le marché.\n\n'
        'Les frais courants (TER) précisent le coût annuel du fonds, '
        'exprimé en pourcentage. Ils sont détaillés dans la ressource « '
        'Comprendre les frais ».\n\n'
        'La méthode de réplication indique comment l’ETF suit son indice : '
        'soit en détenant réellement les titres (réplication physique), '
        'soit au moyen d’un contrat d’échange avec une banque (réplication '
        'synthétique).\n\n'
        'La politique de distribution précise ce que deviennent les '
        'dividendes versés par les entreprises de l’indice. Un ETF '
        'distribuant les reverse périodiquement aux porteurs de parts ; un '
        'ETF capitalisant les réinvestit automatiquement dans le fonds.\n\n'
        'La fiche mentionne également la devise du fonds, la date de '
        'création, les places de cotation et, le cas échéant, l’éligibilité '
        'à certaines enveloppes fiscales. Elle renvoie enfin au document '
        'd’informations clés (DIC), document réglementaire qui présente '
        'notamment un indicateur de risque gradué de 1 à 7 et des scénarios '
        'de performance.\n\n'
        'Avec ces repères, il devient possible de comparer plusieurs ETF '
        'sur des critères objectifs. C’est précisément l’objet du module '
        'Comparer de l’application.',
    type: ResourceType.article,
    duration: '6 min',
    level: Level.intermediate,
    isFavorite: true,
  ),
  Resource(
    title: 'Réplication physique ou synthétique',
    description: 'Les deux façons pour un ETF de suivre son indice.',
    content:
        'Cette vidéo compare les deux méthodes de réplication.\n\n'
        'En réplication physique, l’ETF détient réellement les titres de '
        'l’indice. En réplication synthétique, il utilise un contrat d’échange '
        '(swap) avec une banque pour obtenir la performance de l’indice.',
    type: ResourceType.video,
    duration: '9 min',
    level: Level.experienced,
    isFavorite: false,
    videoUrl: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
  ),
  Resource(
    title: 'L’écart de suivi',
    description: 'Mesurer la différence entre un ETF et son indice.',
    content:
        'Un ETF a pour objectif de reproduire la performance d’un indice. '
        'En pratique, il n’y parvient jamais parfaitement : sa performance '
        's’écarte toujours un peu de celle de l’indice. Deux indicateurs '
        'permettent de mesurer cet écart, et ils ne disent pas la même '
        'chose.\n\n'
        'Le premier est l’écart de suivi, ou tracking difference. Il '
        'correspond simplement à la différence entre la performance de '
        'l’ETF et celle de son indice sur une période donnée, le plus '
        'souvent une année civile. Si l’indice a progressé de 10,00 % et '
        'l’ETF de 9,80 %, l’écart de suivi est de −0,20 %.\n\n'
        'Le second est l’erreur de suivi, ou tracking error. Elle mesure la '
        'régularité de cet écart : il s’agit de la volatilité, exprimée sur '
        'une base annuelle, des différences de performance observées entre '
        'l’ETF et l’indice, par exemple jour après jour. Une erreur de '
        'suivi faible signifie que l’ETF colle de près à son indice au '
        'quotidien, même si un écart de suivi peut exister sur l’année.\n\n'
        'Plusieurs facteurs expliquent ces écarts. Le premier est la '
        'présence des frais courants, qui réduisent mécaniquement la '
        'performance du fonds. À frais égaux, deux ETF peuvent pourtant '
        'afficher des écarts de suivi différents, car d’autres éléments '
        'entrent en jeu.\n\n'
        'Les coûts de transaction en font partie : lorsque la composition '
        'de l’indice change, le gérant doit acheter et vendre des titres, '
        'ce qui génère des frais. La gestion de la trésorerie joue aussi un '
        'rôle : les dividendes perçus et les flux de souscription ne sont '
        'pas toujours investis instantanément, ce qui crée un léger '
        'décalage.\n\n'
        'La fiscalité des dividendes est un autre facteur important. Les '
        'indices dits « nets » intègrent une retenue à la source standard '
        'sur les dividendes ; selon sa structure et son domicile, un ETF '
        'peut supporter une retenue différente, ce qui crée un écart '
        'positif ou négatif.\n\n'
        'Enfin, certains ETF pratiquent le prêt de titres : ils prêtent une '
        'partie des actions détenues contre rémunération. Les revenus '
        'correspondants peuvent compenser une partie des frais, au prix '
        'd’un risque de contrepartie encadré par des garanties.\n\n'
        'Ces mécanismes expliquent qu’un écart de suivi puisse être '
        'légèrement positif certaines années : l’ETF fait alors mieux que '
        'son indice, ce qui ne signifie pas pour autant qu’il le '
        'surperforme durablement.\n\n'
        'Pour analyser la qualité de réplication d’un ETF, il est donc '
        'utile d’observer ces deux indicateurs sur plusieurs années plutôt '
        'que sur une seule période. Les émetteurs les publient généralement '
        'dans leurs rapports annuels et sur leurs fiches produits.',
    type: ResourceType.article,
    duration: '8 min',
    level: Level.professional,
    isFavorite: false,
  ),
];
