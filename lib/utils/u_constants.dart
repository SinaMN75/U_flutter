import "package:u/utilities.dart";

extension PageStateExtension on PageState {
  bool isInitial() => this == PageState.initial;

  bool isLoading() => this == PageState.loading;

  bool isLoaded() => this == PageState.loaded;

  bool isError() => this == PageState.error;

  bool isPaging() => this == PageState.paging;

  bool isEmpty() => this == PageState.empty;
}

extension RxPageStateExtension on Rx<PageState> {
  bool isLoading() => value == PageState.loading;

  bool isLoaded() => value == PageState.loaded;

  bool isInitial() => value == PageState.initial;

  bool isError() => value == PageState.error;

  bool isPaging() => value == PageState.paging;

  bool isEmpty() => value == PageState.empty;

  PageState initial() => this(PageState.initial);

  PageState loading() => this(PageState.loading);

  PageState loaded() => this(PageState.loaded);

  PageState error() => this(PageState.error);

  PageState paging() => this(PageState.paging);

  PageState emptying() => this(PageState.empty);
}

abstract class UConstants {
  static String token = "token";
  static String refreshToken = "refreshToken";
  static String userId = "userId";
  static String locale = "locale";
  static String isDarkMode = "isDarkMode";
}

enum PageState { initial, loading, loaded, error, empty, paging }

abstract class USample {
  static const String persianLorem =
      "لورم ایپسوم متن ساختگی با تولید سادگی نامفهوم از صنعت چاپ، و با استفاده از طراحان گرافیک است، چاپگرها و متون بلکه روزنامه و مجله در ستون و سطرآنچنان که لازم است، و برای شرایط فعلی تکنولوژی مورد نیاز، و کاربردهای متنوع با هدف بهبود ابزارهای کاربردی می باشد، کتابهای زیادی در شصت و سه درصد گذشته حال و آینده، شناخت فراوان جامعه و متخصصان را می طلبد، تا با نرم افزارها شناخت بیشتری را برای طراحان رایانه ای علی الخصوص طراحان خلاقی، و فرهنگ پیشرو در زبان فارسی ایجاد کرد، در این صورت می توان امید داشت که تمام و دشواری موجود در ارائه راهکارها، و شرایط سخت تایپ به پایان رسد و زمان مورد نیاز شامل حروفچینی دستاوردهای اصلی، و جوابگوی سوالات پیوسته اهل دنیای موجود طراحی اساسا مورد استفاده قرار گیرد.";
  static const String lorem =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.";
  static const String profileImageUrl = "https://www.himalmag.com/wp-content/uploads/2019/07/sample-profile-picture.png";
  static const String videoUrl = "https://abolfazlnezami.ir/file/video.mp4";
  static const String sampleName1 = "سینا محمدزاده نوری";

  static String loremPicsum({
    final double width = 1000,
    final double height = 1000,
  }) => "https://picsum.photos/id/${Random.secure().nextInt(300)}/${width.toInt()}/${height.toInt()}";
  static const String timeElapse = "۳۵ دقیقه پیش";
}
