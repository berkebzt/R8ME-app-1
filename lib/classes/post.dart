import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cs310/classes/customUser.dart';
import 'package:cs310/initial_routes/homepage.dart';
import 'package:cs310/pages/commentsScreen.dart';
import 'package:cs310/pages/editPost_screen.dart';
import 'package:cs310/pages/profile.dart';
import 'package:cs310/pages/showLikers_Dislikers.dart';
import 'package:cs310/pages/targetProfile.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:photo_view/photo_view.dart';
import "package:timeago/timeago.dart" as timeago;

CachedNetworkImage cachedNetworkImage_custom(mediaURL) {
  return CachedNetworkImage(
    imageUrl: mediaURL,
    fit: BoxFit.cover,
    placeholder: (context, url) => Padding(
      child: CircularProgressIndicator(),
      padding: EdgeInsets.all(20.0),
    ),
    errorWidget: (context, url, error) => Icon(Icons.error),
  );
}

class Post extends StatefulWidget {

  final String postID;
  final String ownerID;
  final String username;
  final String mediaURL;
  final String description;
  final String location;
  final Timestamp time;

  final dynamic liked_users;
  final dynamic disliked_users;

  final int likeCount;
  final int dislikeCount;

  final double rate;


  //CONSTRUCTOR
  Post({
    this.postID,
    this.ownerID,
    this.username,
    this.mediaURL,
    this.description,
    this.location,
    this.time,

    this.liked_users,
    this.disliked_users,

    this.likeCount,
    this.dislikeCount,

    this.rate,
  });

  factory Post.createPostFromDoc(DocumentSnapshot doc){
    return Post(
      postID: doc.data()["postID"],
      ownerID: doc.data()["ownerID"],
      username: doc.data()["username"],
      mediaURL: doc.data()["mediaURL"],
      description: doc.data()["description"],
      location: doc.data()["location"],
      time: doc.data()["time"],

      liked_users: doc.data()["liked_users"],
      disliked_users: doc.data()["disliked_users"],

      likeCount: doc.data()["likeCount"],
      dislikeCount: doc.data()["dislikeCount"],

      rate : doc.data()["rate"].toDouble()
    );
  }


  int getLikeCount(liked_users){
    if(liked_users == null)
      return 0;

    int counter=0;
    liked_users.forEach((key, value) {
      if(value==true)
        counter++;
    });
    return counter;
  }
  int getDislikeCount(disliked_users){
    if(disliked_users == null)
      return 0;

    int counter=0;
    disliked_users.forEach((key, value) {
      if(value==true)
        counter++;
    });
    return counter;
  }
  double calculateRate(likeCount, dislikeCount){
    if(likeCount == 0){
      return 0.0;
    }
    else if(likeCount != 0 && dislikeCount == 0){
      return 1.0;
    }
    else if(likeCount != 0 && dislikeCount != 0){
      return likeCount/(dislikeCount+likeCount);
    }
  }



  @override
  _PostState createState() => _PostState(
      postID: this.postID,
      ownerID: this.ownerID,
      username: this.username,
      mediaURL: this.mediaURL,
      description: this.description,
      location: this.location,
      time: this.time,

      liked_users: this.liked_users,
      disliked_users: this.disliked_users,

      likeCount: getLikeCount(this.liked_users),
      dislikeCount: getDislikeCount(this.disliked_users),

      rate : calculateRate(this.likeCount, this.dislikeCount)

  );
}



class _PostState extends State<Post> {
  final customUser currentUserOnPage = currentUser;
  bool fillHeart = false;
  bool fillThumb = false;

  final String postID;
  final String ownerID;
  final String username;
  final String mediaURL;
  final String description;
  final String location;
  final Timestamp time;

  Map liked_users;
  Map disliked_users;

  int likeCount;
  int dislikeCount;

  double rate;

  //CONSTRUCTOR
  _PostState({
    this.postID,
    this.ownerID,
    this.username,
    this.mediaURL,
    this.description,
    this.location,
    this.time,

    this.liked_users,
    this.disliked_users,

    this.likeCount,
    this.dislikeCount,

    this.rate,
  });

  double calculateRate(int likeCount, int dislikeCount){
    if(likeCount == 0){
      return 0.0;
    }
    else if(likeCount != 0 && dislikeCount == 0){
      return 1.0;
    }
    else if(likeCount != 0 && dislikeCount != 0){
      return likeCount/(dislikeCount+likeCount);
    }
  }

  void GoToComments(BuildContext context, {String postID, String ownerID, String mediaURL}){
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CommentsScreen(
        postID: postID,
        ownerID: ownerID,
        mediaURL: mediaURL,
      );
    }));
  }

  void showProfile(context)async{
    var doc = await usersRef.doc(ownerID).get();
    customUser targetUser = customUser.fromDocument(doc);

    ///TODO: remove the comment lines for if condition, so that owner of post shall not view himself/herself
   //if(currentUser.userID != ownerID){
     Navigator.push(context, MaterialPageRoute(
         builder: (context){

           return targetProfile(currentUser: targetUser);
         }
     ));
   //}
  }

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerID).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }
        customUser ownerUser = customUser.fromDocument(snapshot.data);
        return Row(
          children: [
            Expanded(
              flex: 10,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(ownerUser.photo_URL),
                  backgroundColor: Colors.grey,
                ),
                title: GestureDetector(
                  onTap: () => showProfile(context),
                  child: Text(
                    ownerUser.username,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                subtitle: Text(location),
                trailing: currentUserOnPage.userID == ownerID ? IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () => ShowOptions(context)
                )
                    : null,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(timeago.format(time.toDate(), locale: 'en_short')),
            ),
          ],
        );
      },
    );
  }
  buildPostImage() {
    return GestureDetector(
      onDoubleTap: () => print("Liked post!"),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
              height: MediaQuery.of(context).size.height-300,
              width:  MediaQuery.of(context).size.width,
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(
                    mediaURL,
                    
                ),
                backgroundDecoration: BoxDecoration(color:Colors.white),
              ),
          )
        ],
      ),
    );
  }

  Future<bool> checkComment()async{
    QuerySnapshot snapshot = await commentsRef
        .doc(postID)
        .collection("comments")
        .where("userID", isEqualTo: authUser.userID).get();

    if(snapshot.docs.length != 0){
      return true;
    }
    return false;
  }

  Future<int> countComment()async {
    QuerySnapshot snapshot = await commentsRef
        .doc(postID)
        .collection("comments")
        .get();

    return snapshot.size;
  }

  buildPostFooter() {
    return FutureBuilder(
      future: Future.wait([checkComment(), countComment()]),
      builder: (context,snapshot){
        if(!snapshot.hasData){   //0=check  1=count
          return LinearProgressIndicator();
        }
        else{
          return Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.favorite_rounded),
                        iconSize: 30,
                        color: fillHeart ? Colors.red : Colors.grey[700],
                        onPressed: (){
                          print("tapped on like!");
                          Like();
                        },
                      ),
                      GestureDetector(
                        child: Text(
                          "$likeCount",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => showLikers_Dislikers(ownerID: ownerID, postID: postID,whichList: "Likers",)));

                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_down_rounded),
                        iconSize: 30,
                        color: fillThumb==true ? Colors.blueAccent : Colors.grey[700] ,
                        onPressed: (){
                          print("tapped on dislike!");
                          Dislike();
                        },
                      ),
                      GestureDetector(
                        child: Text(
                          "$dislikeCount",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => showLikers_Dislikers(ownerID: ownerID, postID: postID,whichList: "Dislikers",)));

                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.trending_up_rounded),
                        iconSize: 34,
                        color: Colors.grey[700],
                        onPressed: (){
                          print("tapped on dislike!");
                        },
                      ),
                      Container(
                        child: Text(
                          num.parse((rate*100).toStringAsFixed(2)).toString(),
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat_rounded),
                        iconSize: 30,
                        color: snapshot.data[0] == true ? Colors.blue[700] : Colors.grey[700],
                        onPressed: (){
                          GoToComments(
                              context,
                              postID: postID,
                              ownerID: ownerID,
                              mediaURL: mediaURL
                          );
                          print("tapped on comment!");
                        },
                      ),
                      Container(
                        child: Text(
                          "${snapshot.data[1]}",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 20.0),
                    child: Text(
                      "$username  ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: Text(description))
                ],
              ),
              SizedBox(height: 5,),
              Divider(thickness: 3,),
            ],
          );
        }
      }
    );
  }


  void Like(){
    bool _alreadyLiked = liked_users[currentUserOnPage.userID] == true ? true : false;

    //if liked person taps button, bring the like back
    if(_alreadyLiked == true){


      setState(() {
        likeCount--;
        fillHeart = false;
        liked_users[currentUserOnPage.userID] = false;
        rate = calculateRate(likeCount, dislikeCount);
      });

      //now update in the database
      postsRef
          .doc(ownerID)
          .collection("user_posts")
          .doc(postID)
      .update({
        "liked_users.${currentUserOnPage.userID}" : false,
        "likeCount" : likeCount,
        "dislikeCount" : dislikeCount,
        "rate" : calculateRate(likeCount, dislikeCount)

      });
    }

    //if it is not liked, then like on tap
    else if(_alreadyLiked == false){

      setState(() {
        likeCount++;
        fillHeart = true;
        liked_users[currentUserOnPage.userID] = true;
        rate = calculateRate(likeCount, dislikeCount);

      //now update in the database
      postsRef
          .doc(ownerID)
          .collection("user_posts")
          .doc(postID)
          .update({
            "liked_users.${currentUserOnPage.userID}" : true,
            "likeCount" : likeCount,
            "dislikeCount" : dislikeCount,
            "rate" : calculateRate(likeCount, dislikeCount)

          });

      });
      addLikeToActivityFeed();
    }
  }
  void Dislike(){
    bool _alreadyDisliked = disliked_users[currentUserOnPage.userID] == true ? true : false;

    //if liked person taps button, bring the like back
    if(_alreadyDisliked == true){


      setState(() {
        dislikeCount--;
        fillThumb = false;
        disliked_users[currentUserOnPage.userID] = false;
        rate = calculateRate(likeCount, dislikeCount);
      });

      //now update in the database
      postsRef
          .doc(ownerID)
          .collection("user_posts")
          .doc(postID)
          .update({
        "disliked_users.${currentUserOnPage.userID}" : false,
        "likeCount" : likeCount,
        "dislikeCount" : dislikeCount,
        "rate" : calculateRate(likeCount, dislikeCount)

      });
    }

    //if it is not liked, then like on tap
    else if(_alreadyDisliked == false){

      setState(() {
        dislikeCount++;
        fillThumb = true;
        disliked_users[currentUserOnPage.userID] = true;
        rate = calculateRate(likeCount, dislikeCount);

        //now update in the database
        postsRef
            .doc(ownerID)
            .collection("user_posts")
            .doc(postID)
            .update({
          "disliked_users.${currentUserOnPage.userID}" : true,
          "likeCount" : likeCount,
          "dislikeCount" : dislikeCount,
          "rate" : calculateRate(likeCount, dislikeCount)

        });

      });
      addDislikeToActivityFeed();
    }
  }

  addLikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = true;//currentUserOnPage.userID != ownerID;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerID)
          .collection("feedItems")
          .add({
        "type": "like",
        "username": currentUser.username,
        "userID": currentUser.userID,
        "photo_URL": currentUser.photo_URL,
        "postID": postID,
        "mediaURL": mediaURL,
        "time": DateTime.now(),
      });
    }
  }
  addDislikeToActivityFeed() {
    // add a notification to the postOwner's activity feed only if comment made by OTHER user (to avoid getting notification for our own like)
    bool isNotPostOwner = true;//currentUserOnPage.userID != ownerID;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerID)
          .collection("feedItems")
          .add({
        "type": "dislike",
        "username": currentUser.username,
        "userID": currentUser.userID,
        "photo_URL": currentUser.photo_URL,
        "postID": postID,
        "mediaURL": mediaURL,
        "time": DateTime.now(),
      });
    }
  }



  ShowOptions(BuildContext mainContext) {

    return showDialog(
        context: mainContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Do you want to remove post?"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);

                  Map<String,String> data = {
                    "postID": postID,
                    "mediaURL": mediaURL,
                    "description": description,
                    "location": location,
                  };
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditPost(currentUser: currentUser, data:data )));

                },
                child: Text(
                  'Edit',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deleteEverythingAboutPost();
                  Navigator.pop(context);
                },
                child: Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              )
            ],
          );
        });
  }

  deleteEverythingAboutPost() async {
    // delete post from posts collection
    postsRef
        .doc(ownerID)
        .collection('user_posts')
        .doc(postID)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // delete uploaded image from storage
    storageRef.child("image_$postID.jpg").delete();

    // then delete all activity feed notifications
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerID)
        .collection("feedItems")
        .where('postID', isEqualTo: postID)
        .get();

    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    // then delete all comments
    QuerySnapshot commentsSnapshot = await commentsRef
        .doc(postID)
        .collection('comments')
        .get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    fillHeart = liked_users[currentUserOnPage.userID] == true;
    fillThumb = disliked_users[currentUserOnPage.userID] == true;
    return Column(
      children: <Widget>[
        buildPostHeader(),
        Divider(height: 5,),
        buildPostImage(),
        Divider(height: 5,),
        buildPostFooter(),

      ],
    );
  }
}
