function handler(event) {
    const request = event.request;
    if (request.uri.indexOf('.') === -1) {
        request.uri = '/index.html';
    }
    return request;
}
