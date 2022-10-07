import 'dart:io';

void main(List<String> arg) {
  late Uri path;
  late Uri pathTmp;
  bool hasPath = false;
  for (String el in arg) {
    try{
      pathTmp = Uri.file(el, windows: Platform.isWindows);
      path = pathTmp;
      hasPath = true;
      break;
    }catch(e){}
  }
  if(!hasPath){
    path = Uri.file("./colorList.txt");
  }
  File f = File.fromUri(path);
  if(!f.existsSync()){
    print("Err: The file in specified by path ${f.path} is not exists.");
    String p = f.absolute.parent.path;
    print (p);
    return;
  }
  Iterable<String> xpathE = f.path.split(".");
  String xpath = xpathE.take(xpathE.length - 1).join(".");
  File ofile = File.fromUri(Uri.file("$xpath.html"));
  File sfile = File.fromUri(Uri.file("$xpath.css"));
  if(!ofile.existsSync()){
    if(!ofile.parent.existsSync()){
      ofile.parent.createSync(recursive: true);
    }
    ofile.createSync(recursive: true);
  }
  if(!sfile.existsSync()){
    if(!sfile.parent.existsSync()){
      sfile.parent.createSync(recursive: true);
    }
    sfile.createSync(recursive: true);
  }
  sfile.writeAsStringSync(CSSStyleFile().output());
  String src = f.readAsStringSync().replaceAll("\r\n", "\n").replaceAll("\r", "\n");
  List<String> data = src.split("\n");
  //print(data);
  Page p = Page(data, sfile.path);
  ofile.writeAsStringSync(p.output());

}
abstract class HtmlTag{
  String tagName;
  bool nonTerminal;
  Map<String, List<String>> attributes;
  List<HtmlTag> children;
  HtmlTag(this.tagName, {this.nonTerminal = false, this.attributes = const {}, this.children = const []});
  String output(){
    String attrStr = this.attributes.isEmpty ? "" : " " + this.attributes.entries
      .map<String>((MapEntry<String, List<String>> e) => e.value.isEmpty ? e.key : e.key + "=\""+ e.value.join(" ") +"\"").join(" ");
    String elStr = this.children.map<String>((HtmlTag e) => e.output()).join("\n");
    if(tagName == ""){
      return elStr;
    }
    if(!nonTerminal){
      return "<${this.tagName}$attrStr>\n$elStr\n</${this.tagName}>";
    }else{
      return "<${this.tagName}$attrStr />";
    }
  }
}
abstract class CoreHTag extends HtmlTag{
  CoreHTag(String tagName, {bool nonTerminal = false, Map<String, List<String>> attributes = const {}, List<HtmlTag> children = const []}):
    super(tagName, attributes: attributes, children: children, nonTerminal: nonTerminal);
}
abstract class CustomHTag extends HtmlTag{
  CustomHTag():
    super("");
  HtmlTag build();
  @override
  String output(){
    HtmlTag buildes = this.build();
    while(buildes is CustomHTag){
      buildes = buildes.build();
    }
    if(buildes is! CoreHTag){
      throw Error();
    }
    return buildes.output();
  }
}
class DivTag extends CoreHTag{
  DivTag({Map<String, List<String>> attributes = const {}, List<HtmlTag> children = const []}):
    super("div", attributes: attributes, children: children);
}
class SpanTag extends CoreHTag{
  SpanTag({Map<String, List<String>> attributes = const {}, List<HtmlTag> children = const []}):
    super("span", attributes: attributes, children: children);
}
class HtmlHTag extends CoreHTag{
  HtmlHTag({Map<String, List<String>> attributes = const {}, List<HtmlTag> children = const []}):
    super("html", attributes: attributes, children: children);
}
class BodyTag extends CoreHTag{
  BodyTag({Map<String, List<String>> attributes = const {}, List<HtmlTag> children = const []}):
    super("html", attributes: attributes, children: children);
}
class HeadTag extends CoreHTag{
  HeadTag({Map<String, List<String>> attributes = const {}, List<HtmlTag> children = const []}):
    super("body", attributes: attributes, children: children);
}
class LinkTag extends CoreHTag{
  LinkTag({Map<String, List<String>> attributes = const {}}):
    super("link", attributes: attributes, children: const [], nonTerminal: true);
}
class StyleSheetLink extends LinkTag{
  StyleSheetLink(String path): super(attributes: {"rel": ["stylesheet"], "type": ["text/css"], "href": [path]});
}
class TitleTag extends CoreHTag{
  String title;
  TitleTag(this.title, {Map<String, List<String>> attributes = const {}}):
    super("title", attributes: attributes, children: [HText(title)]);
}
class BrTag extends CoreHTag{
  BrTag(): super("br", nonTerminal: true);
}
class HText extends CoreHTag{
  String str;
  HText(this.str): super("", nonTerminal: true);
  @override
  String output(){
    return this.str;
  }
}
class Page extends CustomHTag{
  List<String> data;
  String stylesheetPath;
  Page(this.data, this.stylesheetPath);
  @override
  HtmlTag build(){
    return HtmlHTag(children: [
      HeadTag(children: [
        TitleTag("暫定色彩デザインサンプル: Tentative colour design samples"),
        StyleSheetLink(this.stylesheetPath)
        ]),
      BodyTag(children: [
        SampleBoxGrid(this.data.map<HColor>((String e) => HColor.parse(e)).toList())
        ])
    ]);
  }

}
class SampleBoxGrid extends CustomHTag{
  List<HColor> cl;
  SampleBoxGrid(this.cl);
  @override
  HtmlTag build(){
    return DivTag(attributes: {"class": ["sampleGrid"]}, children: 
      this.cl.map<HtmlTag>((HColor e) => SampleBox(e)).toList()
    );
  }
}
class SampleBox extends CustomHTag{
  HColor c;
  SampleBox(this.c);
  @override
  HtmlTag build(){
    return DivTag(attributes: {"class": ["sample"]}, children: [
      DivTag(attributes: {"class": ["box"], "style": ["background-color: ${c.asHex()}"]}),
      DivTag(attributes: {"class": ["text"]}, children: [
        HText(c.asHex())
      ])
    ]);
  }
}
class CSSStyleFile{
  CSSStyleFile();
  String output(){
    return """.sampleGrid{
  margin: 1.5em;
  display: grid;
  column-gap: 0.15em;
  row-gap: 0.17em;
  grid-template-columns: repeat(6, 1fr);
}
.sample{
  padding: 0;
  margin: 0;
}
.sample .box{
  padding: 0;
  margin: 0;
  width: 100%;
  aspect-ratio: 1;
}
.sample .text{
  padding: 0.05em;
  margin: 0;
  font-size: 1.1em;
}""";
  }
}
class HColor{
  double r;
  double g;
  double b;
  HColor._(this.r, this.g, this.b);
  factory HColor.fromRGB(double r, double g, double b) => HColor._(r, g, b);
  factory HColor.fromHex(String src){
    if(src.startsWith("#") && (src.length == 7 || src.length == 9)){
      String t = src.substring(1);
      double r = int.parse(t.substring(0, 2), radix: 16).toDouble();
      double g = int.parse(t.substring(2, 4), radix: 16).toDouble();
      double b = int.parse(t.substring(4, 6), radix: 16).toDouble();
      return HColor._(r, g, b);
    }else{
      throw NotHexColorErr(src);
    }
  }
  factory HColor.fromCMYK(double c, double m, double y, double k) => HColor._(255 * (1- c) * (1 - k), 255 * (1- m) * (1 - k), 255 * (1- y) * (1 - k));
  factory HColor.fromHSL(double h, double s, double l){
    late double min;
    late double max;
    double he = h % 360;
    if(s < 0 || s > 100 || l < 0 || l > 100){
      throw Error();
    }
    if(l < 50){
      max = 2.55 * (l + l * (s / 100));
      min = 2.55 * (l - l * (s / 100));
    }else{
      max = 2.55 * (l + (100 - l) * (s / 100));
      min = 2.55 * (l - (100 - l) * (s / 100));
    }
    if(he < 60){
      return HColor._(max, (he / 60) * (max - min) + min, min);
    }else if(he < 120){
      return HColor._(((120 - he) / 60) * (max - min) + min, max, min);
    }else if(he < 180){
      return HColor._(min, max, ((he - 120) / 60) * (max - min) + min);
    }else if(he < 240){
      return HColor._(min, ((240 - he) / 60) * (max - min) + min, max);
    }else if(he < 300){
      return HColor._(((he - 240) / 60) * (max - min) + min, min, max);
    }else{
      return HColor._(max, min, ((360 - he) / 60) * (max - min) + min);
    }
  }
  String asHex(){
    return "#${this.r.toHex(2)}${this.g.toHex(2)}${this.b.toHex(2)}";
  }
  static HColor parse(String src){
    try{
      HColor h = HColor.fromHex(src);
      return h;
    }on NotHexColorErr catch (e){
      String t = src.toLowerCase();
      List<double> nrs = t.substring(t.indexOf("(") - 1, t.indexOf(")")).csn2list();
      if(nrs.length < 3){
        throw Error();
      }
      if((t.startsWith("rgb(")
      ||t.startsWith("hsl(")
      ||t.startsWith("cmyk(")) && src.endsWith(")")){
        switch (t.substring(0, t.indexOf("("))) {
          case "rgb":
            return HColor.fromRGB(nrs[0], nrs[1], nrs[2]);
          case "hsl":
            return HColor.fromHSL(nrs[0], nrs[1], nrs[2]);
          case "cmyk":
            if(nrs.length == 3){
              return HColor.fromCMYK(nrs[0], nrs[1], nrs[2], 0);
            }else{
              return HColor.fromCMYK(nrs[0], nrs[1], nrs[2], nrs[3]);
            }
          default:
            throw Error();
        }
      }else{
        throw Error();
      }
    }
  }
  static HColor? tryParse(String src){
    try{
      return HColor.parse(src);
    }catch(e){
      return null;
    }
  }
}
extension CSN2NumList on String{
  List<N> csn2list<N>(){
    Iterable<N> t = this.split(",").map<String>((String e) => e.trim())
      .map<N>((String e) {
        switch (N) {
          case int:
            return int.parse(e) as N;
          case double:
            return double.parse(e) as N;
          case num:
            return num.parse(e) as N;
          default:
            throw Error();
        }
      });
    return t.toList();
  }
}
extension Num2Hex<N extends num> on N{
  String toHex([int len = 2]){
    String t = this.floor().toRadixString(16);
    if(t.length == len){
      return t;
    }else if(t.length > len){
      return t.split("").reversed.take(len).toList().reversed.join("");
    }else{
      return t.padLeft(len, "0");
    }
  }
}
class ColorWorkErr extends Error{
  String kind;
  String massage;
  ColorWorkErr(this.kind, this.massage);
  @override
  String toString(){
    return "ColorWorkErr(${this.kind}): ${this.massage}";
  }
}
class NotHexColorErr extends ColorWorkErr{
  String src;
  NotHexColorErr(this.src): super("NotHexColor", "src: ${src}");
}