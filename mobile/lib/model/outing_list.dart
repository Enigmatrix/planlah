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

  static Outing getOuting() {
    var lst = [
      OutingStep(
        name: "Gold Mile Complex",
        description: "Filler text 0",
        imageUrl: "https://spj.hkspublications.org/wp-content/uploads/sites/21/2019/02/darren-soh-golden-mile-complex-800x445.jpg",
        whenTimeStart: "0900",
        whenTimeEnd: "1100",
        estimatedTime: "2 mins",
      ),
      OutingStep(
        name: "Golden Mile Spa",
        description: "Filler text 1",
        imageUrl: "https://cdn.archilovers.com/projects/b_730_5bea89b1-da69-4cb3-adc0-7bc4ab1be101.jpg",
        whenTimeStart: "1100",
        whenTimeEnd: "1300",
        estimatedTime: "51 mins",
      ),
      OutingStep(
        name: "KFC",
        description: "Filler text 2",
        imageUrl: "https://shopsinsg.com/wp-content/uploads/2016/07/kfc-fast-food-restaurant-nex-singapore.jpg",
        whenTimeStart: "1300",
        whenTimeEnd: "1500",
        estimatedTime: "53 mins",
      ),
      OutingStep(
        name: "Botanic Gardens",
        description: "Filler text 3",
        imageUrl: "https://www.visitsingapore.com/see-do-singapore/nature-wildlife/parks-gardens/singapore-botanic-gardens/_jcr_content/par-carousel/carousel_detailpage/carousel/item_2.thumbnail.carousel-img.740.416.jpg",
        whenTimeStart: "1500",
        whenTimeEnd: "1600",
        estimatedTime: "53 mins",
      ),
      OutingStep(
        name: "Raffles Hotel",
        description: "Filler text 4",
        imageUrl: "https://www.raffles.com/assets/0/72/651/652/1702/13de7abd-f23b-4754-a517-ef0336aa331b.jpg",
        whenTimeStart: "1600",
        whenTimeEnd: "1800",
        estimatedTime: "53 mins",
      ),
    ];

    return Outing(
      outingSteps: lst,
      currentOuting: 3,
      name: "Jotham's Outing",
      description: "Hello, I love KFC.",
    );
  }
}