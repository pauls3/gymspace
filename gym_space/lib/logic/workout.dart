class Workout {
  String name;
  String author;
  String muscleGroup;
  String description;
  String documentID;
  List exercises = List(); 
  // exercises are an array [exercise name, sets, reps, exercise name 2, sets 2, reps 2]
  // order counts
  
  Workout({
    this.name = "",
    this.author = "",
    this.muscleGroup = "",
    this.description = "",
    this.documentID = "",
    this.exercises,
  });

  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'name': name,
      'author': author,
      'muscleGroup': muscleGroup,
      'description': description,
      'exercises' : exercises ?? [],
    };
  }

  static Workout jsonToWorkout(Map<String, dynamic> data) {    
    return Workout(
      name: data['name'],
      author: data['author'],
      muscleGroup: data['muscleGroup'],
      description: data['description'],
      documentID: data['documentID'],
      exercises: data['exercises'],
    );
  }
} 