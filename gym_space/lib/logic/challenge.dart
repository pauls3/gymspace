class Challenge {
  String title = "";
  int points = 0;
  int goal = 0;         //e.g.: goal is to finish 5 miles

  Challenge({
    this.title = "",
    this.points = 0,
    this.goal = 0
  });

  Map<String, dynamic> toJSON(){
    return <String, dynamic> {
      'title' : title,
      'points' : points,
      'goal' : goal
    };
  }

  static Challenge jsonToChallenge(Map<String, dynamic> data){
    return Challenge(
      title: data['title'],
      points : data['points'],
      goal : data['goal']
    );
  }

}

