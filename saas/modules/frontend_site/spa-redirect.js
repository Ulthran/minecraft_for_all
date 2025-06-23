function handler(event) {
  var request = event.request;
  var uri = request.uri;

  // If the request is not for a specific file, serve the SPA entry point.
  if (!uri.includes('.')) {
    request.uri = '/index.html';
  }

  return request;
}
  