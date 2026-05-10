/// Resolve a potentially relative URL against a host base URL.
String resolveUrl(String host, String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('/')) {
    final uri = Uri.parse(host);
    return '${uri.scheme}://${uri.host}$url';
  }
  return '$host/$url';
}
