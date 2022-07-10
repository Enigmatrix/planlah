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
                  69420,
                  "sdot3",
                  "Samuel Siow Chin Kang",
                  "data:image/jpeg;base64,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"
                )),
              ],
              "2359.59.59"
          )
        ]
      );
  }
}