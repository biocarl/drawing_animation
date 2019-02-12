import 'package:test/test.dart';
import 'package:drawing_animation/src/parser.dart';

void main() {
  SvgParser parser = new SvgParser();
  test('Test exceptions for color parsing', () {
    //Css-Styling
    expect(
        () => parser.loadFromString(
            '<svg height="210" width="400"> <path style="stroke:rgba(255,255,255);stroke-width:5.75277775" d="M150 0 L75 200 L225 200 Z" /> </svg>'),
        throwsUnsupportedError);
    expect(
        () => parser.loadFromString(
            '<svg height="210" width="400"> <path style="stroke: ;stroke-width:5.75277775" d="M150 0 L75 200 L225 200 Z" /> </svg>'),
        throwsUnsupportedError);

    //Attribute-styling
    expect(
        () => parser.loadFromString(
            '<svg height="210" width="400"> <path stroke="rgba(255,255,255)" stroke-width="5.75277775" d="M150 0 L75 200 L225 200 Z" /> </svg>'),
        throwsUnsupportedError);
    expect(
        () => parser.loadFromString(
            '<svg height="210" width="400"> <path stroke=" " stroke-width="5.75277775" d="M150 0 L75 200 L225 200 Z" /> </svg>'),
        throwsUnsupportedError);
  });

  test('Test Color parsing', () {});
}
