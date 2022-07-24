import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/outing_step.dart';
import 'package:mobile/dto/place.dart';
import 'package:mobile/pages/find_place.dart';
import 'package:mobile/services/place.dart';
import 'package:mobile/widgets/recommender_dialog.dart';
import 'package:mobile/widgets/wait_widget.dart';
import 'package:mobile/utils/errors.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../services/outing.dart';

class CreateOutingStepPage extends StatefulWidget {
  final OutingDto outing;
  final PlaceDto? recentPlace;

  const CreateOutingStepPage({
    Key? key,
    required this.outing,
    this.recentPlace}) : super(key: key);

  @override
  State<CreateOutingStepPage> createState() => _CreateOutingStepPageState();
}

class _CreateOutingStepPageState extends State<CreateOutingStepPage> {
  String stepDesc = "";
  DateTime? date;
  TimeRange? timeRange;
  PlaceDto? place;

  final outingService = Get.find<OutingService>();
  final placeService = Get.find<PlaceService>();

  final _descKey = GlobalKey<FormFieldState>();

  final defaultMargin = const EdgeInsets.only(top: 8.0, left: 24.0, right: 24.0);

  static const ERROR_STATUS = "Failed to get places";
  static const ERROR_FINDING = "We could not find any places for you based off your current location";

  List<PlaceDto> foodSuggestions = [];
  List<PlaceDto> attractionSuggestions = [];

  static const double title_gap = 2.0;

  @override
  void initState() {
    super.initState();
    if (widget.recentPlace == null) {
      initGeolocator();
    }
    date = DateTime.parse(widget.outing.start).toLocal();
  }

  initGeolocator() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permissions are denied!")));
      }
    }

    bool serviceStatus = await Geolocator.isLocationServiceEnabled();
    if (serviceStatus) {
      print("GPS works");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Encountered error checking location service!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Image.asset(
            "assets/undraw_Having_fun_re_vj4h.png",
            height: 200.0,
          ),
          buildFirstPage(context),
        ],
      ),
    ));
  }

  Widget buildFirstPage(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          "Create a step",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        buildOutingDescriptionTextBox(),
        buildPlaceSelectionButton(),
        buildDatetimeRangeButton(context),
        buildCreateOutingStepButton()
      ],
    );
  }

  Widget buildOutingDescriptionTextBox() {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0),
      child: TextFormField(
        key: _descKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Description",
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter a description for your outing";
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            stepDesc = value;
          });
        },
        keyboardType: TextInputType.multiline,
        maxLines: null,
      ),
    );
  }

  Widget buildPlaceSelectionButton() {
    if (place == null) {
      return buildSelectPlaceCard();
    } else {
      return buildChosenPlaceCard();
    }
  }

  Widget buildSelectPlaceCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
      clipBehavior: Clip.none,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.all(4.0)),
        clipBehavior: Clip.none,
        onPressed: () async {
          final chosenPlace = await showDialog<PlaceDto>(context: context, builder: (buildContext) {
            return searchChoosePlaceDialog();
          });
          setState(() {
            place = chosenPlace;
          });
        },
        child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: const BorderSide(color: Colors.grey, width: 0.8),
            ),
            child: ListTile(
              dense: true,
              horizontalTitleGap: title_gap,
              leading: const Icon(Icons.place),
              title: const FittedBox(
                fit: BoxFit.cover,
                child: Text("Choose where to go!"),
              ),
              trailing: buildSuggestionButton()
            )),
      ),
    );
  }

  Widget buildChosenPlaceCard() {
    return Card(
        margin: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom:8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: Colors.grey, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 8.0),
                  child: Center(child: Text(place!.name, style: const TextStyle(fontSize: 24.0), textAlign: TextAlign.center,)),
                ),
                Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(onPressed: () {
                      setState(() {
                        place = null;
                      });
                    }, icon: const Icon(Icons.close))
                )
              ],
            ),
            Container(
                padding: EdgeInsets.all(8.0),
                child: CachedNetworkImage(imageUrl: place!.imageLink)
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      // TODO redir to Google Maps
                    },
                    icon: const Icon(Icons.place)),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(right:8.0, bottom: 8.0),
                    child: Text(place!.formattedAddress,),
                  ),
                )
              ],
            ),
          ],
        ));
  }

  Widget buildSuggestionButton() {
    return FittedBox(
      fit: BoxFit.cover,
      child: ElevatedButton(
        onPressed: () async {
          var resp = await showDialog(context: context, builder: buildSuggestionDialog);
          // resp will be null if the user clicks out of the dialog so just
          // return immediately
          if (resp == null) {
            return;
          }
          // Call await on a showDialog to retrieve the value when the dialog is
          // returned with a value.
          PlaceDto? p = await showDialog(
            context: context,
            builder: (context) => buildFutureRecommender(resp)
          );
          // Set chosen place and rebuild widget
          setState(() {
            place = p;
          });
        },
        child: Text("Unsure?")
      ),
    );
  }

  Widget buildFutureRecommender(PlaceType placeType) {
    List<PlaceDto> suggestions = placeType == PlaceType.restaurant ? foodSuggestions : attractionSuggestions;
    if (suggestions.isEmpty) {
      return FutureBuilder(
          future: getSuggestions(placeType),
          builder: (BuildContext context, AsyncSnapshot<Response<List<PlaceDto>?>> snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.hasError) {
                return showErrorDialog(context, ERROR_STATUS);
              } else if (snapshot.data!.isOk) {
                if (snapshot.data!.body!.isEmpty) {
                  return showErrorDialog(context, ERROR_FINDING);
                } else {
                  if (placeType == PlaceType.restaurant) {
                    foodSuggestions = snapshot.data!.body!;
                  } else {
                    attractionSuggestions = snapshot.data!.body!;
                  }
                  return RecommenderDialog(places: snapshot.data!.body!);
                }
              } else {
                return showErrorDialog(context, ERROR_STATUS);
              }
            } else {
              return waitWidget();
            }
          }
      );
    } else {
      return RecommenderDialog(places: suggestions);
    }
  }

  Future<Response<List<PlaceDto>?>> getSuggestions(PlaceType placeType) async {
    Point p;
    // If place is null, obtain current location.
    // Else use the previous place's location.
    if (widget.recentPlace == null) {
      // This works on the actual android device
      Position position = await Geolocator.getCurrentPosition();
      p = Point(position.longitude, position.latitude);
    } else {
      p = widget.recentPlace!.position;
    }
    return await placeService.recommend(p, placeType);
  }

  Widget showErrorDialog(BuildContext context, String err) {
    return AlertDialog(
      content: Text(
        err,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  /// Dialog that gives the user the choice for food
  /// or attractions.
  Widget buildSuggestionDialog(BuildContext context) {
    return Dialog(
      elevation: 8.0,
      insetPadding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            "Food or fun?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                onPressed: () {
                  Navigator.pop(context, PlaceType.restaurant);
                },
                icon: const Icon(
                  Icons.fastfood,
                  color: Colors.lightGreenAccent,
                )
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context, PlaceType.attraction);
                },
                icon: const Icon(
                  Icons.headphones_battery,
                  color: Colors.pink,
                )
              ),
            ],
          )
        ],
      )
    );
  }

  Widget searchChoosePlaceDialog() {
    return const AlertDialog(
      title: Text("Find Places"),
      contentPadding: EdgeInsets.all(16.0),
      content: FindPlaceWidget()
    );
  }

  fmtDate(DateTime d) => DateFormat("MM/dd").format(d.toLocal());

  Widget buildDatetimeRangeButton(BuildContext context) {
    final firstDate = DateTime.parse(widget.outing.start).toLocal();
    final lastDate = DateTime.parse(widget.outing.end).toLocal();

    final datePicker = TextButton(
        onPressed: () async {
          final chosenDate = await showDatePicker(
            context: context,
            firstDate: firstDate,
            lastDate: lastDate,
            initialDate: firstDate,
          );
          setState(() {
            if (chosenDate != null) {
              date = chosenDate;
            }
          });
        },
        child: Text(fmtDate(date!)));

    final timePicker = TextButton(
        onPressed: () async {
          final chosenTimeRange = await showTimeRangePicker(context: context);
          // only because lastDate is a required parameter
          setState(() {
            timeRange = chosenTimeRange;
          });
        },
        child: Text(timeRange == null
            ? "When?"
            : "${timeRange!.startTime.format(context)} to ${timeRange!.endTime.format(context)}"));

    return Card(
      margin: defaultMargin,
      shape: RoundedRectangleBorder(
        //<-- SEE HERE
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Colors.grey, width: 0.8),
      ),
      child: ListTile(
        leading: const Icon(Icons.timer),
        title: Row(
          children: [datePicker, timePicker],
        ),
      ),
    );
  }

  Widget buildCreateOutingStepButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
          onPressed: () async {
            if (!_descKey.currentState!.validate()) {
              await ErrorManager.showErrorMessage(context, "Description invalid!");
              return;
            }
            if (date == null) {
              await ErrorManager.showErrorMessage(context, "Please select a date");
              return;
            }
            if (timeRange == null) {
              await ErrorManager.showErrorMessage(context, "Please select a time range");
              return;
            }
            if (place == null) {
              await ErrorManager.showErrorMessage(context, "Please select where to go");
              return;
            }
            await createOutingStep();
          },
          child: const Text(
            "Let's go",
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
    );
  }

  Future<void> createOutingStep() async {
    final startTime = timeRange!.startTime;
    final endTime = timeRange!.endTime;
    final start = DateTime(
        date!.year, date!.month, date!.day, startTime.hour, startTime.minute);
    var end = DateTime(
        date!.year, date!.month, date!.day, endTime.hour, endTime.minute);
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    var response = await outingService.createOutingStep(CreateOutingStepDto(
        widget.outing.id,
        stepDesc,
        place!.id,
        start.toUtc().toIso8601String(),
        end.toUtc().toIso8601String()));

    if (response.isOk) {
      Get.back();
    } else {
      if (!mounted) return;
      await ErrorManager.showError(context, response);
    }
  }
}
