import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:mobile/dto/place.dart';
import 'package:mobile/dto/review.dart';
import 'package:mobile/services/reviews.dart';

class PlaceProfilePage extends StatefulWidget {

  final PlaceDto place;

  const PlaceProfilePage({
    Key? key,
    required this.place,
  }) : super(key: key);

  @override
  State<PlaceProfilePage> createState() => _PlaceProfilePageState();
}

class _PlaceProfilePageState extends State<PlaceProfilePage> {

  final ReviewService reviewService = Get.find<ReviewService>();

  late OverallReviewDto overallReviewDto;

  static const MAX_RATING = 5;

  List<ReviewDto> reviews = [];

  int page = 0;

  final textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const double EMPTY_RATING = -1;
  double _rating = EMPTY_RATING;

  static const OVERALL_RATING_STYLE = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold
  );

  static const NUM_RATINGS_STYLE = TextStyle(
    fontSize: 18,
  );

  @override
  void initState() {
    super.initState();
    getOverallReview();
    loadReviews(page);
  }

  getOverallReview() async {
    var resp = await reviewService.getOverallReview(widget.place.id);
    if (resp.isOk) {
      setState(() {
        overallReviewDto = resp.body!;
      });
    } else {
      print(resp.bodyString!);
    }
  }

  loadReviews(int page) async {
    var resp = await reviewService.getReviews(widget.place.id, page);
    if (resp.isOk) {
      setState(() {
        print("Loaded reviews...");
        reviews = resp.body!;
        print(reviews);
      });
    } else {
      print("Failed to load reviews");
      print(resp.bodyString!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.place.name
        ),
      ),
      body: Column(
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: widget.place.imageLink
          ),
          buildContent(),
          buildReviewButton(),
        ],
      ),
    );
  }

  Widget buildContent() {
    if (overallReviewDto.numRatings == 0) {
      return buildEmptyContentWidget();
    } else {
      return Expanded(
        child: Column(
          children: <Widget>[
            buildRatingWidget(),
            buildReviewsList()
          ],
        ),
      );
    }
  }

  Widget buildReviewsList() {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: reviews.length,
        itemBuilder: buildReviewListTile,
        separatorBuilder: (context, index) => const SizedBox(height: 4.0),
      ),
    );
  }

  Widget buildReviewListTile(BuildContext context, int index) {
    ReviewDto review = reviews[index];
    return ListTile(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => buildReviewDialog(context, review)
        );
      },
      tileColor: Colors.lightBlue,
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(
          review.user.imageLink
        ),
      ),
      title: Column(
        children: <Widget>[
          buildRatingBar(review.rating.toDouble()),
          Text(
            review.content,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  Widget buildReviewDialog(BuildContext context, ReviewDto review) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              review.user.imageLink
            ),
          ),
          buildRatingBar(review.rating.toDouble()),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                review.content,
                softWrap: true,
              ),
            )
          ),
        ],
      ),
    );
  }

  Widget buildReviewButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: ButtonBar(
        alignment: MainAxisAlignment.end,
        children: <Widget>[
          ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: buildReviewForm
                );
              },
              icon: const Icon(Icons.rate_review),
              label: const Text("Write a review")
          )
        ],
      ),
    );
  }

  Widget buildReviewForm(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: const Text("Review"),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: textController,
                    keyboardType: TextInputType.multiline,
                    minLines: 12,
                    maxLines: 12,
                    decoration: const InputDecoration(
                        icon: Icon(Icons.drive_file_rename_outline),
                        labelText: "Write your review"
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Please enter some text";
                      } else {
                        return null;
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            RatingBar.builder(
              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
              maxRating: MAX_RATING.toDouble(),
            ),
            IconButton(
                onPressed: () {
                  if (_rating == EMPTY_RATING || textController.text.isEmpty) {
                    var snackBar = const SnackBar(
                      content: Text("Please leave a rating and a review!")
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  } else {
                    submitReview();
                    textController.text = "";
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.check)
            ),
          ],
        ),
      ),
    );
  }
  
  void submitReview() async {
    await reviewService.createReview(textController.text, widget.place.id, _rating.toInt());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
  }

  Widget buildEmptyContentWidget() {
    return Center(
      child: Column(
        children: const <Widget>[
          Text(
            "This place has no reviews yet!",
            style: TextStyle(
                fontWeight: FontWeight.bold
            ),
          ),
          Text(
            "Make our app better by leaving the first review.",
            style: TextStyle(
                fontSize: 10
            ),
          )
        ],
      ),
    );
  }

  Widget buildRatingWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Text(
          overallReviewDto.overallRating.toStringAsFixed(1),
          style: OVERALL_RATING_STYLE
        ),
        buildRatingBar(overallReviewDto.overallRating),
        Text(
          "${overallReviewDto.numRatings} reviews",
          style: NUM_RATINGS_STYLE
        )
      ],
    );
  }

  Widget buildRatingBar(double rating) {
    return RatingBarIndicator(
      rating: rating,
      itemCount: MAX_RATING,
      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
      direction: Axis.horizontal,
    );
  }
}
