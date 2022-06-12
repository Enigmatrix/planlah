

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/state_manager.dart';
import 'package:mobile/pages/sign_up_components/fadeindexedstack.dart';
import 'package:mobile/services/misc.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:get/get.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _formIndex = 0;

  final misc = Get.find<MiscService>();

  late var towns = <String>["-"];

  final genders = <String>[
    "-",
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
  var _gender = "-";
  var _town = "-";

  // User profile
  List<String?> _attractions = [];
  List<String?> _food = [];
  // Either 0 or 1
  var _outOrIndoors = 0;

  // Check if all information is filled in
  var attractionsFilledIn = false;
  var foodFilledIn = false;
  var isFilledIn = false;

  @override
  Widget build(BuildContext context) {
    misc.getTowns().then((value) {
      setState(() {
        towns = value.body!;
      });
    });

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
                  buildWelcomePage(context),
                  buildAccountDetails(context),
                  buildUserProfile(context),
                  buildConfirmationPage(context),
                ],
              ),
            )
            ),
          );
  }

  void checkStatus() {
    if (_name == "" || _username == "" || _gender == "-" || _town == "-") {
      isFilledIn = false;
    } else {
      isFilledIn = true;
    }
  }

  Widget buildWelcomePage(BuildContext context) {
    return Column(
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
    );
  }

  Widget buildAccountDetails(BuildContext context) {
    return Column(
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
                    () {
                      _username = value;
                      checkStatus();
                    }
            );
          },
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Real name"),
          onChanged: (value) {
            setState(
                    () {
                  _name = value;
                  checkStatus();
                }
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
            setState(
                    () {
                  _gender = value!;
                  checkStatus();
                }
            );
          },
        ),
        DropdownSearch<String>(
          items: towns,
          // selectedItem: towns[0],
          dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                  labelText: "Town"
              )
          ),
          onChanged: (value) {
            setState(
                    () {
                  _town = value!;
                  checkStatus();
                }
            );
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
    );
  }

  Widget buildUserProfile(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.asset("assets/undraw_About_me_re_82bv.png"),
        const Text(
          "Tell us more about yourself",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          "This helps us give you better recommendations",
          style: TextStyle(
            fontSize: 14,
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (values) {
                        if (values == null || values.isEmpty || values.length < 5) {
                          attractionsFilledIn = false;
                          checkStatus();
                          return "Please choose at least 5 activities";
                        } else {
                          attractionsFilledIn = true;
                          checkStatus();
                          return "";
                        }
                      },
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (values) {
                        if (values == null || values.isEmpty || values.length < 5) {
                          foodFilledIn = false;
                          checkStatus();
                          return "Please choose at least 5 types of food";
                        } else {
                          foodFilledIn = true;
                          checkStatus();
                          return "";
                        }
                      },
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
                setState(() => _formIndex = 3);
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
    );
  }

  Widget buildConfirmationPage(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.asset(
            "assets/undraw_approve_qwp7.png"
        ),
        const Text(
          "Please confirm your details",
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold
          ),
        ),
        const Divider(
          color: Colors.black,
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              buildConfirmationUserDetails(context),
              const SizedBox(
                height: 16,
              ),
              buildAttractionsConfirmationBox(context),
              const SizedBox(
                height: 16,
              ),
              buildFoodConfirmationBox(context),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                setState(() => _formIndex = 2);
              },
              style: ElevatedButton.styleFrom(
                  fixedSize: const Size(20, 20),
                  shape: const CircleBorder()
              ),
              child: before,
            ),
            buildConfirmationButton(context)
          ],
        )
      ],
    );
  }

  Widget buildConfirmationUserDetails(BuildContext context) {
    return Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.blue,
                  width: 2
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
                onTap: () {
                  setState(() => _formIndex = 1);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Account details",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                      ),
                    ),
                    const Divider(
                      color: Colors.blue,
                    ),
                    CustomText(
                      tag: "Username",
                      value: _username,
                      failure: "",
                    ),
                    CustomText(
                      tag: "Name",
                      value: _name,
                      failure: "",
                    ),
                    CustomText(
                      tag: "Town",
                      value: _town,
                      failure: "-",
                    ),
                    CustomText(
                      tag: "Gender",
                      value: _gender,
                      failure: "-",
                    ),
                  ],
                )
            ),
          );
  }

  Widget buildAttractionsConfirmationBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.blue,
            width: 2
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
          onTap: () {
            setState(() => _formIndex = 2);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                "Attractions",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                ),
              ),
              const Divider(
                color: Colors.blue,
              ),
              buildAttractionsChipsDisplay(context),
            ],
          )
      ),
    );
  }

  Widget buildAttractionsChipsDisplay(BuildContext context) {
    if (_attractions.isEmpty) {
      return const Text(
        "Please choose at least 5 types of attractions.",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    } else {
      return Wrap(
        spacing: 4.0,
        children: _attractions.map<Widget>((a) => Chip(
            label: Text(a!),
        )).toList(),
      );
    }
  }

  Widget buildFoodConfirmationBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.blue,
            width: 2
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
          onTap: () {
            setState(() => _formIndex = 2);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                "Food",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                ),
              ),
              const Divider(
                color: Colors.blue,
              ),
              buildFoodChipsDisplay(context),
            ],
          )
      ),
    );
  }

  Widget buildFoodChipsDisplay(BuildContext context) {
    if (_food.isEmpty) {
      return const Text(
        "Please choose at least 5 kinds of food.",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    } else {
      return Wrap(
        spacing: 4.0,
        children: _food.map<Widget>((a) => Chip(
          label: Text(a!),
        )).toList(),
      );
    }
  }

  Widget buildConfirmationButton(BuildContext context) {
    if (isFilledIn) {
      return ElevatedButton(
          onPressed: () {
            // User registration done here
          },
          child: const Text(
            "This looks good, sign me up!",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900
            ),
          )
      );
    } else {
      return ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
        ),
        onPressed: () {},
        child: const Text(
          "Missing information",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        )
      );
    }
  }
}

class CustomText extends StatelessWidget {
  final String tag;
  final String value;
  final String failure;
  const CustomText({
    Key? key,
    required this.tag,
    required this.value,
    required this.failure
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (value == failure) {
      return Text(
        "$tag: Please enter your ${tag.toLowerCase()}",
        style: const TextStyle(
          color: Colors.red
        ),
      );
    } else {
      return Text(
          "$tag: $value"
      );
    }
  }
}
