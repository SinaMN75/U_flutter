import "package:u/utilities.dart";

// Titles and icons of the short codes used in hotel / dorm details (amenities, meal plans, views...).
// GENERATED from one spec that is shared with the website; keep both in sync when adding an entry.
// Unknown codes are shown as written, so admins can also type free text.

class UPlaceOption {
  const UPlaceOption({required this.key, required this.titleFa, required this.titleEn, required this.icon, this.category});

  final String key;
  final String titleFa;
  final String titleEn;
  final IconData icon;
  final String? category;

  String get localizedTitle => UApp.locale() == "fa" ? titleFa : titleEn;
}

class UPlaceCategory {
  const UPlaceCategory({required this.key, required this.titleFa, required this.titleEn});

  final String key;
  final String titleFa;
  final String titleEn;

  String get localizedTitle => UApp.locale() == "fa" ? titleFa : titleEn;
}

abstract class UPlaceCatalog {
  /// Finds the option of a code (null for free text).
  static UPlaceOption? find(List<UPlaceOption> options, String key) {
    for (final UPlaceOption o in options) {
      if (o.key == key) return o;
    }
    return null;
  }

  /// The translated title of a code, or the code itself when it is free text.
  static String label(List<UPlaceOption> options, String key) => find(options, key)?.localizedTitle ?? key;

  /// The icon of an amenity code (a check mark for free text).
  static IconData iconOf(List<UPlaceOption> options, String key) => find(options, key)?.icon ?? Icons.check_circle_outline_rounded;

  static List<UPlaceOption> amenitiesOf(String category) => amenities.where((UPlaceOption o) => o.category == category).toList();

  static const List<UPlaceCategory> amenityCategories = <UPlaceCategory>[
    UPlaceCategory(key: "general", titleFa: "امکانات عمومی", titleEn: "General"),
    UPlaceCategory(key: "room", titleFa: "امکانات اتاق", titleEn: "In the room"),
    UPlaceCategory(key: "bathroom", titleFa: "سرویس بهداشتی", titleEn: "Bathroom"),
    UPlaceCategory(key: "food", titleFa: "غذا و آشپزخانه", titleEn: "Food & kitchen"),
    UPlaceCategory(key: "leisure", titleFa: "تفریح و فضاهای مشترک", titleEn: "Leisure & shared spaces"),
    UPlaceCategory(key: "business", titleFa: "کسب‌وکار", titleEn: "Business"),
    UPlaceCategory(key: "safety", titleFa: "امنیت و ایمنی", titleEn: "Safety & security"),
    UPlaceCategory(key: "transport", titleFa: "دسترسی و حمل‌ونقل", titleEn: "Transport"),
    UPlaceCategory(key: "family", titleFa: "خانواده و دسترسی", titleEn: "Family & accessibility"),
  ];

  static const List<UPlaceOption> amenities = <UPlaceOption>[
    UPlaceOption(key: "wifi", titleFa: "وای‌فای رایگان", titleEn: "Free Wi-Fi", icon: Icons.wifi_rounded, category: "general"),
    UPlaceOption(key: "fastInternet", titleFa: "اینترنت پرسرعت اختصاصی", titleEn: "Dedicated fast internet", icon: Icons.router_rounded, category: "general"),
    UPlaceOption(key: "parking", titleFa: "پارکینگ", titleEn: "Parking", icon: Icons.local_parking_rounded, category: "general"),
    UPlaceOption(key: "elevator", titleFa: "آسانسور", titleEn: "Elevator", icon: Icons.elevator_rounded, category: "general"),
    UPlaceOption(key: "reception24", titleFa: "پذیرش ۲۴ ساعته", titleEn: "24-hour reception", icon: Icons.support_agent_rounded, category: "general"),
    UPlaceOption(key: "luggageStorage", titleFa: "انبار چمدان", titleEn: "Luggage storage", icon: Icons.luggage_rounded, category: "general"),
    UPlaceOption(key: "laundry", titleFa: "خشکشویی و لاندری", titleEn: "Laundry service", icon: Icons.local_laundry_service_rounded, category: "general"),
    UPlaceOption(key: "washingMachine", titleFa: "ماشین لباسشویی", titleEn: "Washing machine", icon: Icons.wash_rounded, category: "general"),
    UPlaceOption(key: "dailyCleaning", titleFa: "نظافت و خدمات روزانه", titleEn: "Daily housekeeping", icon: Icons.cleaning_services_rounded, category: "general"),
    UPlaceOption(key: "concierge", titleFa: "خدمات کنسیرج", titleEn: "Concierge", icon: Icons.badge_rounded, category: "general"),
    UPlaceOption(key: "airportShuttle", titleFa: "ترانسفر فرودگاهی", titleEn: "Airport transfer", icon: Icons.flight_takeoff_rounded, category: "general"),
    UPlaceOption(key: "airConditioning", titleFa: "تهویه مطبوع (کولر/اسپلیت)", titleEn: "Air conditioning", icon: Icons.ac_unit_rounded, category: "room"),
    UPlaceOption(key: "heating", titleFa: "سیستم گرمایش", titleEn: "Heating", icon: Icons.thermostat_rounded, category: "room"),
    UPlaceOption(key: "tv", titleFa: "تلویزیون", titleEn: "TV", icon: Icons.tv_rounded, category: "room"),
    UPlaceOption(key: "minibar", titleFa: "مینی‌بار", titleEn: "Minibar", icon: Icons.local_bar_rounded, category: "room"),
    UPlaceOption(key: "fridge", titleFa: "یخچال", titleEn: "Refrigerator", icon: Icons.kitchen_rounded, category: "room"),
    UPlaceOption(key: "kettle", titleFa: "کتری برقی و چای‌ساز", titleEn: "Kettle & tea set", icon: Icons.coffee_maker_rounded, category: "room"),
    UPlaceOption(key: "safeBox", titleFa: "صندوق امانات", titleEn: "In-room safe", icon: Icons.lock_rounded, category: "room"),
    UPlaceOption(key: "desk", titleFa: "میز کار", titleEn: "Work desk", icon: Icons.desk_rounded, category: "room"),
    UPlaceOption(key: "balcony", titleFa: "بالکن", titleEn: "Balcony", icon: Icons.balcony_rounded, category: "room"),
    UPlaceOption(key: "wardrobe", titleFa: "کمد لباس", titleEn: "Wardrobe", icon: Icons.checkroom_rounded, category: "room"),
    UPlaceOption(key: "hairDryer", titleFa: "سشوار", titleEn: "Hair dryer", icon: Icons.air_rounded, category: "room"),
    UPlaceOption(key: "iron", titleFa: "اتو", titleEn: "Iron", icon: Icons.iron_rounded, category: "room"),
    UPlaceOption(key: "soundproof", titleFa: "عایق صدا", titleEn: "Soundproof", icon: Icons.volume_off_rounded, category: "room"),
    UPlaceOption(key: "privateBathroom", titleFa: "سرویس بهداشتی اختصاصی", titleEn: "Private bathroom", icon: Icons.bathroom_rounded, category: "bathroom"),
    UPlaceOption(key: "hotWater", titleFa: "آب گرم ۲۴ ساعته", titleEn: "24h hot water", icon: Icons.water_drop_rounded, category: "bathroom"),
    UPlaceOption(key: "bathtub", titleFa: "وان", titleEn: "Bathtub", icon: Icons.bathtub_rounded, category: "bathroom"),
    UPlaceOption(key: "toiletries", titleFa: "لوازم بهداشتی", titleEn: "Toiletries", icon: Icons.soap_rounded, category: "bathroom"),
    UPlaceOption(key: "breakfast", titleFa: "صبحانه", titleEn: "Breakfast", icon: Icons.free_breakfast_rounded, category: "food"),
    UPlaceOption(key: "restaurant", titleFa: "رستوران", titleEn: "Restaurant", icon: Icons.restaurant_rounded, category: "food"),
    UPlaceOption(key: "cafe", titleFa: "کافه", titleEn: "Café", icon: Icons.local_cafe_rounded, category: "food"),
    UPlaceOption(key: "roomService", titleFa: "روم‌سرویس", titleEn: "Room service", icon: Icons.room_service_rounded, category: "food"),
    UPlaceOption(key: "sharedKitchen", titleFa: "آشپزخانه مشترک", titleEn: "Shared kitchen", icon: Icons.countertops_rounded, category: "food"),
    UPlaceOption(key: "kitchenette", titleFa: "آشپزخانه اختصاصی", titleEn: "Private kitchenette", icon: Icons.microwave_rounded, category: "food"),
    UPlaceOption(key: "waterDispenser", titleFa: "آب‌سردکن", titleEn: "Water dispenser", icon: Icons.water_rounded, category: "food"),
    UPlaceOption(key: "selfService", titleFa: "سلف‌سرویس", titleEn: "Self-service dining", icon: Icons.dinner_dining_rounded, category: "food"),
    UPlaceOption(key: "pool", titleFa: "استخر", titleEn: "Swimming pool", icon: Icons.pool_rounded, category: "leisure"),
    UPlaceOption(key: "gym", titleFa: "باشگاه ورزشی", titleEn: "Gym", icon: Icons.fitness_center_rounded, category: "leisure"),
    UPlaceOption(key: "sauna", titleFa: "سونا و جکوزی", titleEn: "Sauna & jacuzzi", icon: Icons.hot_tub_rounded, category: "leisure"),
    UPlaceOption(key: "spa", titleFa: "اسپا و ماساژ", titleEn: "Spa & massage", icon: Icons.spa_rounded, category: "leisure"),
    UPlaceOption(key: "garden", titleFa: "باغ و فضای سبز", titleEn: "Garden", icon: Icons.park_rounded, category: "leisure"),
    UPlaceOption(key: "courtyard", titleFa: "حیاط مرکزی", titleEn: "Courtyard", icon: Icons.yard_rounded, category: "leisure"),
    UPlaceOption(key: "terrace", titleFa: "تراس و پشت‌بام", titleEn: "Terrace & rooftop", icon: Icons.deck_rounded, category: "leisure"),
    UPlaceOption(key: "lounge", titleFa: "لابی و نشیمن مشترک", titleEn: "Lounge & common room", icon: Icons.weekend_rounded, category: "leisure"),
    UPlaceOption(key: "library", titleFa: "کتابخانه", titleEn: "Library", icon: Icons.local_library_rounded, category: "leisure"),
    UPlaceOption(key: "studyRoom", titleFa: "اتاق مطالعه", titleEn: "Study room", icon: Icons.menu_book_rounded, category: "leisure"),
    UPlaceOption(key: "prayerRoom", titleFa: "نمازخانه", titleEn: "Prayer room", icon: Icons.mosque_rounded, category: "leisure"),
    UPlaceOption(key: "playground", titleFa: "فضای بازی کودکان", titleEn: "Kids' play area", icon: Icons.child_care_rounded, category: "leisure"),
    UPlaceOption(key: "gameRoom", titleFa: "اتاق بازی", titleEn: "Game room", icon: Icons.sports_esports_rounded, category: "leisure"),
    UPlaceOption(key: "meetingRoom", titleFa: "سالن جلسات و همایش", titleEn: "Meeting room", icon: Icons.meeting_room_rounded, category: "business"),
    UPlaceOption(key: "coworking", titleFa: "فضای کار مشترک", titleEn: "Coworking space", icon: Icons.laptop_mac_rounded, category: "business"),
    UPlaceOption(key: "printer", titleFa: "چاپ و اسکن", titleEn: "Print & scan", icon: Icons.print_rounded, category: "business"),
    UPlaceOption(key: "cctv", titleFa: "دوربین مداربسته", titleEn: "CCTV", icon: Icons.videocam_rounded, category: "safety"),
    UPlaceOption(key: "securityGuard", titleFa: "نگهبان ۲۴ ساعته", titleEn: "24h security", icon: Icons.security_rounded, category: "safety"),
    UPlaceOption(key: "fireSafety", titleFa: "سیستم اعلام و اطفای حریق", titleEn: "Fire safety system", icon: Icons.local_fire_department_rounded, category: "safety"),
    UPlaceOption(key: "firstAid", titleFa: "کمک‌های اولیه", titleEn: "First aid", icon: Icons.medical_services_rounded, category: "safety"),
    UPlaceOption(key: "smartLock", titleFa: "قفل کارتی / هوشمند", titleEn: "Smart lock", icon: Icons.key_rounded, category: "safety"),
    UPlaceOption(key: "supervisor", titleFa: "سرپرست مقیم", titleEn: "Resident supervisor", icon: Icons.supervisor_account_rounded, category: "safety"),
    UPlaceOption(key: "metroNearby", titleFa: "نزدیک مترو", titleEn: "Near metro", icon: Icons.subway_rounded, category: "transport"),
    UPlaceOption(key: "busNearby", titleFa: "نزدیک ایستگاه اتوبوس", titleEn: "Near bus stop", icon: Icons.directions_bus_rounded, category: "transport"),
    UPlaceOption(key: "shuttle", titleFa: "سرویس ایاب و ذهاب", titleEn: "Shuttle service", icon: Icons.directions_bus_filled_rounded, category: "transport"),
    UPlaceOption(key: "bikeParking", titleFa: "پارکینگ دوچرخه و موتور", titleEn: "Bike parking", icon: Icons.pedal_bike_rounded, category: "transport"),
    UPlaceOption(key: "evCharging", titleFa: "شارژر خودروی برقی", titleEn: "EV charging", icon: Icons.ev_station_rounded, category: "transport"),
    UPlaceOption(key: "wheelchair", titleFa: "مناسب افراد دارای معلولیت", titleEn: "Wheelchair accessible", icon: Icons.accessible_rounded, category: "family"),
    UPlaceOption(key: "familyRooms", titleFa: "اتاق خانوادگی", titleEn: "Family rooms", icon: Icons.family_restroom_rounded, category: "family"),
    UPlaceOption(key: "nonSmokingRooms", titleFa: "اتاق‌های سیگار ممنوع", titleEn: "Non-smoking rooms", icon: Icons.smoke_free_rounded, category: "family"),
    UPlaceOption(key: "petFriendly", titleFa: "پذیرش حیوان خانگی", titleEn: "Pets allowed", icon: Icons.pets_rounded, category: "family"),
    UPlaceOption(key: "lockers", titleFa: "کمد و قفسه شخصی", titleEn: "Personal lockers", icon: Icons.inventory_2_rounded, category: "family"),
  ];

  static const List<UPlaceOption> hotelTypes = <UPlaceOption>[
    UPlaceOption(key: "hotel", titleFa: "هتل", titleEn: "Hotel", icon: Icons.hotel_rounded),
    UPlaceOption(key: "boutique", titleFa: "بوتیک‌هتل", titleEn: "Boutique hotel", icon: Icons.diamond_rounded),
    UPlaceOption(key: "resort", titleFa: "ریزورت", titleEn: "Resort", icon: Icons.beach_access_rounded),
    UPlaceOption(key: "guesthouse", titleFa: "مهمان‌پذیر", titleEn: "Guest house", icon: Icons.home_work_rounded),
    UPlaceOption(key: "apartment", titleFa: "هتل‌آپارتمان", titleEn: "Apartment hotel", icon: Icons.apartment_rounded),
    UPlaceOption(key: "traditional", titleFa: "اقامتگاه سنتی", titleEn: "Traditional stay", icon: Icons.holiday_village_rounded),
    UPlaceOption(key: "hostel", titleFa: "هاستل", titleEn: "Hostel", icon: Icons.bed_rounded),
    UPlaceOption(key: "villa", titleFa: "ویلا", titleEn: "Villa", icon: Icons.villa_rounded),
  ];

  static const List<UPlaceOption> mealPlans = <UPlaceOption>[
    UPlaceOption(key: "roomOnly", titleFa: "فقط اتاق", titleEn: "Room only", icon: Icons.hotel_rounded),
    UPlaceOption(key: "breakfast", titleFa: "با صبحانه", titleEn: "Breakfast included", icon: Icons.free_breakfast_rounded),
    UPlaceOption(key: "halfBoard", titleFa: "نیم‌پانسیون (صبحانه و شام)", titleEn: "Half board", icon: Icons.restaurant_rounded),
    UPlaceOption(key: "fullBoard", titleFa: "پانسیون کامل (سه وعده)", titleEn: "Full board", icon: Icons.dinner_dining_rounded),
    UPlaceOption(key: "allInclusive", titleFa: "همه‌چیز شامل", titleEn: "All inclusive", icon: Icons.local_dining_rounded),
  ];

  static const List<UPlaceOption> paymentMethods = <UPlaceOption>[
    UPlaceOption(key: "cash", titleFa: "نقدی", titleEn: "Cash", icon: Icons.payments_rounded),
    UPlaceOption(key: "card", titleFa: "کارت‌خوان", titleEn: "Card", icon: Icons.credit_card_rounded),
    UPlaceOption(key: "online", titleFa: "پرداخت آنلاین", titleEn: "Online", icon: Icons.language_rounded),
    UPlaceOption(key: "transfer", titleFa: "کارت‌به‌کارت / حواله", titleEn: "Bank transfer", icon: Icons.account_balance_rounded),
  ];

  static const List<UPlaceOption> roomViews = <UPlaceOption>[
    UPlaceOption(key: "city", titleFa: "منظره شهر", titleEn: "City view", icon: Icons.location_city_rounded),
    UPlaceOption(key: "garden", titleFa: "منظره باغ", titleEn: "Garden view", icon: Icons.park_rounded),
    UPlaceOption(key: "courtyard", titleFa: "رو به حیاط", titleEn: "Courtyard view", icon: Icons.yard_rounded),
    UPlaceOption(key: "sea", titleFa: "منظره دریا", titleEn: "Sea view", icon: Icons.waves_rounded),
    UPlaceOption(key: "mountain", titleFa: "منظره کوه", titleEn: "Mountain view", icon: Icons.landscape_rounded),
    UPlaceOption(key: "pool", titleFa: "رو به استخر", titleEn: "Pool view", icon: Icons.pool_rounded),
  ];

  static const List<UPlaceOption> bathroomTypes = <UPlaceOption>[
    UPlaceOption(key: "private", titleFa: "سرویس اختصاصی", titleEn: "Private bathroom", icon: Icons.bathroom_rounded),
    UPlaceOption(key: "shared", titleFa: "سرویس مشترک", titleEn: "Shared bathroom", icon: Icons.wc_rounded),
  ];

  static const List<UPlaceOption> languages = <UPlaceOption>[
    UPlaceOption(key: "fa", titleFa: "فارسی", titleEn: "Persian", icon: Icons.translate_rounded),
    UPlaceOption(key: "en", titleFa: "انگلیسی", titleEn: "English", icon: Icons.translate_rounded),
    UPlaceOption(key: "ar", titleFa: "عربی", titleEn: "Arabic", icon: Icons.translate_rounded),
    UPlaceOption(key: "tr", titleFa: "ترکی", titleEn: "Turkish", icon: Icons.translate_rounded),
    UPlaceOption(key: "ru", titleFa: "روسی", titleEn: "Russian", icon: Icons.translate_rounded),
    UPlaceOption(key: "de", titleFa: "آلمانی", titleEn: "German", icon: Icons.translate_rounded),
    UPlaceOption(key: "fr", titleFa: "فرانسوی", titleEn: "French", icon: Icons.translate_rounded),
    UPlaceOption(key: "zh", titleFa: "چینی", titleEn: "Chinese", icon: Icons.translate_rounded),
  ];

  static const List<UPlaceOption> dormServices = <UPlaceOption>[
    UPlaceOption(key: "internet", titleFa: "اینترنت", titleEn: "Internet", icon: Icons.wifi_rounded),
    UPlaceOption(key: "water", titleFa: "آب", titleEn: "Water", icon: Icons.water_drop_rounded),
    UPlaceOption(key: "electricity", titleFa: "برق", titleEn: "Electricity", icon: Icons.bolt_rounded),
    UPlaceOption(key: "gas", titleFa: "گاز", titleEn: "Gas", icon: Icons.local_fire_department_rounded),
    UPlaceOption(key: "heating", titleFa: "گرمایش", titleEn: "Heating", icon: Icons.thermostat_rounded),
    UPlaceOption(key: "cooling", titleFa: "سرمایش", titleEn: "Cooling", icon: Icons.ac_unit_rounded),
    UPlaceOption(key: "cleaning", titleFa: "نظافت", titleEn: "Cleaning", icon: Icons.cleaning_services_rounded),
    UPlaceOption(key: "laundry", titleFa: "لباسشویی", titleEn: "Laundry", icon: Icons.local_laundry_service_rounded),
    UPlaceOption(key: "furniture", titleFa: "مبلمان و تجهیزات", titleEn: "Furniture", icon: Icons.chair_rounded),
  ];

  static const List<UPlaceOption> mealServices = <UPlaceOption>[
    UPlaceOption(key: "breakfast", titleFa: "صبحانه", titleEn: "Breakfast", icon: Icons.free_breakfast_rounded),
    UPlaceOption(key: "lunch", titleFa: "ناهار", titleEn: "Lunch", icon: Icons.lunch_dining_rounded),
    UPlaceOption(key: "dinner", titleFa: "شام", titleEn: "Dinner", icon: Icons.dinner_dining_rounded),
  ];

  static const List<UPlaceOption> residentTypes = <UPlaceOption>[
    UPlaceOption(key: "bachelor", titleFa: "دانشجوی کارشناسی", titleEn: "Bachelor's students", icon: Icons.school_rounded),
    UPlaceOption(key: "master", titleFa: "دانشجوی ارشد", titleEn: "Master's students", icon: Icons.school_rounded),
    UPlaceOption(key: "phd", titleFa: "دانشجوی دکتری", titleEn: "PhD students", icon: Icons.school_rounded),
    UPlaceOption(key: "staff", titleFa: "کارمند و هیئت علمی", titleEn: "Staff & faculty", icon: Icons.work_rounded),
  ];

  static const List<UPlaceOption> nearbyTypes = <UPlaceOption>[
    UPlaceOption(key: "university", titleFa: "دانشگاه", titleEn: "University", icon: Icons.school_rounded),
    UPlaceOption(key: "metro", titleFa: "مترو", titleEn: "Metro", icon: Icons.subway_rounded),
    UPlaceOption(key: "bus", titleFa: "ایستگاه اتوبوس", titleEn: "Bus stop", icon: Icons.directions_bus_rounded),
    UPlaceOption(key: "hospital", titleFa: "بیمارستان", titleEn: "Hospital", icon: Icons.local_hospital_rounded),
    UPlaceOption(key: "mall", titleFa: "مرکز خرید", titleEn: "Shopping mall", icon: Icons.shopping_bag_rounded),
    UPlaceOption(key: "restaurant", titleFa: "رستوران", titleEn: "Restaurant", icon: Icons.restaurant_rounded),
    UPlaceOption(key: "airport", titleFa: "فرودگاه", titleEn: "Airport", icon: Icons.flight_rounded),
    UPlaceOption(key: "attraction", titleFa: "جاذبه گردشگری", titleEn: "Attraction", icon: Icons.attractions_rounded),
    UPlaceOption(key: "park", titleFa: "پارک", titleEn: "Park", icon: Icons.park_rounded),
    UPlaceOption(key: "market", titleFa: "بازار", titleEn: "Market", icon: Icons.storefront_rounded),
    UPlaceOption(key: "bank", titleFa: "بانک", titleEn: "Bank", icon: Icons.account_balance_rounded),
    UPlaceOption(key: "pharmacy", titleFa: "داروخانه", titleEn: "Pharmacy", icon: Icons.local_pharmacy_rounded),
  ];

  static const List<UPlaceOption> bedLevels = <UPlaceOption>[
    UPlaceOption(key: "bottom", titleFa: "تخت پایین", titleEn: "Bottom bunk", icon: Icons.bed_rounded),
    UPlaceOption(key: "top", titleFa: "تخت بالا", titleEn: "Top bunk", icon: Icons.bed_rounded),
    UPlaceOption(key: "single", titleFa: "تک‌طبقه", titleEn: "Single bed", icon: Icons.single_bed_rounded),
  ];

  static const List<UPlaceOption> bedAmenities = <UPlaceOption>[
    UPlaceOption(key: "desk", titleFa: "میز مطالعه", titleEn: "Desk", icon: Icons.desk_rounded),
    UPlaceOption(key: "locker", titleFa: "قفسه شخصی", titleEn: "Locker", icon: Icons.inventory_2_rounded),
    UPlaceOption(key: "lamp", titleFa: "چراغ مطالعه", titleEn: "Reading lamp", icon: Icons.light_rounded),
    UPlaceOption(key: "curtain", titleFa: "پرده حریم", titleEn: "Privacy curtain", icon: Icons.curtains_rounded),
    UPlaceOption(key: "outlet", titleFa: "پریز برق", titleEn: "Power outlet", icon: Icons.electrical_services_rounded),
    UPlaceOption(key: "shelf", titleFa: "طبقه", titleEn: "Shelf", icon: Icons.shelves),
  ];
}
