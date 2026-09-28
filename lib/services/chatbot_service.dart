import 'dart:math';
import 'data_service.dart';
import '../models/product_model.dart';
import '../models/farmer_model.dart';

class ChatbotService {
  // Crop & Produce translation dictionary for English / Urdu / Roman Urdu
  static final Map<String, List<String>> _cropSynonyms = {
    'apple': ['apple', 'apples', 'saib', 'seb', 'kala kulu'],
    'mango': ['mango', 'mangoes', 'aam', 'sindhri', 'chaunsa', 'anwar ratol', 'langra', 'doseri'],
    'tomato': ['tomato', 'tomatoes', 'tamatar'],
    'potato': ['potato', 'potatoes', 'aloo', 'alu'],
    'onion': ['onion', 'onions', 'pyaz', 'piyaz', 'piaz'],
    'banana': ['banana', 'bananas', 'kela', 'kelay'],
    'milk': ['milk', 'doodh', 'dairy', 'buffalo milk', 'cow milk'],
    'wheat': ['wheat', 'atta', 'gandum', 'flour', 'chakki'],
    'rice': ['rice', 'chawal', 'basmati', 'sela', 'super basmati'],
    'egg': ['egg', 'eggs', 'anda', 'anday', 'desi anday'],
    'honey': ['honey', 'shehad', 'shahtoot', 'sidr', 'choti makhi'],
    'spinach': ['spinach', 'palak', 'saag'],
    'carrot': ['carrot', 'carrots', 'gajar'],
    'cucumber': ['cucumber', 'cucumbers', 'kheera'],
    'corn': ['corn', 'bhutta', 'makai', 'makki'],
    'guava': ['guava', 'amrood'],
    'orange': ['orange', 'oranges', 'kinnow', 'malta', 'mosambi', 'citrus'],
    'chilli': ['chilli', 'chillies', 'mirch', 'hari mirch', 'green pepper'],
    'garlic': ['garlic', 'lehsan', 'lahsan'],
    'ginger': ['ginger', 'adrak'],
    'cauliflower': ['cauliflower', 'gobhi', 'phool gobhi'],
    'cabbage': ['cabbage', 'patta gobhi', 'band gobhi'],
    'peas': ['pea', 'peas', 'matar', 'mattar'],
  };

  // Comprehensive static Q&A knowledge base for HarvestHub features & food science
  static final Map<String, List<String>> _knowledgeBase = {
    // ══════════════════════════════════════════════════════════════════════════
    // 1. HARVESTHUB APP: LIVE MAP & FARMER LOCATIONS
    // ══════════════════════════════════════════════════════════════════════════
    'live map|map|location|farmer location|find farmer|kahan hai farmer|map kaise|karachi map|pakistan map|directions|get directions|market map': [
      ' **HarvestHub Live Farmers Map:**\n\n'
      '• **View Farmers on Map**: Tap the **Map icon** at the top right of the Customer Home screen (next to notifications) or in the Product Listing.\n'
      '• **Pakistan & City Filters**: Filter farmers across all Pakistan cities (Karachi, Lahore, Islamabad, Faisalabad, Multan, Peshawar, Quetta, Hyderabad, etc.).\n'
      '• **Karachi Neighborhoods**: Select specific areas like Clifton & DHA, Gulshan-e-Iqbal, Gulistan-e-Jauhar, North Karachi, Nazimabad, Malir, Korangi, Bahria Town, and Saddar.\n'
      '• **Get Directions**: Tap on any farmer\'s pin to see their market hours, address, fresh produce, and tap "Get Directions" to open Google Maps navigation directly!\n'
      '• **Direct Chat**: You can also initiate a real-time chat with the farmer directly from the map sheet.',
    ],
    'karachi|clifton|gulshan|dha|malir|north karachi|nazimabad|korangi|bahria town': [
      ' **Karachi Farmers & Markets:**\n\n'
      'You can easily discover fresh produce markets in Karachi:\n'
      '• Open the **Live Map** from the top bar.\n'
      '• Select **City: Karachi** and choose your preferred area (e.g. *Clifton & DHA, Gulshan-e-Iqbal, Malir, North Karachi, Nazimabad, Korangi, Bahria Town*).\n'
      '• The map will zoom directly into local farmer stalls and roadside markets in your area!\n'
      '• Tap any marker to view contact info, operating hours, and active fresh crops.',
    ],
    'set location|farmer set market|operating hours|farmer map pin|apni location kaise lagaye': [
      ' **For Farmers: Setting Your Market Location & Hours:**\n\n'
      '1. Go to **Farmer Panel > Market Location** (or tap "Set Market Location & Hours" on Dashboard).\n'
      '2. Select your **City** and **Area** from the dropdowns.\n'
      '3. **Tap on the Interactive Map** to drop your exact market pin (or tap "Use GPS").\n'
      '4. Enter your **Market Name, Address**, and **Operating Hours** (e.g., *7:00 AM - 2:00 PM (Daily)*).\n'
      '5. Tap **Save Market Location**. Customers will now see your live pin on their map!',
    ],

    // ══════════════════════════════════════════════════════════════════════════
    // 2. HARVESTHUB APP: CHAT & VOICE MESSAGES
    // ══════════════════════════════════════════════════════════════════════════
    'chat|message|voice message|audio message|awaz message|farmer se baat|rabta|internal chat': [
      ' **Internal Chat & Voice Messaging:**\n\n'
      '• **Chat with Any Farmer**: Open any Product Details, Farmer Profile, or Map Sheet and tap the **Chat** icon.\n'
      '• **Voice Notes **: Hold or tap the Microphone icon in the chat bar to record a voice message. Tap Send to upload and deliver instantly.\n'
      '• **Images **: Tap the picture icon to share produce photos with the farmer.\n'
      '• **Real-Time Delivery**: Messages are synced in real-time via Cloud Firestore with unread counts and notifications.',
    ],

    // ══════════════════════════════════════════════════════════════════════════
    // 3. HARVESTHUB APP: SEARCH & FILTERS
    // ══════════════════════════════════════════════════════════════════════════
    'filter|filters|reset filter|clear filter|search product|distance filter|filter kaise use kare': [
      ' **Search & Filter Guide:**\n\n'
      '• **Product Name**: Search by any crop (e.g., Tomato, Wheat, Mango, Milk).\n'
      '• **Farmer Name**: Search products sold by a specific grower.\n'
      '• **Category Chips**: Quickly filter by *Vegetable, Fruit, Dairy, Grain, Organic, Herbs*.\n'
      '• **Farmer Distance Slider**: Set max distance (5 km to 50 km).\n'
      '• **GPS Location**: Tap "Use my location for distance" to calculate real distances from your current position.\n'
      '• **Reset All Button**: Tap "Reset All" at top right to instantly clear all keyword, distance, location, category, and price filters!',
    ],

    // ══════════════════════════════════════════════════════════════════════════
    // 4. HARVESTHUB APP: ORDERING & CHECKOUT
    // ══════════════════════════════════════════════════════════════════════════
    'order|how to order|place order|kese order karein|buy product|checkout|khareedna': [
      ' **How to Place an Order on HarvestHub:**\n\n'
      '1. Browse products from **Home** or **Products (Grid View)**.\n'
      '2. Tap any item to view farm source, freshness score, and price insight.\n'
      '3. Select quantity and tap **Add to Cart**.\n'
      '4. Go to **Cart**, review items, and tap **Proceed to Checkout**.\n'
      '5. Select your Delivery Address and preferred Payment Method (Cash on Delivery / Online).\n'
      '6. Confirm to place your order! You can track status in **Profile > My Orders**.',
    ],
    'delivery|shipping|delivery fee|kitna time lagega|when will i get': [
      ' **Delivery & Pickup Details:**\n\n'
      '• **Standard Delivery**: Usually delivered within 24 to 48 hours directly from the nearest partner farm or local collection center.\n'
      '• **Delivery Charges**: Flat PKR 150 standard delivery fee across all orders (Free for reward club members).\n'
      '• **Order Tracking**: Check real-time progress under **Profile > My Orders** (Pending  Confirmed  Out for Delivery  Delivered).',
    ],
    'payment|cod|cash on delivery|online payment|paise': [
      ' **Payment Methods:**\n\n'
      '• **Cash on Delivery (COD)**: Pay cash in Pakistani Rupees (PKR) upon receiving your fresh produce.\n'
      '• **Online Payment / Wallets**: Supports JazzCash, EasyPaisa, and Bank Transfers.\n'
      '• Secure and transparent with digital invoice receipts generated for every order.',
    ],

    // ══════════════════════════════════════════════════════════════════════════
    // 5. HARVESTHUB APP: FARMER VERIFICATION & FOLLOWING
    // ══════════════════════════════════════════════════════════════════════════
    'follow|following|followed farmer|favorite farmer|kisan follow': [
      ' **Following Farmers Feature:**\n\n'
      '• Open any **Farmer Profile** and tap **"Follow Farmer"**.\n'
      '• Followed farmers are saved to your account and shown in **Profile > Following Farmers**.\n'
      '• Whenever they list fresh harvests or restock items, you receive live updates!\n'
      '• You can unfollow anytime with 1 tap.',
    ],
    'verified farmer|badge|verification|approval|admin verify|touseeq': [
      ' **Farmer Verification & Trust:**\n\n'
      '• **Verified Badge (Green Checkmark)**: Given to vetted farmers whose land, CNIC, and produce quality have been inspected by the HarvestHub Admin.\n'
      '• **Admin Management**: Admins can approve pending farmers and toggle verification status with 1-tap directly from the Admin Dashboard & Farmers screen.\n'
      '• Verified status is permanently synchronized to ensure customer confidence and food safety.',
    ],
    'rewards|loyalty|points|discount|coupon|inamat': [
      ' **HarvestHub Rewards & Loyalty Club:**\n\n'
      '• **Earn Points**: Get 10 reward points for every 100 PKR spent on fresh farm orders.\n'
      '• **Level Tiers**: Progress from *Sprout  Harvester  Master Green*.\n'
      '• **Redeem Discounts**: Exchange points for discount vouchers (PKR 100, PKR 250, PKR 500 off).\n'
      '• View your balance anytime under **Profile > My Rewards & Points**.',
    ],
    'urdu|language|zuban|urdu me kaise karein': [
      ' **Language & Localization:**\n\n'
      '• HarvestHub supports **English, Urdu (اردو), and Hindi**.\n'
      '• To switch language: Go to **Profile > Language Selection** and choose your preferred language.\n'
      '• The application keeps clean, modern alignment with full native script support.',
    ],

    // ══════════════════════════════════════════════════════════════════════════
    // 6. NUTRITION, HEALTH & STORAGE TIPS
    // ══════════════════════════════════════════════════════════════════════════
    'vitamin c|vitamin-c|vitaminc': [
      ' **Vitamin C Rich Produce:**\n\n'
      '• Oranges & Kinnow \n• Guava (Amrood)  (highest vitamin C content!)\n• Strawberries \n• Kiwi \n• Papaya (Papeeta)\n• Lemon & Lime \n• Bell Peppers (Capsicum/Shimla Mirch)\n• Green Chillies ',
    ],
    'vitamin a|vitamin-a|vitamina': [
      ' **Vitamin A & Eye Health Foods:**\n\n'
      '• Carrots (Gajar)  (Rich in Beta-Carotene)\n• Sweet Potato (Shakarkandi) \n• Spinach (Palak) \n• Pumpkin (Kaddu) \n• Mango (Chaunsa, Sindhri, Anwar Ratol) \n• Papaya\n• Tomatoes ',
    ],
    'iron|iron rich|khoon ki kami|anemia': [
      ' **Iron-Rich Farm Products (Boost Hemoglobin):**\n\n'
      '• Spinach (Palak) \n• Beetroot (Chukandar)\n• Pomegranate (Anaar) \n• Lentils (Daal Masoor, Moong, Chana) \n• Green Peas (Matar)\n• Fenugreek (Methi) \n• Dates (Khajoor)',
    ],
    'protein|proteins|taqat': [
      ' **High-Protein Farm Products:**\n\n'
      '• Pulses & Dal (Moong, Masoor, Chana, Mash) \n• Chickpeas (Kabuli & Desi Chana)\n• Soybean & Kidney Beans (Rajma)\n• Fresh Farm Eggs \n• Desi Cow & Buffalo Milk \n• Paneer & Cheese \n• Green Peas',
    ],
    'store tomato|tamatar store|keep tomato': [
      ' **Tomato Storage Tips:**\n\n'
      ' Keep at room temperature until fully ripe.\n'
      ' Keep stem-side down away from direct sunlight.\n'
      ' Once fully ripe, store in refrigerator crisper for up to 5 days.\n'
      ' Bring to room temp before cooking for best natural flavor!',
    ],
    'store potato|aloo store|keep potato': [
      ' **Potato Storage Tips:**\n\n'
      ' Store in a cool, dark, dry, well-ventilated area (10°C - 15°C).\n'
      ' Use paper bags or basket.\n'
      ' DO NOT store inside the refrigerator (starch turns to sugar).\n'
      ' Keep away from onions (gases cause both to spoil faster).',
    ],
    'store onion|pyaz store|keep onion': [
      ' **Onion Storage Tips:**\n\n'
      ' Store in an open basket or mesh bag with good air circulation.\n'
      ' Keep in a dry, dark place.\n'
      ' Never refrigerate whole unpeeled onions (they get soggy).\n'
      ' Stored properly, dry onions last 2 to 3 months.',
    ],
    'store leafy|spinach storage|palak store|dhaniya store': [
      ' **Leafy Greens (Palak, Methi, Coriander, Mint) Storage:**\n\n'
      ' Remove rubber bands and trim dry roots.\n'
      ' Wrap unwashed greens loosely in dry paper towels.\n'
      ' Place inside an airtight container or zip lock in the fridge crisper.\n'
      ' Keeps fresh and crisp for 7 to 10 days!',
    ],
    'seasonal|season|mausam|garmi|sardi|crops': [
      ' **Seasonal Produce Calendar:**\n\n'
      '• **Summer (Garmi)**: Mangoes , Watermelon , Melons, Cucumber , Bitter Gourd (Karela), Ridge Gourd (Tori), Ladyfinger (Bhindi), Bottle Gourd (Lauki).\n'
      '• **Winter (Sardi)**: Kinnow & Oranges , Carrots (Gajar) , Cauliflower (Gobhi), Green Peas (Matar), Radish (Mooli), Turnip (Shalgam), Spinach (Palak), Mustard Greens (Sarson Ka Saag) .\n'
      '• **Monsoon / Autumn**: Corn (Bhutta) , Pomegranate, Guava, Apples.',
    ],
  };

  static final List<String> _greetings = [
    'Hello!  Welcome to HarvestHub Assistant. How can I help you with our app, live map, farmers, or farm produce today?',
    'Assalam-o-Alaikum & Welcome!  I am your HarvestHub Assistant. Ask me anything about orders, live products, the map, farmers, or storage tips!',
    'Hi there!  How can I assist you today? You can ask about available fruits, vegetables, prices, Karachi map, or messaging farmers.',
  ];

  static final List<String> _thanksResponses = [
    'You are very welcome!  Feel free to ask if you need anything else.',
    'Happy to help!  Enjoy fresh farm produce directly from our local growers.',
    'Bohat shukriya!  Let me know if you have any more questions about HarvestHub.',
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // DYNAMIC PRODUCT CATALOG ANALYSIS ENGINE
  // ══════════════════════════════════════════════════════════════════════════

  /// Analyze the live catalog in DataService and respond intelligently
  static String? _analyzeLiveCatalog(String rawMessage) {
    final message = rawMessage.toLowerCase().trim();
    final dataService = DataService();
    final products = dataService.products;
    final farmers = dataService.farmers;

    if (products.isEmpty) {
      return null;
    }

    // 1. Check for "show all products" / "what products do you have" intent
    if (message.contains('what products') ||
        message.contains('all products') ||
        message.contains('show products') ||
        message.contains('kya kya hai') ||
        message.contains('tamam products') ||
        message.contains('list of products')) {
      return _generateCatalogSummary(products);
    }

    // 2. Extract potential crop/item search query from user message
    String cleaned = message;
    // Remove common question prefixes & suffixes
    final removePatterns = [
      'do you have any',
      'do you have',
      'is there any',
      'is there',
      'are there any',
      'are there',
      'can i buy',
      'i want to buy',
      'i need',
      'looking for',
      'search for',
      'show me',
      'price of',
      'how much is',
      'who sells',
      'who has',
      'kya aap ke paas',
      'kya aap k pas',
      'kya ap ke pas',
      'kya milay ga',
      'kya milega',
      'hai kya',
      'chahiye',
      'chahye',
      'available',
      'in stock',
      'please',
      'tell me about',
      'rate of',
      'cost of',
      '?',
      '!',
      '.',
    ];

    for (final pattern in removePatterns) {
      cleaned = cleaned.replaceAll(pattern, ' ');
    }
    cleaned = cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Check against synonym dictionary first
    List<String> targetTerms = [];
    for (final entry in _cropSynonyms.entries) {
      for (final synonym in entry.value) {
        if (message.contains(synonym)) {
          targetTerms.addAll(entry.value);
          break;
        }
      }
    }

    if (targetTerms.isEmpty && cleaned.isNotEmpty) {
      targetTerms.add(cleaned);
      // also split into words
      for (final word in cleaned.split(' ')) {
        if (word.length > 2) targetTerms.add(word);
      }
    }

    if (targetTerms.isEmpty) {
      return null;
    }

    // 3. Search matching products in the live catalog
    final matchingProducts = <ProductModel>[];
    for (final p in products) {
      final pTitle = p.title.toLowerCase();
      final pCat = p.category.toLowerCase();
      final pDesc = p.description.toLowerCase();
      final pFarmer = p.farmerName.toLowerCase();

      bool match = false;
      for (final term in targetTerms) {
        if (term.isEmpty) continue;
        if (pTitle.contains(term) ||
            pCat.contains(term) ||
            pDesc.contains(term) ||
            pFarmer.contains(term)) {
          match = true;
          break;
        }
      }

      if (match && !matchingProducts.contains(p)) {
        matchingProducts.add(p);
      }
    }

    // 4. If products found, build rich dynamic response
    if (matchingProducts.isNotEmpty) {
      final buffer = StringBuffer();
      final topItem = matchingProducts.first;
      buffer.writeln(' **Yes! We have ${topItem.title} available on HarvestHub!** \n');
      buffer.writeln('Here is the live availability & pricing directly from our registered farmers:\n');

      int count = 0;
      for (final product in matchingProducts) {
        if (count >= 3) break; // Display top 3 matching farm sources
        count++;

        // Find farmer details for enhanced location info
        FarmerModel? farmerObj;
        try {
          farmerObj = farmers.firstWhere(
            (f) => f.id == product.farmerId || f.name.toLowerCase() == product.farmerName.toLowerCase(),
          );
        } catch (_) {}

        final locationStr = (farmerObj?.marketName.isNotEmpty == true)
            ? farmerObj!.marketName
            : (farmerObj?.location.isNotEmpty == true
                ? farmerObj!.location
                : (product.marketName.isNotEmpty ? product.marketName : 'Local Farm Stall'));

        final cityArea = (farmerObj?.area != null && farmerObj!.area!.isNotEmpty)
            ? ' (${farmerObj.area}, ${farmerObj.city ?? "Karachi"})'
            : (farmerObj?.city != null ? ' (${farmerObj!.city})' : '');

        buffer.writeln(' **Option $count: ${product.title}**');
        buffer.writeln('•  **Price:** PKR ${product.price.toStringAsFixed(0)} / ${product.unit}');
        buffer.writeln('•  **Farmer:** ${product.farmerName} ${farmerObj?.isVerified == true ? " (Verified)" : ""}');
        buffer.writeln('•  **Location:** $locationStr$cityArea');
        buffer.writeln('•  **Quality:** ${product.isOrganic ? " 100% Organic" : " Fresh Farm Produce"} (Freshness: ${product.freshnessScore}%)');
        buffer.writeln('•  **Stock Status:** ${product.stock > 0 ? "${product.stock} ${product.unit} in stock" : "Low Stock"}');
        buffer.writeln();
      }

      buffer.writeln(' **How to buy:** You can find this item in the **Products** tab or search for **"${topItem.title}"** to add it directly to your cart with Cash on Delivery!');
      return buffer.toString().trim();
    }

    // 5. If specific product was asked for but not in catalog, provide friendly guidance
    // Check if the query looked like a specific product inquiry
    final isProductInquiry = message.contains('have') ||
        message.contains('hai') ||
        message.contains('milay') ||
        message.contains('buy') ||
        message.contains('sell') ||
        message.contains('price') ||
        message.contains('rate') ||
        message.contains('cost') ||
        _cropSynonyms.keys.any((k) => message.contains(k));

    if (isProductInquiry) {
      final searchedName = cleaned.isNotEmpty ? cleaned : rawMessage;
      final buffer = StringBuffer();
      buffer.writeln(' I searched our live farm inventory, but **"$searchedName"** is currently not listed by any farmer today.\n');
      buffer.writeln(' **Currently Available Fresh Categories on HarvestHub:**');

      final categories = dataService.categories.map((c) => c.name).toSet();
      if (categories.isNotEmpty) {
        for (final cat in categories.take(6)) {
          buffer.writeln('• $cat');
        }
      } else {
        buffer.writeln('• Fresh Vegetables \n• Farm Fruits \n• Pure Dairy & Milk \n• Whole Grains & Atta ');
      }

      buffer.writeln('\n *Tip:* Our partner farmers update fresh harvests every morning! You can explore other items in the **Products** tab or view the **Live Map** to see nearby farmers.');
      return buffer.toString().trim();
    }

    return null;
  }

  static String _generateCatalogSummary(List<ProductModel> products) {
    final buffer = StringBuffer();
    buffer.writeln(' **Currently Available Products on HarvestHub:**\n');

    final grouped = <String, List<ProductModel>>{};
    for (final p in products) {
      grouped.putIfAbsent(p.category.isNotEmpty ? p.category : 'Fresh Harvest', () => []).add(p);
    }

    for (final entry in grouped.entries.take(4)) {
      buffer.writeln(' **${entry.key}:**');
      for (final item in entry.value.take(3)) {
        buffer.writeln('  • **${item.title}** — PKR ${item.price.toStringAsFixed(0)} / ${item.unit} *(by ${item.farmerName})*');
      }
      buffer.writeln();
    }

    buffer.writeln(' Browse the **Products** tab for full catalog and 1-tap cart ordering!');
    return buffer.toString().trim();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN BOT RESPONSE ROUTER
  // ══════════════════════════════════════════════════════════════════════════

  /// Get bot response based on user message
  static String getBotResponse(String userMessage) {
    final message = userMessage.toLowerCase().trim();

    // 1. Check greetings
    if (_isGreeting(message)) {
      return _greetings[Random().nextInt(_greetings.length)];
    }

    // 2. Check thanks
    if (_isThanks(message)) {
      return _thanksResponses[Random().nextInt(_thanksResponses.length)];
    }

    // 3. Check live product catalog intelligence first
    final liveProductResponse = _analyzeLiveCatalog(userMessage);
    if (liveProductResponse != null) {
      return liveProductResponse;
    }

    // 4. Match keywords against knowledge base
    for (var entry in _knowledgeBase.entries) {
      final keywords = entry.key.split('|');
      for (var keyword in keywords) {
        if (message.contains(keyword.toLowerCase())) {
          return entry.value[Random().nextInt(entry.value.length)];
        }
      }
    }

    // 5. Default smart fallback
    return 'I\'m your HarvestHub Smart Assistant! \n\n'
        'You can ask me:\n'
        '•  **"Do you have apples / tomatoes / milk?"** (I check live farmer prices & locations!)\n'
        '•  **"How does the Live Map work?"** (Karachi & Pakistan areas)\n'
        '•  **"How to send voice messages to farmers?"**\n'
        '•  **"How to place an order with Cash on Delivery?"**\n'
        '•  **"Storage tips for vegetables"**\n\n'
        'Please feel free to ask your question below!';
  }

  static bool _isGreeting(String message) {
    final greetings = [
      'hi',
      'hello',
      'hey',
      'salam',
      'assalam',
      'aoa',
      'good morning',
      'good afternoon',
      'good evening',
      'kaise ho',
      'kese ho',
      'help',
      'start',
    ];
    return greetings.any((g) => message == g || message.startsWith('$g '));
  }

  static bool _isThanks(String message) {
    final thanks = [
      'thank',
      'thanks',
      'thank you',
      'thanku',
      'shukriya',
      'shukria',
      'meherbani',
      'jazakallah',
    ];
    return thanks.any((t) => message.contains(t));
  }

  // Get welcome message
  static String getWelcomeMessage() {
    return ' **Welcome to HarvestHub Assistant!** \n\n'
        'I\'m here to help you explore everything:\n'
        '•  **Live Product Availability**: Ask *"Do you have apples?"* or *"What is the price of tomatoes?"* to see live farmer stocks & prices!\n'
        '•  **Live Farmers Map**: Discover local markets in Karachi & across Pakistan\n'
        '•  **Farmer Chat & Voice Notes**: Connect directly with verified growers\n'
        '•  **Orders & Delivery**: Home delivery & Cash on Delivery tracking\n'
        '•  **Freshness & Storage Tips**: Food science & storage guides\n\n'
        'Type your question below or pick a suggested question! ';
  }

  // Get suggested questions
  static List<String> getSuggestedQuestions() {
    return [
      'Do you have apples or fresh fruits?',
      'Which vegetables are available today?',
      'How to use the Live Farmers Map in Karachi?',
      'How to chat or send voice messages to farmers?',
      'How to place an order and delivery time?',
      'How do farmers get verified badges?',
    ];
  }
}
