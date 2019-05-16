import 'user.dart';
import 'challenge.dart';
import 'post.dart';

class ProfileData {
  String _description;
  String _quote;
  String _profilePic; // changed from UML Image -> String
  double _progress;
  User _forUser;
  List<Challenge> _challenges;
  List<Post> _posts; // new from UML
  Map _weightLog = {DateTime: 0};

  ProfileData(
      {User forUser,
      String description = "",
      String quote = "",
      String profilePic = "",
      double progress = 0,
      List<Challenge> challenges,
      Map weightLog}) {
    this._forUser = forUser;
    this._description = description;
    this._quote = quote;
    this._profilePic = profilePic;
    this._progress = progress;

    if (challenges != null) {
      this._challenges = challenges;
    } else {
      this._challenges = [];
    }

    if (weightLog != null) {
      this._weightLog = weightLog;
    } else {
      this._weightLog = {};
    }
  }

  void addPost(Post post) => _posts.add(post);
  void addFriend() {}
  void block() {}
  void calculateDietInfo() {}
  void displayGraph() {}
  String getDescription() => _description;
  double getProgress() => _progress;
  List<Challenge> getChallenges() => _challenges;
  User getUser() => _forUser;
  String getQuote() => _quote;
  String getProfilePic() => _profilePic;
  Map getWeightLog() => _weightLog;
  void removePost(Post post) => _posts.remove(post); // might need to have this actually return a bool to check
  void setAvatarImage(String image) => _profilePic = image;
  void setDescription(String description) => _description = description;
  void setQuote(String quote) => _quote = quote;
  void updateProgress(double progress) => _progress = progress; // unsure if this works
}
