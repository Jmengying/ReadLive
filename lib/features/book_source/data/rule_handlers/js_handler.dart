import 'package:flutter_js/flutter_js.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';

/// Handles JavaScript rule execution from Legado book sources.
///
/// Legado rules can contain JavaScript code in two formats:
/// - `<js>code</js>` tags
/// - `@js:code` prefix
///
/// Uses the `flutter_js` package (QuickJS engine) to evaluate JS code.
/// A `java` object is injected into the JS context with methods:
/// - `java.encodeURI(s)` — URL-encodes a string
/// - `java.put(key, value)` — stores a value in the RuleContext
/// - `java.get(key)` — retrieves a value from the RuleContext
class JsHandler {
  JavascriptRuntime? _runtime;
  bool _initialized = false;

  /// Dart-side mirror of the JS context variables.
  /// Used to provide values for `java.get()` without round-tripping through JS.
  final Map<String, String> _jsContext = {};

  /// Ensure the QuickJS runtime is initialized and the `java` object is
  /// injected with its bridge functions.
  void _ensureInitialized() {
    if (_initialized && _runtime != null) return;
    // Create QuickJsRuntime2 directly instead of using getJavascriptRuntime()
    // to avoid enableFetch() which requires Flutter asset bundle initialization.
    _runtime = QuickJsRuntime2();
    _initialized = true;

    // Set up the bridge for java.put → Dart context updates.
    // When JS calls java.put(key, val), it sends a message via
    // sendMessage which is routed to this Dart callback.
    _runtime!.onMessage('JavaBridge', (dynamic args) {
      if (args is List && args.length >= 2) {
        final key = args[0].toString();
        final value = args[1].toString();
        _jsContext[key] = value;
        // Note: we sync back to the RuleContext in _syncJsToContext.
      }
    });

    // Inject the java object and encodeURI polyfill.
    // java.put uses sendMessage to bridge to Dart.
    // java.get reads from __ctx which is synced before each execution.
    _runtime!.evaluate("""
      var java = {
        encodeURI: function(s) { return encodeURIComponent(s); },
        put: function(k, v) { sendMessage('JavaBridge', JSON.stringify([k, String(v)])); },
        get: function(k) { return (__ctx && __ctx[k]) ? __ctx[k] : ''; }
      };
    """);
  }

  /// Execute JavaScript code within the given [context].
  ///
  /// The code is expected to set a `result` variable whose value will be
  /// returned as a string. If `result` is not defined, returns `null`.
  ///
  /// Variables stored via `java.put(key, val)` in JS are synced back to
  /// the [RuleContext] after execution.
  Future<String?> execute(String jsCode, RuleContext context) async {
    _ensureInitialized();

    // Sync RuleContext variables into JS so java.get() can access them.
    _syncContextToJs(context);

    // Wrap code in an IIFE that returns the `result` variable.
    final wrappedCode = '''
      (function() {
        $jsCode
        return typeof result !== 'undefined' ? String(result) : '';
      })()
    ''';

    try {
      final evalResult = _runtime!.evaluate(wrappedCode);

      if (evalResult.isError) {
        return null;
      }

      // Sync any java.put values back to the RuleContext.
      _syncJsToContext(context);

      final value = evalResult.stringResult;
      if (value == 'null' || value.isEmpty) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Sync Dart's RuleContext variables into the JS runtime as `__ctx`.
  void _syncContextToJs(RuleContext context) {
    // Merge RuleContext into our local mirror.
    for (final entry in context.variables.entries) {
      _jsContext[entry.key] = entry.value;
    }

    // Build a JS object literal from the context entries.
    final entries = _jsContext.entries
        .map((e) =>
            "'${_escapeJs(e.key)}': '${_escapeJs(e.value)}'")
        .join(', ');

    _runtime!.evaluate("var __ctx = {$entries};");
  }

  /// Sync JS-side context (via java.put bridge) back to the RuleContext.
  void _syncJsToContext(RuleContext context) {
    for (final entry in _jsContext.entries) {
      context.put(entry.key, entry.value);
    }
  }

  /// Escape a string for safe embedding in a JS single-quoted string literal.
  String _escapeJs(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  /// Check whether a rule string contains JavaScript code.
  ///
  /// Detects both `<js>...</js>` tags and `@js:` prefix formats.
  static bool isJsRule(String rule) {
    final trimmed = rule.trim();
    return trimmed.contains('<js>') || trimmed.startsWith('@js:');
  }

  /// Extract the JavaScript code from a rule string.
  ///
  /// Handles both formats:
  /// - `<js>code</js>` → extracts code between tags
  /// - `@js:code` → strips the prefix
  static String extractJsCode(String rule) {
    final trimmed = rule.trim();
    if (trimmed.startsWith('@js:')) {
      return trimmed.substring(4);
    }
    final match = RegExp(r'<js>(.*?)</js>', dotAll: true).firstMatch(trimmed);
    if (match != null) {
      return match.group(1)!;
    }
    return trimmed;
  }

  /// Dispose of the QuickJS runtime. Call when the handler is no longer needed.
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    _initialized = false;
    _jsContext.clear();
  }
}
