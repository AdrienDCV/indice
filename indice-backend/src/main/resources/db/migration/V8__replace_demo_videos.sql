-- Remplace les vidéos de démonstration de V7 par des vidéos de La finance pour tous,
-- publiées sur sa chaîne YouTube officielle, et complète leur présentation.

UPDATE resource
SET media_url = 'https://www.youtube.com/watch?v=lA6b8tckrQQ',
    duration_minutes = 1,
    content = 'Cette courte vidéo présente le principe d’un ETF (Exchange Traded Fund), aussi appelé tracker ou fonds indiciel coté. Le texte ci-dessous reprend l’essentiel et le complète.

Un ETF est un fonds d’investissement qui cherche à reproduire l’évolution d’un indice. Un indice mesure l’évolution d’un ensemble de titres : le CAC 40 regroupe 40 grandes entreprises cotées à Paris, le MSCI World plus d’un millier d’entreprises de pays développés. Acheter une part d’un ETF revient donc à investir, en une seule fois, dans tous les titres de l’indice, ou dans un ensemble qui en reproduit l’évolution.

Contrairement à la plupart des fonds, un ETF est coté en Bourse : son prix évolue tout au long de la séance et l’on peut acheter ou vendre des parts à tout moment pendant les heures d’ouverture du marché, comme une action.

Il existe des ETF sur de nombreux types d’actifs : actions, obligations, matières premières, ou thèmes plus étroits (un secteur, une technologie…). Comme ils suivent un indice au lieu de chercher à le battre, leurs frais courants sont en général plus faibles que ceux des fonds gérés activement.

Un ETF n’est pas sans risque. Il suit son indice à la baisse comme à la hausse, et le capital investi n’est pas garanti. Si l’indice est exprimé dans une autre devise que l’euro, les variations de change s’ajoutent à celles des titres. Certains ETF, dits à effet de levier ou inverses, amplifient ou inversent les variations de leur indice : leur fonctionnement est plus complexe et leurs risques plus élevés.

En France, un ETF peut être éligible au plan d’épargne en actions (PEA) s’il respecte les règles de cette enveloppe, notamment investir plus de 75 % de ses actifs en actions d’entreprises européennes. La ressource « Réplication physique ou synthétique » explique comment certains ETF éligibles au PEA suivent malgré tout des indices mondiaux.

Source : La finance pour tous, vidéo publiée en juin 2025 sur sa chaîne YouTube officielle. La finance pour tous est le nom d’usage de l’Institut pour l’éducation financière du public (IEFP), une association d’intérêt général créée en 2006 à l’initiative de l’Autorité des marchés financiers (AMF). Elle est agréée par le ministère de l’Éducation nationale et soutenue notamment par la Banque de France et l’AMF.'
WHERE id = '00000000-0000-4000-8000-000000000001';

UPDATE resource
SET media_url = 'https://www.youtube.com/watch?v=eq537XjLofw',
    duration_minutes = 2,
    content = 'Cette vidéo explique le principe de la diversification. Le texte ci-dessous reprend l’essentiel et le complète.

Diversifier, c’est répartir un investissement entre plusieurs actifs, pour qu’une mauvaise nouvelle sur l’un d’eux n’ait qu’un effet limité sur l’ensemble. C’est le sens de l’expression « ne pas mettre tous ses œufs dans le même panier ».

On peut diversifier de plusieurs façons : entre plusieurs entreprises, entre plusieurs secteurs économiques (santé, énergie, technologie…), entre plusieurs zones géographiques, ou entre plusieurs classes d’actifs (actions, obligations, immobilier…). Un ETF qui suit un large indice apporte déjà une diversification entre de nombreuses entreprises, avec un seul produit.

La diversification est d’autant plus efficace que les actifs n’évoluent pas de la même façon. C’est ce que mesure la corrélation : proche de 1, deux actifs évoluent dans le même sens ; proche de 0, leurs évolutions sont peu liées ; proche de -1, elles vont en sens inverse. Le module Comparer affiche la corrélation entre deux ETF.

La diversification a ses limites. Elle réduit le risque propre à une entreprise ou à un secteur, mais pas le risque qui touche l’ensemble des marchés : lors d’une crise générale, la plupart des actifs peuvent baisser en même temps. Détenir plusieurs ETF ne garantit pas non plus d’être diversifié, s’ils suivent des indices proches ou contiennent les mêmes entreprises. Enfin, un indice large peut rester concentré, par exemple sur un pays ou un secteur qui y pèse lourd.

Source : La finance pour tous, vidéo publiée en avril 2026 sur sa chaîne YouTube officielle. La finance pour tous est le nom d’usage de l’Institut pour l’éducation financière du public (IEFP), une association d’intérêt général créée en 2006 à l’initiative de l’Autorité des marchés financiers (AMF). Elle est agréée par le ministère de l’Éducation nationale et soutenue notamment par la Banque de France et l’AMF.'
WHERE id = '00000000-0000-4000-8000-000000000003';

UPDATE resource
SET media_url = 'https://www.youtube.com/watch?v=rpcUsAuEE2Q',
    duration_minutes = 2,
    content = 'Cette vidéo compare les deux méthodes qu’utilise un ETF pour suivre son indice. Le texte ci-dessous reprend l’essentiel et le complète.

En réplication physique, l’ETF achète les titres qui composent l’indice. Il peut les détenir tous, dans les mêmes proportions que l’indice (réplication complète), ou seulement une partie choisie pour en reproduire l’évolution (échantillonnage), ce qui est courant pour les indices qui comptent beaucoup de titres. Certains ETF physiques prêtent une partie de leurs titres à d’autres établissements contre rémunération, ce qui ajoute un risque si l’emprunteur fait défaut.

En réplication synthétique, l’ETF détient un panier de titres qui peut être différent de l’indice. Il conclut avec une banque un contrat d’échange, appelé swap : l’ETF lui verse la performance de son panier et reçoit en échange celle de l’indice. Le risque principal est que la banque ne puisse pas honorer ce contrat. La réglementation européenne des fonds (UCITS) limite ce risque : l’exposition à une même banque au titre de ces contrats ne peut pas dépasser 10 % des actifs du fonds.

La vidéo prend l’exemple du PEA. Cette enveloppe impose de détenir majoritairement des actions européennes. Grâce à la réplication synthétique, un ETF composé d’actions européennes peut tout de même suivre un indice étranger, comme le S&P 500 ou le MSCI World, en échangeant sa performance.

Aucune des deux méthodes n’est meilleure dans l’absolu : elles reposent sur des mécanismes et des risques différents. La méthode de réplication figure dans le document d’informations clés (DIC) de chaque ETF. La ressource « L’écart de suivi » explique comment mesurer à quel point un ETF suit fidèlement son indice.

Source : La finance pour tous, vidéo publiée en août 2026 sur sa chaîne YouTube officielle. La finance pour tous est le nom d’usage de l’Institut pour l’éducation financière du public (IEFP), une association d’intérêt général créée en 2006 à l’initiative de l’Autorité des marchés financiers (AMF). Elle est agréée par le ministère de l’Éducation nationale et soutenue notamment par la Banque de France et l’AMF.'
WHERE id = '00000000-0000-4000-8000-000000000005';
