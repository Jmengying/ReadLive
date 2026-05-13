import 'dart:convert' as convert;
import 'package:dio/dio.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:readlive/features/book_source/data/rule_context.dart';

/// Handles JavaScript rule execution from Legado book sources.
///
/// Legado rules can contain JavaScript code in two formats:
/// - `<js>code</js>` tags
/// - `@js:code` prefix
///
/// Uses the `flutter_js` package (QuickJS engine) to evaluate JS code.
/// A `java` object is injected into the JS context with Legado-compatible methods.
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

    // Inject the java object with Legado-compatible APIs.
    _runtime!.evaluate("""
      var java = {
        encodeURI: function(s) { return encodeURIComponent(s); },
        put: function(k, v) { sendMessage('JavaBridge', JSON.stringify([k, String(v)])); },
        get: function(k) { return (__ctx && __ctx[k]) ? __ctx[k] : ''; },
        getString: function(k) { return (__ctx && __ctx[k]) ? __ctx[k] : ''; },
        timeFormat: function(ts) {
          var d = new Date(Number(ts) < 1e12 ? Number(ts) * 1000 : Number(ts));
          var pad = function(n) { return n < 10 ? '0' + n : '' + n; };
          return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate()) + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
        },
        t2s: function(s) {
          // Basic Traditional → Simplified Chinese pass-through
          // Most sources work without full conversion
          return String(s);
        },
        base64: function(s) {
          sendMessage('Base64Bridge', JSON.stringify(['encode', String(s)]));
          return (__ctx && __ctx['__b64result']) ? __ctx['__b64result'] : '';
        },
        base64Decode: function(s) {
          sendMessage('Base64Bridge', JSON.stringify(['decode', String(s)]));
          return (__ctx && __ctx['__b64result']) ? __ctx['__b64result'] : '';
        },
        ajax: function(config) {
          // Collect ajax request for later execution
          var url, method = 'GET', body = null, headers = {};
          if (typeof config === 'string') {
            url = config;
          } else if (typeof config === 'object') {
            url = config.url || '';
            method = (config.method || 'GET').toUpperCase();
            body = config.body || config.data || null;
            if (config.headers) headers = config.headers;
          }
          sendMessage('AjaxBridge', JSON.stringify({url: url, method: method, body: body ? String(body) : null, headers: headers}));
          // Return cached result if available, otherwise empty
          return (__ctx && __ctx['__ajaxResult']) ? __ctx['__ajaxResult'] : '';
        },
        ajaxAll: function(urls) { return urls.map(function(u) { return java.ajax(u); }); },
        md5Encode: function(s) {
          function md5cycle(x, k) {
            var a = x[0], b = x[1], c = x[2], d = x[3];
            a = ff(a, b, c, d, k[0], 7, -680876936); d = ff(d, a, b, c, k[1], 12, -389564586);
            c = ff(c, d, a, b, k[2], 17, 606105819); b = ff(b, c, d, a, k[3], 22, -1044525330);
            a = ff(a, b, c, d, k[4], 7, -176418897); d = ff(d, a, b, c, k[5], 12, 1200080426);
            c = ff(c, d, a, b, k[6], 17, -1473231341); b = ff(b, c, d, a, k[7], 22, -45705983);
            a = ff(a, b, c, d, k[8], 7, 1770035416); d = ff(d, a, b, c, k[9], 12, -1958414417);
            c = ff(c, d, a, b, k[10], 17, -42063); b = ff(b, c, d, a, k[11], 22, -1990404162);
            a = ff(a, b, c, d, k[12], 7, 1804603682); d = ff(d, a, b, c, k[13], 12, -40341101);
            c = ff(c, d, a, b, k[14], 17, -1502002290); b = ff(b, c, d, a, k[15], 22, 1236535329);
            a = gg(a, b, c, d, k[1], 5, -165796510); d = gg(d, a, b, c, k[6], 9, -1069501632);
            c = gg(c, d, a, b, k[11], 14, 643717713); b = gg(b, c, d, a, k[0], 20, -373897302);
            a = gg(a, b, c, d, k[5], 5, -701558691); d = gg(d, a, b, c, k[10], 9, 38016083);
            c = gg(c, d, a, b, k[15], 14, -660478335); b = gg(b, c, d, a, k[4], 20, -405537848);
            a = gg(a, b, c, d, k[9], 5, 568446438); d = gg(d, a, b, c, k[14], 9, -1019803690);
            c = gg(c, d, a, b, k[3], 14, -187363961); b = gg(b, c, d, a, k[8], 20, 1163531501);
            a = gg(a, b, c, d, k[13], 5, -1444681467); d = gg(d, a, b, c, k[2], 9, -51403784);
            c = gg(c, d, a, b, k[7], 14, 1735328473); b = gg(b, c, d, a, k[12], 20, -1926607734);
            a = hh(a, b, c, d, k[5], 4, -378558); d = hh(d, a, b, c, k[8], 11, -2022574463);
            c = hh(c, d, a, b, k[11], 16, 1839030562); b = hh(b, c, d, a, k[14], 23, -35309556);
            a = hh(a, b, c, d, k[1], 4, -1530992060); d = hh(d, a, b, c, k[4], 11, 1272893353);
            c = hh(c, d, a, b, k[7], 16, -155497632); b = hh(b, c, d, a, k[10], 23, -1094730640);
            a = hh(a, b, c, d, k[13], 4, 681279174); d = hh(d, a, b, c, k[0], 11, -358537222);
            c = hh(c, d, a, b, k[3], 16, -722521979); b = hh(b, c, d, a, k[6], 23, 76029189);
            a = hh(a, b, c, d, k[9], 4, -640364487); d = hh(d, a, b, c, k[12], 11, -421815835);
            c = hh(c, d, a, b, k[15], 16, 530742520); b = hh(b, c, d, a, k[2], 23, -995338651);
            a = ii(a, b, c, d, k[0], 6, -198630844); d = ii(d, a, b, c, k[7], 10, 1126891415);
            c = ii(c, d, a, b, k[14], 15, -1416354905); b = ii(b, c, d, a, k[5], 21, -57434055);
            a = ii(a, b, c, d, k[12], 6, 1700485571); d = ii(d, a, b, c, k[3], 10, -1894986606);
            c = ii(c, d, a, b, k[10], 15, -1051523); b = ii(b, c, d, a, k[1], 21, -2054922799);
            a = ii(a, b, c, d, k[8], 6, 1873313359); d = ii(d, a, b, c, k[15], 10, -30611744);
            c = ii(c, d, a, b, k[6], 15, -1560198380); b = ii(b, c, d, a, k[13], 21, 1309151649);
            a = ii(a, b, c, d, k[4], 6, -145523070); d = ii(d, a, b, c, k[11], 10, -1120210379);
            c = ii(c, d, a, b, k[2], 15, 718787259); b = ii(b, c, d, a, k[9], 21, -343485551);
            x[0] = add32(a, x[0]); x[1] = add32(b, x[1]); x[2] = add32(c, x[2]); x[3] = add32(d, x[3]);
          }
          function cmn(q, a, b, x, s, t) { a = add32(add32(a, q), add32(x, t)); return add32((a << s) | (a >>> (32 - s)), b); }
          function ff(a, b, c, d, x, s, t) { return cmn((b & c) | ((~b) & d), a, b, x, s, t); }
          function gg(a, b, c, d, x, s, t) { return cmn((b & d) | (c & (~d)), a, b, x, s, t); }
          function hh(a, b, c, d, x, s, t) { return cmn(b ^ c ^ d, a, b, x, s, t); }
          function ii(a, b, c, d, x, s, t) { return cmn(c ^ (b | (~d)), a, b, x, s, t); }
          function md51(s) {
            var n = s.length, state = [1732584193, -271733879, -1732584194, 271733878], i;
            for (i = 64; i <= n; i += 64) md5cycle(state, md5blk(s.substring(i - 64, i)));
            s = s.substring(i - 64);
            var tail = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
            for (i = 0; i < s.length; i++) tail[i >> 2] |= s.charCodeAt(i) << ((i % 4) << 3);
            tail[i >> 2] |= 0x80 << ((i % 4) << 3);
            if (i > 55) { md5cycle(state, tail); tail = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]; }
            tail[14] = n * 8;
            md5cycle(state, tail);
            return state;
          }
          function md5blk(s) {
            var md5blks = [], i;
            for (i = 0; i < 64; i += 4) md5blks[i >> 2] = s.charCodeAt(i) + (s.charCodeAt(i+1) << 8) + (s.charCodeAt(i+2) << 16) + (s.charCodeAt(i+3) << 24);
            return md5blks;
          }
          var hex_chr = '0123456789abcdef'.split('');
          function rhex(n) { var s = '', j = 0; for (; j < 4; j++) s += hex_chr[(n >> (j * 8 + 4)) & 0x0F] + hex_chr[(n >> (j * 8)) & 0x0F]; return s; }
          function hex(x) { for (var i = 0; i < x.length; i++) x[i] = rhex(x[i]); return x.join(''); }
          function add32(a, b) { return (a + b) & 0xFFFFFFFF; }
          return hex(md51(s));
        }
      };
    """);

    // Set up Base64 bridge (Dart handles encoding/decoding).
    _runtime!.onMessage('Base64Bridge', (dynamic args) {
      if (args is List && args.length >= 2) {
        final action = args[0].toString();
        final data = args[1].toString();
        try {
          if (action == 'encode') {
            _jsContext['__b64result'] = convert.base64Encode(convert.utf8.encode(data));
          } else if (action == 'decode') {
            _jsContext['__b64result'] = convert.utf8.decode(convert.base64Decode(data));
          }
        } catch (_) {
          _jsContext['__b64result'] = '';
        }
      }
    });

    // Set up AJAX bridge (collects requests for later execution).
    _runtime!.onMessage('AjaxBridge', (dynamic args) {
      try {
        final Map<String, dynamic> config;
        if (args is String) {
          config = convert.jsonDecode(args);
        } else if (args is Map) {
          config = Map<String, dynamic>.from(args);
        } else {
          return;
        }
        _pendingAjax.add(_AjaxRequest(
          url: config['url']?.toString() ?? '',
          method: config['method']?.toString() ?? 'GET',
          body: config['body']?.toString(),
          headers: config['headers'] is Map
              ? Map<String, String>.from(config['headers'])
              : {},
        ));
      } catch (_) {}
    });
  }

  /// Execute pending AJAX requests and inject results into JS context.
  Future<void> _executePendingAjax() async {
    if (_pendingAjax.isEmpty) return;

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
    ));

    for (final req in _pendingAjax) {
      try {
        final options = Options(
          method: req.method,
          headers: req.headers.isEmpty ? null : req.headers,
        );
        final response = await dio.request<String>(
          req.url,
          data: req.body,
          options: options,
        );
        final result = response.data ?? '';
        _jsContext['__ajaxResult'] = result;
        // Also set as 'result' variable for convenience
        _runtime!.evaluate("var result = '${_escapeJs(result)}';");
      } catch (_) {
        _jsContext['__ajaxResult'] = '';
      }
    }

    dio.close();
    _pendingAjax.clear();
  }

  /// Pending AJAX requests collected during JS execution.
  final List<_AjaxRequest> _pendingAjax = [];

  /// Execute JavaScript code within the given [context].
  ///
  /// The code is expected to set a `result` variable whose value will be
  /// returned as a string. If `result` is not defined, returns `null`.
  ///
  /// Variables stored via `java.put(key, val)` in JS are synced back to
  /// the [RuleContext] after execution.
  ///
  /// [baseUrl] is injected as a JS global variable for Legado rules that
  /// reference it (e.g. `baseUrl.match(...)`).
  /// [result] is injected as the pre-set `result` variable.
  Future<String?> execute(
    String jsCode,
    RuleContext context, {
    String? baseUrl,
    String? result,
  }) async {
    _ensureInitialized();

    // Sync RuleContext variables into JS so java.get() can access them.
    _syncContextToJs(context);

    // Inject baseUrl as a JS global if provided.
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _runtime!.evaluate("var baseUrl = '${_escapeJs(baseUrl)}';");
    }

    // Inject result as a JS global if provided.
    if (result != null) {
      _runtime!.evaluate("var result = '${_escapeJs(result)}';");
    }

    // Wrap code in an IIFE that returns the `result` variable.
    final wrappedCode = '''
      (function() {
        $jsCode
        return typeof result !== 'undefined' ? String(result) : '';
      })()
    ''';

    try {
      // First pass: execute JS, collecting any ajax requests
      _pendingAjax.clear();
      var evalResult = _runtime!.evaluate(wrappedCode);

      // If there are pending ajax requests, execute them and re-run
      if (_pendingAjax.isNotEmpty) {
        await _executePendingAjax();
        // Re-run with ajax results injected
        evalResult = _runtime!.evaluate(wrappedCode);
      }

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
    _pendingAjax.clear();
  }
}

class _AjaxRequest {
  final String url;
  final String method;
  final String? body;
  final Map<String, String> headers;

  const _AjaxRequest({
    required this.url,
    required this.method,
    this.body,
    this.headers = const {},
  });
}
