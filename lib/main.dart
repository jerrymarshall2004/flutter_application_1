import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'The Community Button'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late int _up;
  late int _down;
  late int _userUp;
  late int _userDown;
  DatabaseReference dataRef = FirebaseDatabase.instance.ref("data");
  late AnimationController _redColorController;
  late AnimationController _greenColorController;
  late Animation<double> _redColorAnimation;
  late Animation<double> _greenColorAnimation;

  late StreamSubscription _valueStream;
  late User? user;
  late String? email;
  late String? password;

  //Init State
  @override
  void initState() {
    _up = 1;
    _down = 1;
    _userUp = 1;
    _userDown = 1;

    email = null;
    password = null;

    user = null;

    FirebaseAuth.instance.authStateChanges().listen((User? thisUser) {
      if (thisUser == null) {
        print('User is currently signed out!');
        setState(() {
          user = thisUser;
        });
      } else {
        print('User is signed in!');
        setState(() {
          user = thisUser;
        });
      }
    });

    FirebaseAuth.instance.userChanges().listen((User? thisUser) {
      if (thisUser == null) {
        print('User is currently signed out!');
        setState(() {
          user = thisUser;
        });
      } else {
        print('User is signed in!');
        setState(() {
          user = thisUser;
        });
      }
    });

    _valueStream = dataRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        changeCounter(data);
      },
    );

    //Animation Controllers
    _redColorController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 200,
      ),
    );
    _greenColorController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 200,
      ),
    );

    //Animations
    _redColorAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      _redColorController,
    );
    _greenColorAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      _greenColorController,
    );

    //Animation Listeners
    _redColorController.addListener(
      () {
        setState(() {});
      },
    );

    _greenColorController.addListener(
      () {
        setState(
          () {},
        );
      },
    );

    //Start
    _redColorController.forward();
    _greenColorController.forward();

    super.initState();
  }

  //Changed DB
  void changeCounter(dynamic data) {
    if (data["up"] > _up) {
      _greenColorController.reset();
      _greenColorController.forward();
    }
    if (data["down"] > _down) {
      _redColorController.reset();
      _redColorController.forward();
    }
    setState(() {
      _up = data["up"];
      _down = data["down"];
      _userUp = data[FirebaseAuth.instance.currentUser!.uid]["up"];
      _userDown = data[FirebaseAuth.instance.currentUser!.uid]["down"];
      print(_userUp);
    });
  }

  void changeUserCounter(dynamic data) {
    setState(() {});
  }

  //Update DB
  void _increaseCounter() {
    _up++;
    _userUp++;
    dataRef.child("up").set(_up);
    dataRef
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("up")
        .set(_userUp);
    _greenColorController.reset();
    _greenColorController.forward();
  }

  //Update DB
  void _decreaseCounter() {
    _down++;
    _userDown++;
    dataRef
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("down")
        .set(_userDown);
    dataRef.child("down").set(_down);
    _redColorController.reset();
    _redColorController.forward();
  }

  //Close State
  @override
  void dispose() {
    _valueStream.cancel();
    super.dispose();
  }

  void signUp() async {
    if (email != null && password != null) {
      try {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email!,
          password: password!,
        );
        dataRef.child(credential.user!.uid).child("up").set(0);
        dataRef.child(credential.user!.uid).child("down").set(0);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void signIn() async {
    if (email != null && password != null) {
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email!, password: password!);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print('No user found for that email.');
        } else if (e.code == 'wrong-password') {
          print('Wrong password provided for that user.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (user != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          centerTitle: true,
          title: Text(widget.title),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => FirebaseAuth.instance.signOut(),
          child: Icon(Icons.logout),
          tooltip: "Log Out",
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(.5),
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(children: [
                      Text(
                        "Your Contributions:",
                        style: GoogleFonts.montserrat(
                          fontSize: (18),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text("Up: " + _userUp.toString(),
                          style: GoogleFonts.montserrat(
                            fontSize: (12),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          )),
                      Text("Down: " + _userDown.toString(),
                          style: GoogleFonts.montserrat(
                            fontSize: (12),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          )),
                    ]),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 5),
                        blurRadius: 5),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 50,
                        width: width - 40,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _decreaseCounter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.red[300],
                                    Colors.red[500],
                                    _redColorController.value,
                                  ),
                                ),
                                height: 50,
                                width: (width * (_down / (_up + _down)) - 20),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        ((_down / (_up + _down)) * 100)
                                                .floor()
                                                .toString() +
                                            "%",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: (18 +
                                              (_redColorController.value * 3)),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _down.toString(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _increaseCounter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.green[300],
                                    Colors.green[500],
                                    _greenColorController.value,
                                  ),
                                ),
                                height: 50,
                                width: (width * (_up / (_up + _down)) - 20),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        ((_up / (_up + _down)) * 100)
                                                .floor()
                                                .toString() +
                                            "%",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: (18 +
                                              (_greenColorController.value *
                                                  3)),
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _up.toString(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * .5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        onPressed: _decreaseCounter,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.remove),
                      ),
                      FloatingActionButton(
                        onPressed: _increaseCounter,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
          children: [
            TextFormField(
              onChanged: (String value) {
                setState(() {
                  email = value;
                });
              },
              decoration: InputDecoration(label: Text("Email")),
            ),
            TextFormField(
              onChanged: (String value) {
                setState(() {
                  password = value;
                });
              },
              decoration: InputDecoration(label: Text("Password")),
            ),
            ElevatedButton(onPressed: signIn, child: Text("Sign In")),
            ElevatedButton(onPressed: signUp, child: Text("Sign Up"))
          ],
        )),
      );
    }
  }
}
