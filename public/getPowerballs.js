function onPowerballsClick(state) {
  var xhttp = new XMLHttpRequest();
  var request = {
    method: 'GET',
    parameters: '',
    path: '/api/powerballs'
  };

  xhttp.open(request.method, request.path, true);
  
  // Adds signed authorization header
  if (state == 'auth') {
    // How to hide secret key?
    var signature = signRequest(request, 'fghij');
    xhttp.setRequestHeader("Authorization", "abcde:" + signature);
  }

  // Make the request
  xhttp.send();

  // Response handler
  xhttp.onreadystatechange = function() {
    if (xhttp.readyState == 4 && xhttp.status == 200) {
      var response = JSON.parse(xhttp.response);
      var list = document.getElementById('powerballs_list');
      var element = document.createElement('li');
      var powerballs = response.powerballs.join(', ');

      element.appendChild(document.createTextNode(powerballs));
      list.appendChild(element);
    } else if (xhttp.readyState == 4 && xhttp.status == 401) {
      alert(xhttp.response);
    }
  }
}

// Returns signed authorization string "public_key:signature"
function signRequest(request, secretKey) {
  var string = request.method + request.parameters + request.path;
  var hash = CryptoJS.HmacSHA256(string, secretKey);
  return CryptoJS.enc.Base64.stringify(hash);
}