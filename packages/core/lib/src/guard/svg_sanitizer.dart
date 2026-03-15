import 'package:xml/xml.dart';
import '../errors/iconify_exception.dart';

/// Modes for SVG sanitization.
enum SanitizerMode {
  /// Throws [SvgSanitizationException] if any dangerous element or attribute is found.
  /// Used for official starter sets.
  strict,

  /// Silently strips dangerous elements and attributes.
  /// Used for remote and custom sets.
  lenient,
}

/// A security-focused SVG sanitizer.
///
/// Strips potentially malicious content like `<script>`, event handlers,
/// and external references while preserving structural SVG elements.
class SvgSanitizer {
  const SvgSanitizer({this.mode = SanitizerMode.lenient});

  final SanitizerMode mode;

  /// Sanitizes an SVG body string.
  ///
  /// The [body] should be the content inside the `<svg>` tag.
  /// Returns the sanitized body string.
  String sanitize(String body) {
    if (body.isEmpty) return body;

    try {
      // Wrap in a root element to make it a valid XML document fragment
      final xmlString = '<root>$body</root>';
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;

      _sanitizeElement(root);

      // Return children's inner XML to get back the body
      return root.children.map((c) => c.toXmlString()).join();
    } on XmlException catch (e) {
      if (mode == SanitizerMode.strict) {
        throw IconifyParseException(
            message: 'Invalid XML in SVG body: ${e.message}');
      }
      // In lenient mode, we might just return an empty string or the original if it's not even XML,
      // but usually, we want to at least try to be safe.
      return '';
    }
  }

  void _sanitizeElement(XmlElement element) {
    final toRemove = <XmlNode>[];

    for (final child in element.children) {
      if (child is XmlElement) {
        if (_isForbiddenElement(child)) {
          if (mode == SanitizerMode.strict) {
            throw SvgSanitizationException(
                message: 'Forbidden SVG element: <${child.name.local}>');
          }
          toRemove.add(child);
          continue;
        }

        _sanitizeAttributes(child);
        _sanitizeElement(child);
      } else if (child is XmlCDATA ||
          child is XmlComment ||
          child is XmlDoctype) {
        // Strip CDATA, comments, and doctypes for extra safety
        toRemove.add(child);
      }
    }

    for (final node in toRemove) {
      node.remove();
    }
  }

  bool _isForbiddenElement(XmlElement element) {
    final name = element.name.local.toLowerCase();
    return name == 'script' || name == 'foreignobject';
  }

  void _sanitizeAttributes(XmlElement element) {
    final attributesToRemove = <XmlAttribute>[];

    for (final attribute in element.attributes) {
      final attrName = attribute.name.local.toLowerCase();

      // 1. Strip event handlers (on*)
      if (attrName.startsWith('on')) {
        if (mode == SanitizerMode.strict) {
          throw SvgSanitizationException(
              message: 'Forbidden event handler attribute: $attrName');
        }
        attributesToRemove.add(attribute);
        continue;
      }

      // 2. Strip dangerous hrefs
      if (attrName == 'href' ||
          attrName == 'xlink:href' ||
          attribute.name.qualified.toLowerCase() == 'xlink:href') {
        final value = attribute.value.toLowerCase().trim();

        // Block javascript: and data: URIs
        if (value.startsWith('javascript:') || value.startsWith('data:')) {
          if (mode == SanitizerMode.strict) {
            throw SvgSanitizationException(
                message: 'Forbidden URI scheme in $attrName: $value');
          }
          attributesToRemove.add(attribute);
          continue;
        }

        // Block external references in <use>
        if (element.name.local.toLowerCase() == 'use' &&
            !value.startsWith('#')) {
          if (mode == SanitizerMode.strict) {
            throw SvgSanitizationException(
                message: 'Forbidden external reference in <use>: $value');
          }
          attributesToRemove.add(attribute);
          continue;
        }
      }

      // 3. Strip dangerous CSS in style
      if (attrName == 'style') {
        final value = attribute.value.toLowerCase();
        if (value.contains('expression(') ||
            value.contains('url(javascript:') ||
            value.contains('url(data:')) {
          if (mode == SanitizerMode.strict) {
            throw const SvgSanitizationException(
                message: 'Forbidden CSS in style attribute');
          }
          attributesToRemove.add(attribute);
          continue;
        }
      }
    }

    for (final attr in attributesToRemove) {
      element.attributes.remove(attr);
    }
  }
}
