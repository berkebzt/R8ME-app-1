import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import "package:cs310/classes/customUser.dart";
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as im;
import 'package:uuid/uuid.dart';
import "package:cs310/initial_routes/homepage.dart";

class Upload extends StatefulWidget {


  final customUser currentUser;
  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {


  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  File myfile;
  bool uploadingProgress = false;
  String postID;




  void showCustomDialog(BuildContext context) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.purple[200]
                ),
                child: Text("Capture Photo",style: TextStyle(fontSize: 20,color: Colors.black),),
                  onPressed: TakePhoto

              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.purple[200]
                ),
                child: Text("Select From Gallery",style: TextStyle(fontSize: 20,color: Colors.black)),
                onPressed: ChooseGallery,

              ),
              Divider(height: 8,thickness: 3, color: Colors.black,),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.white
                ),
                child: Text("Cancel",style: TextStyle(fontSize: 20, color: Colors.black),),
                onPressed: () => Navigator.pop(context),

              ),


            ],
          ),
        ),
      );
    });



   TakePhoto() async {
    Navigator.pop(context);
    File pickedFile = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      myfile = pickedFile;
    });
   }

  ChooseGallery() async {
    Navigator.pop(context);
    File chosenFile = await ImagePicker.pickImage(
        source: ImageSource.gallery
    );
    setState(() {
      myfile = chosenFile;
    });
  }



  Container UploadingScreen() {
    return Container(
      color: Colors.greenAccent.withOpacity(0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/upload.svg', height: 260.0),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              color: Colors.red[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                "Upload Image",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                ),
              ),
              onPressed: () {
                setState(() {
                  postID = Uuid().v4();
                });
                showCustomDialog(context);
            },
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      myfile = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    im.Image Imagefile = im.decodeImage(myfile.readAsBytesSync());
    final compressedImageFile = File('$tempPath/img_$postID.jpg')..writeAsBytesSync(im.encodeJpg(Imagefile, quality: 85));

    setState(() {
      myfile = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {

    UploadTask uploadTask = storageRef.child("image_$postID.jpg").putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask.whenComplete(() {});
    String downloadUrl = await storageSnap.ref.getDownloadURL();

    return downloadUrl;
  }

  createPostInFirestore({String mediaUrl, String location, String description}) {
    postsRef
        .doc(widget.currentUser.userID)
        .collection("user_posts")
        .doc(postID)
        .set({
      "postID": postID,
      "ownerID": widget.currentUser.userID,
      "username": widget.currentUser.username,
      "mediaURL": mediaUrl,
      "description": description,
      "location": location,
      "time": DateTime.now(),

      "liked_users": {},
      "disliked_users": {},

      "likeCount" : 0,
      "dislikeCount" : 0,

      "rate" : 0.0
    });


    captionController.clear();
    locationController.clear();

    setState(() {
      myfile = null;
      uploadingProgress = false;
    });
  }

  SubmitPost() async {
    setState(() {
      uploadingProgress = true;
    });
    await compressImage();

    String mediaUrl = await uploadImage(myfile);

    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
  }

  Scaffold CaptionScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: clearImage),
        title: Text(
          "Add Caption",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: uploadingProgress ? null : () => SubmitPost(),
            child: Container(
              child: Icon(
                Icons.send_rounded,
                size: 35,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          uploadingProgress ? LinearProgressIndicator() : Text(""),
          Container(
            height: 400.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: FileImage(myfile),
                      )),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
              CachedNetworkImageProvider(widget.currentUser.photo_URL),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Write a caption...", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12,vertical:0),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                          Icons.location_pin,
                          size :40,
                          color :Colors.grey),
                      //suffixIcon:
                      hintText: "Add Location?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Ink(
                    decoration: const ShapeDecoration(
                      color: Colors.green,
                      shape: CircleBorder(
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location),
                      iconSize: 30,
                      color: Colors.white,
                      onPressed: () async {
                        getCurrentLocation();
                      },
                    ),
                  ),
                ),

              ],
            ),
          ),


          
        ],
      ),
    );
  }

  getCurrentLocation() async {

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }



    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';

    print(completeAddress);
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return  myfile == null ? UploadingScreen() : CaptionScreen() ;
  }
}