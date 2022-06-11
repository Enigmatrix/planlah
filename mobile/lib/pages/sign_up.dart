

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _formIndex = 0;

  final towns = [
    "Ang Mo Kio",
    "Bedok",
    "Bishan",
    "Boon Lay",
    "Bukit Batok",
    "Bukit Merah",
    "Bukit Panjang",
    "Changi",
    "Choa Chu Kang",
    "Clementi",
    "Geylang",
    "Hougang",
    "Jurong",
    "Kallang",
    "Lum Chu Kang",
    "Mandai",
    "Marina",
    "Marine Parade",
    "Newton",
    "Novena",
    "Orchard",
    "Outram",
    "Pasir Ris",
    "Paya Lebar",
    "Pioneer",
    "Punggol",
    "Queenstown",
    "River Valley",
    "Rochor",
    "Seletar",
    "Sembawang",
    "Sengkang",
    "Serangoon",
    "Sungei Kadut",
    "Tampines"
    "Tanglin",
    "Tengah",
    "Toa Payoh",
    "Tuas",
    "Woodlands",
    "Yishun"
  ];

  final genders = <String>[
    "Male",
    "Female",
    "Other",
  ];

  final attractionTags = <String>[
    "Airport",
    "Sports",
    "Art & History",
    "Movies",
    "Nature & Wildlife",
    "Water Activities",
    "Nightlife",
    "Spas",
    "Religion",
    "Food",
    "Shopping",
    "Studying",
    "Transport",
    "Games",
    "Tourism"
  ];

  final foodTags = <String>[
    "American",
    "Chinese",
    "European",
    "Pubs",
    "Italian",
    "Diner",
    "Healthy",
    "Japanese",
    "Malaysian",
    "Middle Eastern",
    "Vietnamese",
    "Barbecue",
    "French",
    "Indian",
    "Indonesian",
    "Korean",
    "Lebanese",
    "Philippine",
    "Singaporean",
    "Sri Lankan",
    "Thai",
    "Bakeries",
    "Cafe",
    "Contemporary",
    "Dessert",
    "Fast food",
    "Fusion",
    "Halal",
    "Kosher",
    "Pizza",
    "Quick Bites",
    "Seafood",
    "Soups",
    "Street Food",
    "Sushi"
  ];

  final before = const Icon(
    Icons.navigate_before_rounded
  );

  final next = const Icon(
      Icons.navigate_next_rounded
  );

  // Basic account details
  var _name = "";
  var _username = "";
  var _gender = "";
  var _town = "";

  // User profile
  List<String?> _attractions = [];
  List<String?> _food = [];
  // Either 0 or 1
  var _outOrIndoors = 0;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      // Prevent keyboard from messing up layout
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
            // height: size.height * 9 / 10,
            padding: const EdgeInsets.all(8.0),
            child:  FadeIndexedStack(
                index: _formIndex,
                children: <Widget>[
                  // Welcome page
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/undraw_Mobile_login_re_9ntv.png",
                            scale: 0.4,
                          ),
                          const Text(
                            "Welcome to PlanLah!",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                                color: Colors.black),
                          ),
                          const Text(
                            "Create an account, it's free",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _formIndex = 1);
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(20, 20),
                          shape: const CircleBorder()
                        ),
                        child: next,
                      ),
                    ],
                  ),

                  // Account details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                          "assets/undraw_Social_bio_re_0t9u.png",
                          scale: 0.3,
                      ),
                      const Text(
                        "Enter your account details",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                            color: Colors.black),
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: "Username"),
                        onChanged: (value) {
                          setState(
                                  () => _username = value
                          );
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: "Real name"),
                        onChanged: (value) {
                          setState(
                                  () => _name = value
                          );
                        },
                      ),
                      DropdownSearch<String>(
                        items: genders,
                        selectedItem: genders[0],
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                                labelText: "Gender"
                            )
                        ),
                        onChanged: (value) {
                          setState(() => _gender = value!);
                        },
                      ),
                      DropdownSearch<String>(
                        items: towns,
                        selectedItem: towns[0],
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Town"
                          )
                        ),
                        onChanged: (value) {
                          setState(() => _town = value!);
                        },
                      ),
                      Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => _formIndex = 0);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(20, 20),
                                        shape: const CircleBorder()
                                    ),
                                    child: before,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => _formIndex = 2);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(20, 20),
                                        shape: const CircleBorder()
                                    ),
                                    child: next,
                                  ),
                                ],
                              )
                            ],
                          )
                      ),
                    ],
                  ),

                  // User profile
                  Column(
                    children: <Widget>[
                      Image.asset("assets/undraw_About_me_re_82bv.png"),
                      const Text(
                          "Tell us more about yourself",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                          child: ListView(
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  MultiSelectBottomSheetField(
                                    buttonText: const Text(
                                        "What activities interest you?",
                                      style: TextStyle(
                                        fontSize: 18
                                      ),
                                    ),
                                    items: attractionTags.map((a) => MultiSelectItem<String?>(a, a)).toList(),
                                    onConfirm: (List<String?> values) {
                                      _attractions = values;
                                    },
                                  ),
                                  MultiSelectBottomSheetField(
                                    buttonText: const Text(
                                      "What kind of food do you like?",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    items: foodTags.map((a) => MultiSelectItem<String?>(a, a)).toList(),
                                    onConfirm: (List<String?> values) {
                                      _food = values;
                                    },
                                  )
                                ],
                              ),
                              Column(
                                children: <Widget>[
                                  SizedBox(height: 10),
                                  const Text(
                                    "Do you like going outdoors or staying indoors?",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      ChoiceChip(
                                        label: const Text(
                                            "Outdoors",
                                        ),
                                        selected: _outOrIndoors == 0,
                                        onSelected: (bool selected) {
                                            setState(() {
                                              if (selected) {
                                                _outOrIndoors = 0;
                                              }
                                            });
                                        },
                                        selectedColor: Colors.green,
                                      ),
                                      ChoiceChip(
                                        label: const Text(
                                          "Indoors",
                                        ),
                                        selected: _outOrIndoors == 1,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) {
                                              _outOrIndoors = 1;
                                            }
                                          });
                                        },
                                        selectedColor: Colors.blueGrey,
                                      )
                                    ],
                                  )
                                ],
                              )
                            ],
                          )
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _formIndex = 1);
                            },
                            style: ElevatedButton.styleFrom(
                                fixedSize: const Size(20, 20),
                                shape: const CircleBorder()
                            ),
                            child: before,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _formIndex = 2);
                            },
                            style: ElevatedButton.styleFrom(
                                fixedSize: const Size(20, 20),
                                shape: const CircleBorder()
                            ),
                            child: next,
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            )
            ),
          );
  }
}
