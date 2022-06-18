import 'outing_steps.dart';

class OutingList {
  List<OutingStep> outingSteps;
  int currentOuting;

  OutingList({
    required this.outingSteps,
    required this.currentOuting
  });

  OutingStep get(int index) {
    if (index < 0 || index >= outingSteps.length) {
      throw IndexError(index, outingSteps);
    }
    return outingSteps[index];
  }

  int size() {
    return outingSteps.length;
  }
}