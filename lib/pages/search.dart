import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:testt/models/user.dart';
import 'package:testt/widgets/progress.dart';

final userRef = FirebaseFirestore.instance.collection("users");

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();

  Future<QuerySnapshot>? searchResultsFuture;

  clearSearch(){
    searchController.clear();
  }

buildSearchResults(){
  return FutureBuilder(future: 
  searchResultsFuture, 
  builder: (context, snapshot){
    if (!snapshot.hasData){
      return circularProgress();
    }
    List<UserResult> searchResults= [];
    snapshot.data?.docs.forEach((doc){
      User user = User.fromDocument(doc);
      UserResult searchResult = UserResult(user);

      searchResults.add(searchResult);
    });
    return ListView(
      children: searchResults,
    );
  });
}


  handleSearch(String query){
    Future<QuerySnapshot> users = userRef
    .where("username", isGreaterThanOrEqualTo: query)
    .get();
    setState(() {
      searchResultsFuture = users;
    });
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Seacrh for a user ...",
          filled: true,
          prefixIcon: Icon(Icons.account_box, size: 28.0),
          suffixIcon: IconButton(
            onPressed: () => clearSearch(),
            icon: Icon(Icons.clear),
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  buildNoContent() {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          SvgPicture.asset("assets/images/search.svg",
           height: orientation == Orientation.portrait? 300.0: 150.0),
          Text(
            "Find Users",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color.fromARGB(223, 255, 255, 255),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              fontSize: 60.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withAlpha((0.8 * 255).round()),
      appBar: buildSearchField(),
      body: searchResultsFuture == null? buildNoContent(): 
      buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: ()=> print("Tapped"),

            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoURL),
              ),
              title: Text(user.displayName, style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user.username, style: TextStyle(color: Colors.white),),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
