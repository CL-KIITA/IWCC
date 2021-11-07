import "dart:html";

void main() async {
  String day = "2021/11/7";
  Duration dur = new Duration(days: 0, hours: 0);
  PeriodDispatcher pd = PeriodDispatcher();
  pd.periodFromTT(TimeTable.fromHtml(), day);
  DateTime dt = DateTime.now().add(dur);
  window.onLoad.listen((Event e) {
    pd.dispatch(dt);
  });
  Future<void> ft = nextDisp(pd, window.location, dur);
  ft.then((_) {
    pd.dispatch(dt);
  });

}
Future<void> nextDisp(PeriodDispatcher pd , Location loc, Duration d) async {
  DateTime dt = DateTime.now();
  Duration d;
  if(pd.isInPeriod()) {
    d = pd.durWithThisPeriodEnd(dt);
  } else {
    d = pd.durWithNextPeriod();
  }
  Future<void> ft = Future.delayed(d, () {
    loc.reload();
  });
  return ft;
}
class TimeTable{
  static List<List<String>> fromHtml(){
    Element tbody = document.querySelector(".schedule table.timetable tbody");
    List<Element> trs = tbody.children.where((Element e) => e.tagName == "TR" || e.tagName == "tr").toList();
    List<List<Element>> rows = trs.map((Element e) => e.children.where((Element e) => e.tagName == "TD" || e.tagName == "td").toList()).toList();
    List<List<String>> data = rows.indexedMap((int i, List<Element> row){
      List<String> time = row[1].text.split(" - ");
      return [trs[i].id, time[0], time[1]];
      }).toList();
    return data;
  }
}
class PeriodDispatcher {
  List<Period> _periods;
  PeriodDispatcher() {
    this._periods = List<Period>();
  }
  void periodFromTT(List<List<String>> data, String day){
    data.forEach((List<String> row){
      Period p = Period(row[0], Period.date(row[1], day), Period.date(row[2], day));
      this.addPeriod(p);
    });
  }
  void addPeriod(Period period) {
    this._periods.add(period);
  }
  void removePeriod(Period period) {
    this._periods.remove(period);
  }
  void dispatch([DateTime date]) {
    DateTime dt;
    if (date == null) {
      dt = DateTime.now();
    } else {
      dt = date;
    }
    this._periods.forEach((Period period) {
      String id = period.name;
      String query = ".schedule table.timetable tbody tr#$id";
      if (period.isInPeriod(dt)) {
        this._setClass(query);
      }else{
        this._removeClass(query);
      }
    });
  }
  void _setClass(String query){
    document.querySelector(query).classes.add("now");
  }
  void _removeClass(String query){
    document.querySelector(query).classes.remove("now");
  }
  Duration durWithNextPeriod([DateTime date]){
    DateTime dt;
    if (date == null) {
      dt = DateTime.now();
    } else {
      dt = date;
    }
    Period next = this._periods.firstWhere((Period p) => p.isBefore(dt), orElse: () => null);
    return next.start.difference(date);
  }
  Duration durWithThisPeriodEnd([DateTime date]){
    DateTime dt;
    if (date == null) {
      dt = DateTime.now();
    } else {
      dt = date;
    }
    Period next = this._periods.firstWhere((Period p) => p.isInPeriod(dt), orElse: () => null);
    return next.end.difference(date);
  }
  bool isInPeriod([DateTime date]){
    DateTime dt;
    if (date == null) {
      dt = DateTime.now();
    } else {
      dt = date;
    }
    return this._periods.any((Period p) => p.isInPeriod(dt));
  }
}
class Period {
  String _name;
  DateTime _start;
  DateTime _end;
  Period(String name, DateTime start, DateTime end) {
    this._name = name;
    this._start = start;
    this._end = end;
  }
  static DateTime date(String time, String day) {
    // returns DateTime object that represents the time and day
    // time is in the format "HH:MM"
    // day is in the format "YY/MM/DD"
    List<int> timeList = time.split(":").map((String s) => int.parse(s)).toList();
    List<int> dayList = day.split("/").map((String s) => int.parse(s)).toList();
    DateTime dt = DateTime(dayList[0], dayList[1], dayList[2], timeList[0], timeList[1]);
    return dt;
  }
  bool isInPeriod(DateTime dt) {
    return dt.isAfter(this._start) && dt.isBefore(this._end);
  }
  bool isBefore(DateTime dt) {
    return dt.isBefore(this._start);
  }
  String get name => this._name;
  DateTime get start => this._start;
  DateTime get end => this._end;
}
extension IndexedMap<T, E> on List<T> {
  List<E> indexedMap<E>(E Function(int index, T item) function) {
    final list = <E>[];
    asMap().forEach((index, element) {
      list.add(function(index, element));
    });
    return list;
  }
}