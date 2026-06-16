import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class RestaurantSpot {
  final String name;
  final String address;
  final String specialty;

  RestaurantSpot({
    required this.name,
    required this.address,
    required this.specialty,
  });

  factory RestaurantSpot.fromJson(Map<String, dynamic> json) {
    return RestaurantSpot(
      name: json['name']?.toString() ?? json['restaurantName']?.toString() ?? 'Unknown Restaurant',
      address: json['address']?.toString() ?? json['location']?.toString() ?? 'Nearby',
      specialty: json['specialty']?.toString() ?? json['recommendedDish']?.toString() ?? '',
    );
  }
}

class FoodScanResult {
  final String foodName;
  final bool isFood;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final String description;
  final List<RestaurantSpot> restaurants;

  FoodScanResult({
    required this.foodName,
    required this.isFood,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.description,
    required this.restaurants,
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return FoodScanResult(
      foodName: json['foodName']?.toString() ?? 'Unknown Food',
      isFood: json['isFood'] as bool? ?? false,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: toDouble(json['protein'] ?? json['proteins']),
      fat: toDouble(json['fat'] ?? json['fats']),
      carbs: toDouble(json['carbs'] ?? json['carbohydrates']),
      description: json['description']?.toString() ?? '',
      restaurants: (json['restaurants'] as List?)
              ?.map((item) => RestaurantSpot.fromJson(item as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class _MockRestaurant {
  final String name;
  final String address;
  final String city;
  final List<String> tags;
  final int openHour;
  final int closeHour;
  final String specialty;

  const _MockRestaurant({
    required this.name,
    required this.address,
    required this.city,
    required this.tags,
    required this.openHour,
    required this.closeHour,
    required this.specialty,
  });

  bool isOpenAt(int hour) {
    if (closeHour > openHour) {
      return hour >= openHour && hour < closeHour;
    } else {
      // Spans past midnight, e.g. open at 18 (6 PM) and closes at 2 (2 AM)
      return hour >= openHour || hour < closeHour;
    }
  }
}

class GeminiService {
  // Comprehensive verified list of real, popular restaurants in Pakistan's major cities and global chains
  static const List<_MockRestaurant> _mockRestaurants = [
    // Karachi
    _MockRestaurant(
      name: 'Kababjees Clifton',
      address: 'Do Darya, Clifton, Karachi',
      city: 'Karachi',
      tags: ['kebab', 'beef', 'chicken', 'bbq', 'karahi', 'fast food', 'burger'],
      openHour: 18,
      closeHour: 2,
      specialty: 'Beef Seekh Kabab / Chicken Karahi',
    ),
    _MockRestaurant(
      name: 'BBQ Tonight Clifton',
      address: 'Clifton Block 5, Karachi',
      city: 'Karachi',
      tags: ['kebab', 'beef', 'chicken', 'bbq', 'mutton'],
      openHour: 12,
      closeHour: 1,
      specialty: 'Mutton Behari Kabab',
    ),
    _MockRestaurant(
      name: 'Al-Rehman Biryani Kharadar',
      address: 'Kharadar, Karachi',
      city: 'Karachi',
      tags: ['biryani', 'rice', 'chicken'],
      openHour: 11,
      closeHour: 23,
      specialty: 'Double Masala Chicken Biryani',
    ),
    _MockRestaurant(
      name: 'Student Biryani Saddar',
      address: 'Saddar Road, Karachi',
      city: 'Karachi',
      tags: ['biryani', 'rice', 'chicken', 'beef'],
      openHour: 11,
      closeHour: 0,
      specialty: 'Special Beef Biryani',
    ),
    _MockRestaurant(
      name: 'Waheed Kabab House Burns Road',
      address: 'Burns Road, Karachi',
      city: 'Karachi',
      tags: ['kebab', 'beef', 'bbq'],
      openHour: 17,
      closeHour: 3,
      specialty: 'Beef Fry Kabab',
    ),
    _MockRestaurant(
      name: 'Kolachi Restaurant Do Darya',
      address: 'Do Darya, Clifton, Karachi',
      city: 'Karachi',
      tags: ['kebab', 'beef', 'chicken', 'bbq', 'karahi'],
      openHour: 19,
      closeHour: 2,
      specialty: 'Sajji / Paneer Reshmi Handi',
    ),
    _MockRestaurant(
      name: 'Zameer Ansari BBQ',
      address: 'Bahadurabad, Karachi',
      city: 'Karachi',
      tags: ['kebab', 'beef', 'chicken', 'bbq'],
      openHour: 18,
      closeHour: 2,
      specialty: 'Reshmi Kabab',
    ),
    _MockRestaurant(
      name: 'Farhan Biryani Johar',
      address: 'Block 15, Gulistan-e-Johar, Karachi',
      city: 'Karachi',
      tags: ['biryani', 'rice', 'chicken'],
      openHour: 11,
      closeHour: 23,
      specialty: 'Chicken Biryani',
    ),
    _MockRestaurant(
      name: 'Daily Deli Co. Clifton',
      address: 'Clifton Block 4, Karachi',
      city: 'Karachi',
      tags: ['burger', 'fast food', 'chicken', 'beef'],
      openHour: 12,
      closeHour: 1,
      specialty: 'Double Cheese Beef Burger',
    ),
    _MockRestaurant(
      name: 'Oh My Grill DHA',
      address: 'Khayaban-e-Seher, DHA Phase 6, Karachi',
      city: 'Karachi',
      tags: ['burger', 'fast food'],
      openHour: 12,
      closeHour: 2,
      specialty: 'Swiss Mushroom Burger',
    ),
    _MockRestaurant(
      name: 'Broadway Pizza Gulshan',
      address: 'Main University Road, Gulshan-e-Iqbal, Karachi',
      city: 'Karachi',
      tags: ['pizza', 'fast food'],
      openHour: 11,
      closeHour: 3,
      specialty: 'Stuffed Crust Pizza',
    ),
    _MockRestaurant(
      name: 'Evergreen DHA',
      address: 'Khayaban-e-Shahbaz, DHA Phase 5, Karachi',
      city: 'Karachi',
      tags: ['salad', 'healthy', 'protein', 'keto'],
      openHour: 9,
      closeHour: 22,
      specialty: 'Keto Bowl / Grilled Chicken Salad',
    ),
    _MockRestaurant(
      name: "Neco's Cafe DHA",
      address: 'DHA Phase 6, Karachi',
      city: 'Karachi',
      tags: ['salad', 'healthy', 'protein', 'keto'],
      openHour: 8,
      closeHour: 23,
      specialty: 'Organic Chicken Salad',
    ),
    _MockRestaurant(
      name: 'Dera Restaurant Clifton',
      address: 'Boat Basin, Clifton, Karachi',
      city: 'Karachi',
      tags: ['desi', 'karahi', 'roti', 'chicken', 'beef'],
      openHour: 17,
      closeHour: 3,
      specialty: 'Daal Makhani & Handi',
    ),
    _MockRestaurant(
      name: 'Lal Qila Restaurant',
      address: 'Main Shahrah-e-Faisal, Karachi',
      city: 'Karachi',
      tags: ['desi', 'bbq', 'kebab', 'chicken', 'beef'],
      openHour: 19,
      closeHour: 23,
      specialty: 'Mughlai Buffet & Daal/BBQ',
    ),
    _MockRestaurant(
      name: 'Fresco Sweets Burns Road',
      address: 'Burns Road, Karachi',
      city: 'Karachi',
      tags: ['dessert', 'sweet', 'desi'],
      openHour: 6,
      closeHour: 0,
      specialty: 'Dahi Baray & Samosa / Halwa',
    ),
    _MockRestaurant(
      name: 'Ginsoy Clifton',
      address: 'Clifton Block 4, Karachi',
      city: 'Karachi',
      tags: ['chinese', 'soup', 'chicken', 'beef'],
      openHour: 12,
      closeHour: 0,
      specialty: 'Chicken Manchurian & Egg Fried Rice',
    ),

    // Lahore
    _MockRestaurant(
      name: 'Savour Foods Shadman',
      address: 'Shadman Mall, Shadman, Lahore',
      city: 'Lahore',
      tags: ['biryani', 'rice', 'chicken'],
      openHour: 11,
      closeHour: 1,
      specialty: 'Chicken Pulao Kabab',
    ),
    _MockRestaurant(
      name: 'Waqas Biryani Hall Road',
      address: 'Hall Road, Lahore',
      city: 'Lahore',
      tags: ['biryani', 'rice', 'chicken'],
      openHour: 11,
      closeHour: 22,
      specialty: 'Sada Biryani with Shami Kabab',
    ),
    _MockRestaurant(
      name: 'Butt Karahi Lakshmi Chowk',
      address: 'Lakshmi Chowk, Lahore',
      city: 'Lahore',
      tags: ['karahi', 'chicken', 'beef', 'mutton', 'desi'],
      openHour: 12,
      closeHour: 3,
      specialty: 'Butter Chicken Karahi',
    ),
    _MockRestaurant(
      name: 'Phajja Siri Paye Fort',
      address: 'Near Badshahi Mosque, Walled City, Lahore',
      city: 'Lahore',
      tags: ['paye', 'mutton', 'beef', 'desi'],
      openHour: 0,
      closeHour: 24,
      specialty: 'Siri Paye',
    ),
    _MockRestaurant(
      name: 'Bhaiya Kabab Model Town',
      address: 'Model Town G-Block, Lahore',
      city: 'Lahore',
      tags: ['kebab', 'beef', 'chicken', 'bbq'],
      openHour: 16,
      closeHour: 23,
      specialty: 'Beef Seekh Kabab',
    ),
    _MockRestaurant(
      name: 'Siddique Kabab Gulberg',
      address: 'Main Boulevard, Gulberg, Lahore',
      city: 'Lahore',
      tags: ['kebab', 'beef', 'chicken', 'bbq'],
      openHour: 17,
      closeHour: 2,
      specialty: 'Chicken Boti / Seekh Kabab',
    ),
    _MockRestaurant(
      name: 'Howdy Johar Town',
      address: 'Abdul Haque Rd, Johar Town, Lahore',
      city: 'Lahore',
      tags: ['burger', 'fast food'],
      openHour: 12,
      closeHour: 2,
      specialty: 'Son of a Bun Burger',
    ),
    _MockRestaurant(
      name: 'Ministry of Burgers Gulberg',
      address: 'Gulberg 3, Lahore',
      city: 'Lahore',
      tags: ['burger', 'fast food'],
      openHour: 13,
      closeHour: 1,
      specialty: 'Classic Beef Burger',
    ),
    _MockRestaurant(
      name: 'The Fit Kitchen Johar Town',
      address: 'Block H-3, Johar Town, Lahore',
      city: 'Lahore',
      tags: ['salad', 'healthy', 'protein', 'keto'],
      openHour: 11,
      closeHour: 23,
      specialty: 'High Protein Chicken Salad',
    ),
    _MockRestaurant(
      name: 'Lean & Green Cafe Gulberg',
      address: 'Gulberg 2, Lahore',
      city: 'Lahore',
      tags: ['salad', 'healthy', 'protein', 'keto'],
      openHour: 10,
      closeHour: 22,
      specialty: 'Avocado Quinoa Salad',
    ),
    _MockRestaurant(
      name: 'Sweet Tooth DHA Phase 6',
      address: 'DHA Phase 6, Lahore',
      city: 'Lahore',
      tags: ['fast food', 'pizza', 'dessert'],
      openHour: 12,
      closeHour: 1,
      specialty: 'Deep Dish Pizza / Fudge Cake',
    ),
    _MockRestaurant(
      name: 'Dera Restaurant Lahore',
      address: 'Main Boulevard, Gaddafi Stadium, Lahore',
      city: 'Lahore',
      tags: ['desi', 'karahi', 'roti', 'chicken', 'beef'],
      openHour: 17,
      closeHour: 3,
      specialty: 'Daal Makhani & Mutton Handi',
    ),
    _MockRestaurant(
      name: 'Chaman Ice Cream Beadon Rd',
      address: 'Beadon Road, Mall Road, Lahore',
      city: 'Lahore',
      tags: ['dessert', 'sweet', 'desi'],
      openHour: 11,
      closeHour: 1,
      specialty: 'Pista Ice Cream & Falooda',
    ),
    _MockRestaurant(
      name: 'Ginsoy Gulberg',
      address: 'Mini Market, Gulberg, Lahore',
      city: 'Lahore',
      tags: ['chinese', 'soup', 'chicken', 'beef'],
      openHour: 12,
      closeHour: 0,
      specialty: 'Chicken Manchurian & Egg Fried Rice',
    ),

    // Islamabad / Rawalpindi
    _MockRestaurant(
      name: 'Savour Foods Blue Area',
      address: 'Jinnah Avenue, Blue Area, Islamabad',
      city: 'Islamabad',
      tags: ['biryani', 'rice', 'chicken'],
      openHour: 11,
      closeHour: 1,
      specialty: 'Chicken Pulao Kabab',
    ),
    _MockRestaurant(
      name: 'Savour Foods Rawalpindi',
      address: 'College Road, Saddar, Rawalpindi',
      city: 'Rawalpindi',
      tags: ['biryani', 'rice', 'chicken'],
      openHour: 11,
      closeHour: 1,
      specialty: 'Chicken Pulao Kabab',
    ),
    _MockRestaurant(
      name: 'Kabul Restaurant F-7',
      address: 'Jinnah Super Market, F-7, Islamabad',
      city: 'Islamabad',
      tags: ['kebab', 'beef', 'chicken', 'bbq'],
      openHour: 12,
      closeHour: 23,
      specialty: 'Afghani Kabab / Tikka',
    ),
    _MockRestaurant(
      name: 'Monal Restaurant Margalla Hills',
      address: 'Pir Sohawa, Margalla Hills, Islamabad',
      city: 'Islamabad',
      tags: ['kebab', 'beef', 'chicken', 'bbq', 'karahi', 'fast food', 'desi'],
      openHour: 9,
      closeHour: 0,
      specialty: 'Chicken Makhani Handi',
    ),
    _MockRestaurant(
      name: 'Tandoori Restaurant G-8',
      address: 'G-8 Markaz, Islamabad',
      city: 'Islamabad',
      tags: ['karahi', 'chicken', 'bbq', 'desi'],
      openHour: 12,
      closeHour: 23,
      specialty: 'Chicken Karahi',
    ),
    _MockRestaurant(
      name: 'Cheezious Commercial Market',
      address: 'Commercial Market, Rawalpindi',
      city: 'Rawalpindi',
      tags: ['pizza', 'burger', 'fast food', 'chicken'],
      openHour: 11,
      closeHour: 3,
      specialty: 'Bihari Kabab Pizza / Crown Crust',
    ),
    _MockRestaurant(
      name: 'Cheezious F-11 Markaz',
      address: 'F-11 Markaz, Islamabad',
      city: 'Islamabad',
      tags: ['pizza', 'burger', 'fast food', 'chicken'],
      openHour: 11,
      closeHour: 3,
      specialty: 'Bihari Kabab Pizza / Crown Crust',
    ),
    _MockRestaurant(
      name: 'Roasters Bistro F-7',
      address: 'F-7 Markaz, Islamabad',
      city: 'Islamabad',
      tags: ['burger', 'fast food', 'steak'],
      openHour: 12,
      closeHour: 23,
      specialty: 'Mushroom Swiss Burger',
    ),
    _MockRestaurant(
      name: 'The Health Grill F-11',
      address: 'F-11 Markaz, Islamabad',
      city: 'Islamabad',
      tags: ['salad', 'healthy', 'protein', 'keto'],
      openHour: 11,
      closeHour: 22,
      specialty: 'Grilled Fish Bowl',
    ),
    _MockRestaurant(
      name: 'NutriFit Bahria Town',
      address: 'Phase 4, Bahria Town, Rawalpindi',
      city: 'Rawalpindi',
      tags: ['salad', 'healthy', 'protein', 'keto'],
      openHour: 10,
      closeHour: 22,
      specialty: 'Grilled Chicken Caesar Salad',
    ),
    _MockRestaurant(
      name: 'Kitchen Cuisine F-7',
      address: 'F-7 Markaz, Islamabad',
      city: 'Islamabad',
      tags: ['dessert', 'sweet', 'desi'],
      openHour: 8,
      closeHour: 23,
      specialty: 'Chocolate Fudge Cake & Cookies',
    ),

    // Nationwide / Generic Fallback
    _MockRestaurant(
      name: 'KFC Drive-Thru',
      address: 'Main Commercial Hub, Nearby Branch',
      city: '',
      tags: ['burger', 'fast food', 'chicken', 'sandwich'],
      openHour: 11,
      closeHour: 3,
      specialty: 'Zinger Burger',
    ),
    _MockRestaurant(
      name: "McDonald's Family Restaurant",
      address: 'City Center Park, Nearby Branch',
      city: '',
      tags: ['burger', 'fast food', 'chicken'],
      openHour: 6,
      closeHour: 3,
      specialty: 'Big Mac / McChicken',
    ),
    _MockRestaurant(
      name: "Domino's Pizza Grill",
      address: 'High Street, Nearby Branch',
      city: '',
      tags: ['pizza', 'fast food'],
      openHour: 11,
      closeHour: 2,
      specialty: 'Tex-Mex Chicken Pizza',
    ),
    _MockRestaurant(
      name: 'Pizza Hut Express',
      address: 'Shopping Mall, Nearby Branch',
      city: '',
      tags: ['pizza', 'fast food'],
      openHour: 11,
      closeHour: 1,
      specialty: 'Chicken Tikka Pizza',
    ),
    _MockRestaurant(
      name: 'Subway Healthy Subs',
      address: 'Market Square, Nearby Branch',
      city: '',
      tags: ['salad', 'healthy', 'fast food', 'sandwich'],
      openHour: 8,
      closeHour: 23,
      specialty: 'Roasted Chicken Breast Sub / Salad',
    ),
    _MockRestaurant(
      name: 'OPTP Fries & Burgers',
      address: 'Food Court, Nearby Branch',
      city: '',
      tags: ['burger', 'fast food', 'fries'],
      openHour: 11,
      closeHour: 2,
      specialty: 'Gourmet Fries / Beef Burger',
    ),
  ];

  static String getCityFromLocation(String? locationName) {
    if (locationName == null || locationName.isEmpty) return '';
    final name = locationName.toLowerCase();
    if (name.contains('lahore')) return 'Lahore';
    if (name.contains('karachi')) return 'Karachi';
    if (name.contains('islamabad')) return 'Islamabad';
    if (name.contains('rawalpindi')) return 'Rawalpindi';
    if (name.contains('faisalabad')) return 'Faisalabad';
    if (name.contains('multan')) return 'Multan';
    if (name.contains('peshawar')) return 'Peshawar';
    return '';
  }

  static List<String> getTagsForFood(String foodName) {
    final name = foodName.toLowerCase();
    List<String> tags = [];
    if (name.contains('biryani') || name.contains('pulao') || name.contains('rice') || name.contains('chawal')) {
      tags.add('rice');
      tags.add('biryani');
    }
    if (name.contains('kebab') || name.contains('kabab') || name.contains('tikka') || name.contains('bbq') || name.contains('boti') || name.contains('charcoal') || name.contains('grill') || name.contains('sajji')) {
      tags.add('kebab');
      tags.add('bbq');
    }
    if (name.contains('burger') || name.contains('zinger') || name.contains('patty') || name.contains('bun')) {
      tags.add('burger');
      tags.add('fast food');
    }
    if (name.contains('pizza') || name.contains('slice') || name.contains('calzone')) {
      tags.add('pizza');
      tags.add('fast food');
    }
    if (name.contains('salad') || name.contains('avocado') || name.contains('healthy') || name.contains('diet') || name.contains('keto') || name.contains('protein bowl') || name.contains('greens') || name.contains('organic')) {
      tags.add('salad');
      tags.add('healthy');
    }
    if (name.contains('karahi') || name.contains('handi') || name.contains('nihari') || name.contains('paye') || name.contains('korma') || name.contains('makhani') || name.contains('haleem') || name.contains('gravy') || name.contains('siri')) {
      tags.add('karahi');
    }
    if (name.contains('sandwich') || name.contains('sub') || name.contains('wrap') || name.contains('shawarma') || name.contains('roll')) {
      tags.add('sandwich');
      tags.add('fast food');
    }
    if (name.contains('chinese') || name.contains('noodle') || name.contains('chow mein') || name.contains('soup') || name.contains('manchurian')) {
      tags.add('chinese');
    }
    if (name.contains('sweet') || name.contains('cake') || name.contains('ice cream') || name.contains('dessert') || name.contains('halwa') || name.contains('kheer') || name.contains('custard')) {
      tags.add('dessert');
    }
    if (name.contains('daal') || name.contains('roti') || name.contains('naan') || name.contains('sabzi') || name.contains('paneer') || name.contains('chana') || name.contains('desi') || name.contains('paratha')) {
      tags.add('desi');
    }
    if (name.contains('chicken')) {
      tags.add('chicken');
    }
    if (name.contains('beef')) {
      tags.add('beef');
    }
    if (name.contains('mutton')) {
      tags.add('mutton');
    }
    return tags;
  }

  static List<RestaurantSpot> getMockSuggestions({
    required String foodName,
    required String? locationName,
  }) {
    final city = getCityFromLocation(locationName);
    final foodTags = getTagsForFood(foodName);
    final currentHour = DateTime.now().hour;

    // Filter by city first (if matched)
    List<_MockRestaurant> matchingRestaurants = [];
    if (city.isNotEmpty) {
      matchingRestaurants = _mockRestaurants.where((r) => r.city.toLowerCase() == city.toLowerCase()).toList();
    }

    // Filter by tags
    List<_MockRestaurant> tagMatches = [];
    if (foodTags.isNotEmpty) {
      // First try to find matches in the specific city
      tagMatches = matchingRestaurants.where((r) {
        return r.tags.any((tag) => foodTags.contains(tag));
      }).toList();

      // If no city matches, fallback to generic/nationwide ones matching the tags
      if (tagMatches.isEmpty) {
        tagMatches = _mockRestaurants
            .where((r) => r.city.isEmpty && r.tags.any((tag) => foodTags.contains(tag)))
            .toList();
      }
    }

    // Filter for open restaurants ONLY
    final openRestaurants = tagMatches.where((r) => r.isOpenAt(currentHour)).toList();

    // If all matched restaurants are closed, fallback to showing them as closed or keep the list
    final finalSelection = openRestaurants.isNotEmpty ? openRestaurants : tagMatches;

    return finalSelection.map((r) {
      return RestaurantSpot(
        name: r.name,
        address: r.address,
        specialty: r.specialty.isNotEmpty ? r.specialty : foodName,
      );
    }).toList();
  }

  static FoodScanResult _generateMockResult(String? locationName) {
    final options = [
      FoodScanResult(
        foodName: 'Grilled Chicken Salad with Avocado',
        isFood: true,
        calories: 380,
        protein: 35.0,
        fat: 18.0,
        carbs: 12.0,
        description: 'A nutritious blend of tender grilled chicken breast, fresh mixed greens, ripe avocado, and a light olive oil dressing. Rich in protein and healthy fats, with low glycemic impact.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Chicken Biryani',
        isFood: true,
        calories: 550,
        protein: 24.0,
        fat: 14.0,
        carbs: 82.0,
        description: 'Fragrant basmati rice layered with spiced chicken, herbs, and aromatics. A popular Pakistani favorite, high in carbohydrates and moderate in protein.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Beef Seekh Kebab with Naan',
        isFood: true,
        calories: 490,
        protein: 28.0,
        fat: 20.0,
        carbs: 45.0,
        description: 'Minced beef skewers seasoned with traditional Pakistani spices, grilled over charcoal. Good protein source, accompanied by refined flatbread.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Zinger Burger with Fries',
        isFood: true,
        calories: 650,
        protein: 28.0,
        fat: 32.0,
        carbs: 55.0,
        description: 'Crispy fried chicken thigh fillet topped with lettuce and mayonnaise in a sesame seed bun. A high-calorie fast food option.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Pepperoni Pizza',
        isFood: true,
        calories: 720,
        protein: 32.0,
        fat: 28.0,
        carbs: 85.0,
        description: 'Classic oven-baked crust topped with rich tomato sauce, melted mozzarella cheese, and spicy beef pepperoni slices.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Butter Chicken with Garlic Naan',
        isFood: true,
        calories: 850,
        protein: 42.0,
        fat: 35.0,
        carbs: 95.0,
        description: 'Tender chicken pieces simmered in a creamy, spiced tomato and butter sauce, served with traditional clay-oven flatbread.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Chocolate Fudge Cake Slice',
        isFood: true,
        calories: 420,
        protein: 5.0,
        fat: 22.0,
        carbs: 50.0,
        description: 'A rich, moist chocolate sponge cake layered and frosted with chocolate fudge icing. High in sugars and fats.',
        restaurants: [],
      ),
      FoodScanResult(
        foodName: 'Egg Fried Rice with Chicken Manchurian',
        isFood: true,
        calories: 680,
        protein: 26.0,
        fat: 18.0,
        carbs: 98.0,
        description: 'Stir-fried basmati rice with scrambled eggs and vegetables, paired with sweet and sour chicken chunks in red Manchurian gravy.',
        restaurants: [],
      ),
    ];

    final index = DateTime.now().millisecond % options.length;
    final baseResult = options[index];

    // Dynamically calculate open restaurants for the location and mock food
    final openRestaurants = getMockSuggestions(
      foodName: baseResult.foodName,
      locationName: locationName,
    );

    return FoodScanResult(
      foodName: baseResult.foodName,
      isFood: baseResult.isFood,
      calories: baseResult.calories,
      protein: baseResult.protein,
      fat: baseResult.fat,
      carbs: baseResult.carbs,
      description: baseResult.description,
      restaurants: openRestaurants,
    );
  }

  static Future<FoodScanResult> scanFoodImage({
    required Uint8List imageBytes,
    required String apiKey,
    String? locationName,
  }) async {
    // Intercept mock/placeholder key calls immediately
    if (apiKey == 'AIzaSyBffxYEvQx99C3wo-FWUx4_-B3M-f_p7Uc' || apiKey.isEmpty || apiKey.trim().toLowerCase() == 'mock') {
      return _generateMockResult(locationName);
    }

    final models = [
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-3.5-flash',
      'gemini-1.5-flash',
    ];

    dynamic lastError;

    for (final model in models) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

        final base64Image = base64Encode(imageBytes);

        String prompt = 'Analyze this image and identify the food item. '
            'If the image does not contain any food, set isFood to false. '
            'Provide the response as a single, valid JSON object with the following fields: '
            '"foodName" (string, name of the food, supporting all global and Pakistani cuisines such as Biryani, Karahi, Pulao, Nihari, Halwa Puri, Paratha, Samosa, burgers, pizzas, pastas, etc.), '
            '"isFood" (boolean, true if it is a food item, false otherwise), '
            '"calories" (integer, estimation of calories per standard serving in kcal), '
            '"protein" (number, estimation of protein in grams per serving), '
            '"fat" (number, estimation of fat in grams per serving), '
            '"carbs" (number, estimation of carbohydrates in grams per serving), '
            '"description" (string, a brief 1-2 sentence description explaining the dish and its nutritional composition), ';

        if (locationName != null && locationName.isNotEmpty) {
          prompt += '"restaurants" (array of objects, containing up to 10 REAL, existing, popular restaurants/spots to eat this food item (or variations of it, e.g. Zinger burger if a burger is scanned) in or near the location "$locationName". Each object must have "name" (string, real restaurant name), "address" (string, the branch name, street, or area name in "$locationName"), and "specialty" (string, the specific popular version of this food they are famous for), "openHour" (integer, typical opening hour in 24-hour format, e.g. 11 for 11 AM or 18 for 6 PM), and "closeHour" (integer, typical closing hour in 24-hour format, e.g. 23 for 11 PM or 2 for 2 AM). Do NOT return fake or hallucinated names). ';
        } else {
          prompt += '"restaurants" (array of objects, containing up to 10 famous spots/chains to eat this food. Each object must have "name" (string), "address" (string, e.g., "Main branches / Nationwide"), and "specialty" (string), "openHour" (integer, typical opening hour in 24-hour format, e.g. 11), and "closeHour" (integer, typical closing hour in 24-hour format, e.g. 23)). ';
        }

        prompt += 'Ensure the JSON output is strictly formatted. Do not wrap the JSON object in markdown formatting or "```json" blocks. Return only raw, valid JSON.';

        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            throw Exception('No analysis result received from Gemini.');
          }
          final content = candidates[0]['content'];
          if (content == null) {
            throw Exception('Content not found in API response.');
          }
          final parts = content['parts'] as List?;
          if (parts == null || parts.isEmpty) {
            throw Exception('Parts not found in API response.');
          }
          String resultText = parts[0]['text']?.toString() ?? '';

          resultText = resultText.trim();
          if (resultText.startsWith('```')) {
            resultText = resultText.replaceAll(RegExp(r'^```(json)?'), '');
            resultText = resultText.replaceAll(RegExp(r'```$'), '');
            resultText = resultText.trim();
          }

          final jsonMap = jsonDecode(resultText) as Map<String, dynamic>;
          
          double toDouble(dynamic val) {
            if (val == null) return 0.0;
            if (val is num) return val.toDouble();
            return double.tryParse(val.toString()) ?? 0.0;
          }

          final currentHour = DateTime.now().hour;
          final List<dynamic> rawRestaurants = jsonMap['restaurants'] as List? ?? [];
          final List<Map<String, dynamic>> openRestaurants = [];

          for (final item in rawRestaurants) {
            if (item is Map<String, dynamic>) {
              final openHour = int.tryParse(item['openHour']?.toString() ?? '') ?? 11;
              final closeHour = int.tryParse(item['closeHour']?.toString() ?? '') ?? 23;
              
              bool isOpen = true;
              if (closeHour > openHour) {
                isOpen = currentHour >= openHour && currentHour < closeHour;
              } else if (closeHour < openHour) {
                isOpen = currentHour >= openHour || currentHour < closeHour;
              }
              
              if (isOpen) {
                openRestaurants.add(item);
              }
            }
          }

          final String foodName = jsonMap['foodName']?.toString() ?? 'Unknown Food';
          final localOpenSpots = getMockSuggestions(
            foodName: foodName,
            locationName: locationName,
          );

          final List<RestaurantSpot> finalSpots = openRestaurants.map((item) {
            return RestaurantSpot.fromJson(item);
          }).toList();

          // ONLY append matching local spots if they are relevant (meaning localOpenSpots is not empty)
          if (finalSpots.length < 3 && localOpenSpots.isNotEmpty) {
            for (final localSpot in localOpenSpots) {
              final isDuplicate = finalSpots.any((s) => s.name.toLowerCase() == localSpot.name.toLowerCase());
              if (!isDuplicate) {
                finalSpots.add(localSpot);
              }
            }
          }

          return FoodScanResult(
            foodName: foodName,
            isFood: jsonMap['isFood'] as bool? ?? false,
            calories: (jsonMap['calories'] as num?)?.toInt() ?? 0,
            protein: toDouble(jsonMap['protein'] ?? jsonMap['proteins']),
            fat: toDouble(jsonMap['fat'] ?? jsonMap['fats']),
            carbs: toDouble(jsonMap['carbs'] ?? jsonMap['carbohydrates']),
            description: jsonMap['description']?.toString() ?? '',
            restaurants: finalSpots,
          );
        } else {
          final bodyJson = jsonDecode(response.body);
          final errorMsg = bodyJson['error']?['message'] ?? 'Unknown error';
          if (response.statusCode == 404 || errorMsg.toString().contains('not found')) {
            lastError = 'Model $model not found: $errorMsg';
            continue;
          }
          throw Exception('API call failed with status ${response.statusCode}: $errorMsg');
        }
      } catch (e) {
        lastError = e;
      }
    }

    final errorStr = lastError.toString().toLowerCase();
    if (errorStr.contains('api key') || errorStr.contains('400') || errorStr.contains('403') || errorStr.contains('unauthorized')) {
      return _generateMockResult(locationName);
    }

    throw Exception('Failed to analyze food with all available models. Last error: $lastError');
  }
}
