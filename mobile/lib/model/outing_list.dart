import 'package:mobile/dto/outing.dart';
import 'package:mobile/dto/user.dart';

import 'outing_steps.dart';

class Outing {
  List<OutingStep> outingSteps;
  int currentOuting;
  String name;
  String description;

  Outing({
    required this.outingSteps,
    required this.currentOuting,
    required this.name,
    required this.description,
  });

  OutingStep getOutingStep(int index) {
    if (index < 0 || index >= outingSteps.length) {
      throw IndexError(index, outingSteps);
    }
    return outingSteps[index];
  }

  int size() {
    return outingSteps.length;
  }

  static OutingDto getOuting() {
    return OutingDto(
        1,
        "Placeholder name",
        "Placeholder description",
        1,
        "1600",
        "1800",
        [
          OutingStepDto(
              1,
              "Placeholder name",
              "Placeholder description",
              "Placeholder whereName",
              "Placeholder wherePoint",
              "2356",
              "2359",
              [
                OutingStepVoteDto(true, UserSummaryDto(
                  "sdot3",
                  "Samuel Siow Chin Kang"
                )),
              ],
              "2359.59.59"
          )
        ]
      );
  }
}