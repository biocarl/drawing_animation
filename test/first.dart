import 'package:test/test.dart';
import 'package:flutter/material.dart';
import 'package:drawing_animation/src/parser.dart';

void main() {
  SvgParser parser = new SvgParser();

  test('Test Svg path parsing - Unsupported', () {
    //No RGBA
    expect(
        () => parser.loadFromString(
            '<svg height="210" width="400"> <path d="M150 0 L75 200 L225 200 Z" style="stroke:rgba(255,255,255);stroke-width:5.75277775" /> </svg>'),
        throwsUnsupportedError);
  });

  test('Test Svg path parsing - Supported', () {
    //Style attributes successful
    parser.loadFromString(
        '<svg height="210" width="400"> <path d="M150 0 L75 200 L225 200 Z" style="stroke:#FFFFFF;stroke-width:5.0" /> </svg>');
    expect(parser.getPathSegments().first.color, Colors.white);
    expect(parser.getPathSegments().first.strokeWidth, 5.0);
    //Node attributes successful
    parser.loadFromString(
        '<svg height="210" width="400"> <path d="M150 0 L75 200 L225 200 Z" stroke="#FFFFFF" stroke-width="5.0" /> </svg>');
    expect(parser.getPathSegments().first.color, Colors.white);
    expect(parser.getPathSegments().first.strokeWidth, 5.0);
  });

  test('Test path segment parsing', () {
    //Default color
    parser.loadFromPaths(
        [Path()..addRect(Rect.fromCircle(center: Offset.zero, radius: 2.0))]);
    expect(parser.getPathSegments().first.color, Colors.black);
    //Bounding box
    parser.loadFromPaths(
        [Path()..addRect(Rect.fromCircle(center: Offset.zero, radius: 2.0))]);
    expect(parser.getPathSegments().first.length, 16);
  });
}
