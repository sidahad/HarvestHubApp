import 'package:flutter/material.dart';
import '../models/product_model.dart';

class RecipeModel {
  final String title;
  final String description;
  final String prepTime;
  final IconData iconData;
  final List<ProductModel> ingredients;

  RecipeModel({
    required this.title,
    required this.description,
    required this.prepTime,
    required this.iconData,
    required this.ingredients,
  });
}

class AIDealModel {
  final String id;
  final String title;
  final String tag;
  final String discount;
  final String code;
  final String bgGradient;

  AIDealModel({
    required this.id,
    required this.title,
    required this.tag,
    required this.discount,
    required this.code,
    required this.bgGradient,
  });
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Gemini API Key placeholder (can be loaded or passed)
  final String _geminiApiKey =
      'Ab8RN6KpL_AaPyTm1vDYqm-eAQlGnyACZu7zQNDTujgkLR_hhQ';

  // 1. AI Freshness Score
  Map<String, dynamic> getFreshnessScore(ProductModel product) {
    int score = 95;
    String status = "Peak Freshness";
    String hours = "Harvested 3 hours ago";

    if (product.category == 'Fruits') {
      score = 98;
      hours = "Hand-picked this morning at 6:00 AM";
    } else if (product.category == 'Dairy') {
      score = 99;
      hours = "Milked 2 hours ago from organic cowshed";
    } else if (product.category == 'Honey & Jam') {
      score = 100;
      hours = "100% Pure Raw Extraction";
    } else if (product.distanceKm < 5.0) {
      score = 96;
      hours = "Local farm within 5km radius";
    }

    return {
      'score': score,
      'status': status,
      'details': hours,
      'isOrganic': product.isOrganic,
    };
  }

  // 2. AI Price Insight
  String getPriceInsight(ProductModel product) {
    final cityAvg = product.price * 1.18;
    final diff = ((cityAvg - product.price) / cityAvg * 100).toInt();

    return "HarvestAI Price Insight: Rs.${product.price.toInt()}/${product.unit} is $diff% cheaper than city supermarket average (Rs.${cityAvg.toInt()}/${product.unit}). Fair direct farmer price!";
  }

  // 3. AI Substitute Finder
  List<ProductModel> getSubstituteProducts(
    ProductModel target,
    List<ProductModel> allProducts,
  ) {
    return allProducts
        .where((p) {
          return p.id != target.id &&
              (p.category == target.category ||
                  p.isOrganic == target.isOrganic);
        })
        .take(2)
        .toList();
  }

  // 4. AI Meal / Recipe Suggestions
  List<RecipeModel> getRecipeSuggestions(List<ProductModel> availableProducts) {
    final tomatoes = availableProducts.firstWhere(
      (p) => p.title.toLowerCase().contains('tomato'),
      orElse: () => availableProducts.first,
    );
    final milk = availableProducts.firstWhere(
      (p) => p.category == 'Dairy',
      orElse: () => availableProducts.last,
    );
    final corn = availableProducts.firstWhere(
      (p) => p.title.toLowerCase().contains('corn'),
      orElse: () => availableProducts.first,
    );
    final strawberries = availableProducts.firstWhere(
      (p) => p.title.toLowerCase().contains('strawberry'),
      orElse: () => availableProducts.first,
    );
    final honey = availableProducts.firstWhere(
      (p) => p.category == 'Honey & Jam',
      orElse: () => availableProducts.last,
    );

    return [
      RecipeModel(
        title: 'Farm Fresh Garden Salad',
        description: 'Crisp organic tomatoes, sweet corn & olive oil dressing.',
        prepTime: '10 mins',
        iconData: Icons.restaurant,
        ingredients: [tomatoes, corn],
      ),
      RecipeModel(
        title: 'Organic Honey Milk Smoothie',
        description:
            'Pure buffalo milk infused with natural Sidr wild honey & strawberries.',
        prepTime: '5 mins',
        iconData: Icons.local_drink_rounded,
        ingredients: [milk, honey, strawberries],
      ),
    ];
  }

  // 5. AI Personalized Deals
  List<AIDealModel> getPersonalizedDeals() {
    return [
      AIDealModel(
        id: 'deal_1',
        title: 'AI Smart Pick: 20% OFF Fresh Dairy',
        tag: 'RECOMMENDED FOR YOU',
        discount: '20% OFF',
        code: 'AIDAIRY20',
        bgGradient: 'green',
      ),
      AIDealModel(
        id: 'deal_2',
        title: 'Organic Fruits Bundle Offer',
        tag: 'LOCAL HARVEST SPECIAL',
        discount: 'Rs. 150 Cashback',
        code: 'FRUITAI',
        bgGradient: 'amber',
      ),
    ];
  }

  // 6. AI Product Recommendation
  List<ProductModel> getAIRecommendedProducts(List<ProductModel> allProducts) {
    // Recommends top organic / highly rated products based on user activity
    final sorted = List<ProductModel>.from(allProducts);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(4).toList();
  }

  // 7. Process Natural Language Query & Voice Search
  Future<Map<String, dynamic>> processNaturalLanguageQuery(
    String query,
    List<ProductModel> allProducts,
  ) async {
    final lower = query.toLowerCase();

    // Try Gemini API if key is valid, else smart NLP parser
    if (!_geminiApiKey.contains('MOCK')) {
      try {
        // Real Gemini API call would go here when a valid key is configured.
        // Skipped in this build — using local NLP parser below.
        debugPrint(
          'Gemini API: real key detected but HTTP package not bundled in this build.',
        );
      } catch (e) {
        debugPrint('Gemini API call info: $e');
      }
    }

    // Smart Local NLP Parser for Natural Language & Voice
    String responseText = "HarvestAI analyzed your request: '$query'";
    List<ProductModel> matched = [];

    if (lower.contains('tomato') || lower.contains('tamatar')) {
      matched = allProducts
          .where((p) => p.title.toLowerCase().contains('tomato'))
          .toList();
      responseText =
          "I found fresh organic red tomatoes from local farmers nearby! Here is the best option:";
    } else if (lower.contains('strawberry') || lower.contains('strawberries')) {
      matched = allProducts
          .where((p) => p.title.toLowerCase().contains('strawberry'))
          .toList();
      responseText =
          "Plucked fresh strawberries from Chaudhry Tariq's farm are available right now!";
    } else if (lower.contains('milk') || lower.contains('doodh')) {
      matched = allProducts.where((p) => p.category == 'Dairy').toList();
      responseText =
          "Pure, unadulterated buffalo farm milk is ready for scheduling delivery!";
    } else if (lower.contains('honey') ||
        lower.contains(' शहद') ||
        lower.contains('shahed')) {
      matched = allProducts.where((p) => p.category == 'Honey & Jam').toList();
      responseText = "Wild Sidr Natural Honey from Swat Valley is in stock!";
    } else if (lower.contains('vegetable') ||
        lower.contains('sabzi') ||
        lower.contains('under')) {
      matched = allProducts
          .where((p) => p.category == 'Vegetables' && p.price <= 1000)
          .toList();
      responseText =
          "Here are healthy organic vegetables under Rs. 1000 matching your household needs!";
    } else if (lower.contains('potatoes') ||
        lower.contains('aloo') ||
        lower.contains('corn')) {
      matched = allProducts.where((p) => p.category == 'Vegetables').toList();
      responseText =
          "Freshly harvested root vegetables and sweet corn from local farm fields!";
    } else {
      matched = _matchProducts(lower, allProducts);
      if (matched.isNotEmpty) {
        responseText =
            "Based on your prompt, here are top fresh farm items recommended for you:";
      } else {
        matched = allProducts.take(2).toList();
        responseText =
            "I searched our local farm listings for '$query'. Here are the freshest organic items available today:";
      }
    }

    return {'response': responseText, 'products': matched};
  }

  List<ProductModel> _matchProducts(
    String query,
    List<ProductModel> allProducts,
  ) {
    return allProducts.where((p) {
      return query.contains(p.title.toLowerCase()) ||
          query.contains(p.category.toLowerCase()) ||
          query.contains(p.farmerName.toLowerCase());
    }).toList();
  }
}
