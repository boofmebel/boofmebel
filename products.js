// Каталог с примерами. Менять цены/фото можно прямо здесь.
const PRODUCTS = [
  {
    id: "soho",
    name: "Диван Soho 3-х местный",
    category: "divan",
    badge: "Хит",
    price: 89000,
    oldPrice: 102000,
    short: "Съемные чехлы, глубокая посадка, спальное место 200×150 см",
    description:
      "Мягкий диван с модульной системой. Чехлы можно снять и почистить. Усиленный каркас и HR-пена — держит форму и комфорт.",
    images: [
      "images/soho-1.svg",
      "images/soho-2.svg"
    ],
    fabrics: [
      { id: "linen-ice", name: "Лён — ледяной", priceDelta: 0, color: "#cfd7df" },
      { id: "vel-soft", name: "Велюр — тёплый серый", priceDelta: 4000, color: "#b0a99f" },
      { id: "boucle-sand", name: "Букле — песочный", priceDelta: 7000, color: "#d7c7b0" }
    ],
    specs: {
      frame: "Берёзовая фанера + сухой брус",
      filler: "HR-пена 35/45 + холлофайбер",
      warranty: "3 года",
      cover: "Съёмные чехлы, сухая чистка"
    },
    dimensions: { width: 230, depth: 105, height: 90, sleep: "200×150", weight: 68 },
    reviews: [
      { author: "Марина", rating: 5, text: "Комфортный, ткань легко чистится, привезли за неделю.", date: "2025-10-01" },
      { author: "Игорь", rating: 4, text: "Брал в букле, выглядит богато. Подлокотники удобные.", date: "2025-10-12" }
    ]
  },
  {
    id: "loft-corner",
    name: "Угловой диван Loft",
    category: "uglovoy",
    badge: "Новинка",
    price: 94000,
    oldPrice: 112000,
    short: "Модульный угол, спальное место 210×155 см, ниша для белья",
    description:
      "Угловая компоновка с высокой опорой и поддержкой поясницы. Подойдёт для ежедневного сна. Ниша для белья в шезлонге.",
    images: [
      "images/loft-1.svg",
      "images/loft-2.svg"
    ],
    fabrics: [
      { id: "vel-deep", name: "Велюр — графит", priceDelta: 0, color: "#555" },
      { id: "linen-storm", name: "Лён — шторм", priceDelta: 3500, color: "#8a8f99" },
      { id: "eco-cream", name: "Эко-кожа — крем", priceDelta: 6000, color: "#f1e6d6" }
    ],
    specs: {
      frame: "Металлокаркас + берёзовый брус",
      filler: "Пружинный блок + HR-пена",
      warranty: "3 года",
      cover: "Несъёмные, пятновыводитель допустим"
    },
    dimensions: { width: 275, depth: 170, height: 92, sleep: "210×155", weight: 82 },
    reviews: [
      { author: "Светлана", rating: 5, text: "Мягкий, угол можно переставлять, ниша вместительная.", date: "2025-10-05" }
    ]
  },
  {
    id: "cozy-chair",
    name: "Кресло Cozy",
    category: "kreslo",
    badge: "Хит",
    price: 34000,
    oldPrice: 39000,
    short: "Кокон с опорой для спины и съёмной подушкой",
    description:
      "Компактное кресло для чтения и отдыха. Съёмная подушка, мягкие подлокотники, облегчённая рама для лёгкого переставления.",
    images: [
      "images/cozy-1.svg",
      "images/cozy-2.svg"
    ],
    fabrics: [
      { id: "boucle-milk", name: "Букле — молочный", priceDelta: 0, color: "#f3e9da" },
      { id: "vel-olive", name: "Велюр — олива", priceDelta: 1800, color: "#7a835c" }
    ],
    specs: {
      frame: "Фанера + берёзовый брус",
      filler: "HR-пена 38 + пуховый микс",
      warranty: "2 года",
      cover: "Съёмная подушка"
    },
    dimensions: { width: 92, depth: 90, height: 88, sleep: "—", weight: 28 },
    reviews: [
      { author: "Антон", rating: 5, text: "Очень удобное, не проседает. Подушка снимается.", date: "2025-09-20" }
    ]
  },
  {
    id: "berlin-lounger",
    name: "Лаунж Berlin",
    category: "divan",
    badge: "Хит",
    price: 76000,
    oldPrice: 89000,
    short: "Низкая посадка, широкие подушки, стиль лофт",
    description:
      "Лаунж-диван с глубокими сидениями и мягкими спинками. Отлично смотрится в минимализме и лофте.",
    images: [
      "images/berlin-1.svg",
      "images/berlin-2.svg"
    ],
    fabrics: [
      { id: "linen-graphite", name: "Лён — графит", priceDelta: 0, color: "#4a4f56" },
      { id: "vel-sand", name: "Велюр — песок", priceDelta: 2500, color: "#d5c3a7" }
    ],
    specs: {
      frame: "Брус + фанера",
      filler: "HR-пена 35 + пуховый микс",
      warranty: "3 года",
      cover: "Съёмные сиденья и спинки"
    },
    dimensions: { width: 210, depth: 110, height: 82, sleep: "195×145", weight: 60 },
    reviews: [
      { author: "Кирилл", rating: 5, text: "Очень комфортный, гости спят без жалоб.", date: "2025-09-10" }
    ]
  },
  {
    id: "mila-compact",
    name: "Диван-кровать Mila",
    category: "divan",
    badge: "Новинка",
    price: 68000,
    oldPrice: 78000,
    short: "Компакт 190 см, спальное место 190×145 см",
    description:
      "Компактный диван для городских квартир. Лёгкий механизм, ортопедическое основание, подлокотники съёмные.",
    images: [
      "images/mila-1.svg",
      "images/mila-2.svg"
    ],
    fabrics: [
      { id: "linen-mist", name: "Лён — туман", priceDelta: 0, color: "#c9ced6" },
      { id: "vel-sky", name: "Велюр — голубой", priceDelta: 1800, color: "#9bb7d3" }
    ],
    specs: {
      frame: "Металлокаркас + фанера",
      filler: "HR-пена 32 + слой латекса",
      warranty: "3 года",
      cover: "Несъёмные, петли для химчистки"
    },
    dimensions: { width: 190, depth: 95, height: 86, sleep: "190×145", weight: 55 },
    reviews: [
      { author: "Лена", rating: 4, text: "Легко раскладывается, компактный.", date: "2025-10-15" }
    ]
  },
  {
    id: "porto-bed",
    name: "Кровать Porto с мягким изголовьем",
    category: "divan",
    badge: "Топ",
    price: 82000,
    oldPrice: 92000,
    short: "Подъёмный механизм, ниша для белья, изголовье с кантом",
    description:
      "Кровать с мягкой спинкой и большим коробом для хранения. Доступны размеры 160/180 см.",
    images: [
      "images/porto-1.svg",
      "images/porto-2.svg"
    ],
    fabrics: [
      { id: "vel-milk", name: "Велюр — молочный", priceDelta: 0, color: "#f4eadf" },
      { id: "eco-taupe", name: "Эко-кожа — тауп", priceDelta: 3500, color: "#cbb9a0" }
    ],
    specs: {
      frame: "Фанера + ламели",
      filler: "Изголовье — HR-пена 30",
      warranty: "3 года",
      cover: "Несъёмный кантованный"
    },
    dimensions: { width: 200, depth: 220, height: 115, sleep: "160/180×200", weight: 85 },
    reviews: [
      { author: "Виктория", rating: 5, text: "Очень аккуратный кант, короб вместительный.", date: "2025-08-30" }
    ]
  }
];

const GLOBAL_REVIEWS = [
  { author: "Дарья", rating: 5, text: "Заказ оформили быстро, ткань помогли подобрать по образцам.", date: "2025-10-02" },
  { author: "Алексей", rating: 4, text: "Сборка в тот же день доставки, упаковка отличная.", date: "2025-10-08" }
];

