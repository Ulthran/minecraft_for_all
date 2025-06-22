function handler(event) {
    var request = event.request;
    var uri = request.uri;
  
    if (!uri.includes('.') && !uri.endsWith('/')) {
      request.uri += '/';
    }
  
    if (request.uri.endsWith('/')) {
      request.uri += 'index.html';
    }
  
    return request;
  }
  