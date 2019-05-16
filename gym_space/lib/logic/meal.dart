enum Category { Breakfast, Lunch, Dinner, Snack, Beverage }

class Meal {
  String _name;
  Category _category;
  double _protein;
  double _carbs;
  double _fats;

  Meal(
      {String name,
      Category category,
      double protein = 0,
      double carbs = 0,
      double fats = 0}) {
    _name = name;
    _category = category;
    _protein = protein;
    _carbs = carbs;
    _fats = fats;
  }

  String getName() => _name;
  Category getCategory() => _category;
  double getCalories() => 4 * _carbs + 4 * _protein + 4 * _fats;
  double getProtein() => _protein;
  double getCarbs() => _carbs;
  double getFats() => _fats;
  void setName(String name) => this._name = name;
  void setCategory(Category category) => this._category = category;
  void setProtein(double protein) => this._protein = protein;
  void setCarbs(double carbs) => this._carbs = carbs;
  void setFats(double fats) => this._fats = fats;
}
