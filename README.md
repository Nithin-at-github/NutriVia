# 🥗 NutriVia – AI-Powered Personal Nutrition Assistant

NutriVia is a **Flutter-based AI-powered nutrition assistant** designed to help users make healthier food choices through personalized diet recommendations, smart meal tracking, and real-time nutritional analysis.  
The app acts as a **personal digital dietitian**, focusing on improved health, sustainability, and regional food availability.

---

## 📱 Features

### 🔐 Authentication & User Profile
- Secure user authentication using **Firebase Authentication**
- Multi-step onboarding & profile completion flow
- Profile completion check on every login
- User data stored in **Firebase Firestore**

### 🧍 Personal Health Metrics
- Real-time **BMI calculation** with health status
- Automatic **BMR** and **TDEE** calculation
- Personalized daily calorie & macronutrient targets
- Weekly nutrient recommendations

### 🍽️ Smart Diet & Meal Planning
- Personalized diet recommendations based on:
  - Dietary goals
  - Health conditions
  - Dietary restrictions
  - Preferred cuisine
  - Region/location
- Region-based food suggestions using **Edamam API**
- Daily meal plans generated after profile completion

### 📸 Food Logging & Recognition
- Food logging via:
  - Camera
  - Gallery upload
  - Voice input
- AI-based **food image classification** (top prediction only)
- Portion adjustment before logging meals
- Nutrition analysis using **Nutritionix API**

### 📊 Daily Tracking
- Meal-wise calorie tracking (Breakfast, Lunch, Dinner, Snacks)
- Daily macronutrient tracking (Calories, Protein, Fat, Carbs)
- Water intake logging
- Exercise logging
- Remaining calories visualization

### 🎨 UI & Experience
- Clean **teal-themed UI** for consistency
- User-friendly dashboards
- Editable profile (except email & password)

---

## 🛠️ Tech Stack

| Category | Technologies |
|--------|--------------|
| Frontend | Flutter |
| Backend | Firebase |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| APIs | Edamam API, Nutritionix API |
| AI/ML | Food Image Classification Model |
| State Management | GetIt |
| Networking | `http` package |

---

## 🗂️ Firestore Database Structure

```
users (collection)
└── userId (document)
├── personal details
├── health metrics
├── dietary preferences
├── dailyCalories
├── dailyProtein
├── dailyFat
├── dailyCarbs
├── profileCompleted
├── daily_logs (subcollection)
├── daily_nutrients (subcollection)
├── food_logs (subcollection)
├── exercise_logs (subcollection)
└── meal_plans (subcollection)
```


## 🚀 App Workflow

1. User signs up and completes onboarding
2. Profile data is validated and stored in Firestore
3. BMI, BMR, and TDEE are calculated automatically
4. Personalized diet plan is generated
5. User logs meals via image, voice, or text
6. Nutritional values are analyzed and tracked daily
7. Dashboard displays progress and remaining goals


## 📸 Screens Implemented

- Onboarding screens
- Multi-step signup
- Home dashboard
- Food scanning & logging screen
- Meal logging screen
- Account & profile screen


## 🧠 AI Components

### Food Image Classification
- Trained on a food image dataset
- Returns the **top predicted food item**


### Personalized Recommendation Engine
- Adjusts nutrient values based on:
  - Health conditions
  - Dietary restrictions (vegetarian, vegan, dairy-free, etc.)
  - Regional food availability
  

## 🎯 Project Objectives

- Promote healthier eating habits
- Provide personalized nutrition guidance
- Simplify meal tracking
- Encourage sustainable food choices
- Serve as a **real-world MCA final-year project**


## 📌 Future Enhancements

- Barcode scanning for packaged foods
- Carbon footprint calculation for meals
- Offline mode for food logging
- Community challenges and achievements
- Wearable device integration (optional)


## 🧑‍🎓 Academic Use

This project is developed as part of an **MCA Final Year Project**, focusing on:
- Mobile application development
- Applied machine learning
- Health-tech solutions
- Real-world problem solving



A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
