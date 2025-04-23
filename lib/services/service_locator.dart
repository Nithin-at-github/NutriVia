import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nutrivia/services/meal_plan_service.dart';
import 'package:nutrivia/services/nutrition_logging_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Verify environment variables
  assert(
    dotenv.get('NUTRITIONIX_APP_ID').isNotEmpty,
    'Nutritionix App ID not found in .env',
  );
  assert(
    dotenv.get('NUTRITIONIX_APP_KEY').isNotEmpty,
    'Nutritionix App Key not found in .env',
  );

  // Register services
  getIt.registerSingleton<NutritionLoggingService>(
    NutritionLoggingService(
      appId: dotenv.get('NUTRITIONIX_APP_ID'),
      appKey: dotenv.get('NUTRITIONIX_APP_KEY'),
    ),
  );

  getIt.registerSingleton<MealPlanService>(
    MealPlanService(
      nutritionixAppId: dotenv.get('NUTRITIONIX_APP_ID'),
      nutritionixAppKey: dotenv.get('NUTRITIONIX_APP_KEY'),
    ),
  );
}
