var saml2 = require('saml2-js');
var fs = require('fs');
var express = require('express');
var bodyParser = require('body-parser')
var app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true })); 
// Create service provider 
var sp_options = {
  entity_id: "https://www.xcryptolab.com:8443",
  private_key: fs.readFileSync("key-file.pem").toString(),
  certificate: fs.readFileSync("cert-file.crt").toString(),
  assert_endpoint: "https://www.xcryptolab.com:8443/assert",
  allow_unencrypted_assertion: true,
  nameid_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
};
var sp = new saml2.ServiceProvider(sp_options);
 
// Create identity provider 
var idp_options = {
  sso_login_url: "https://login.microsoftonline.com/a62a9e18-d778-4d72-9deb-7ba3712b8db3/saml2",
  sso_logout_url: "https://idp.sancho.net/idp/profile/Logout",
  certificates: [fs.readFileSync("navistardevazure.crt").toString()],
  allow_unencrypted_assertion: true
};
var idp = new saml2.IdentityProvider(idp_options);
 
// ------ Define express endpoints ------ 
 
// Endpoint to retrieve metadata 
app.get("/metadata.xml", function(req, res) {
  res.type('application/xml');
  res.send(sp.create_metadata());
});
 
// Starting point for login 
app.get("/login", function(req, res) {
  sp.create_login_request_url(idp, {}, function(err, login_url, request_id) {
    if (err != null) {
      console.log(err);
      return res.send(500);
      }
    res.redirect(login_url);
  });
});
 
// Assert endpoint for when login completes 
app.post("/assert", function(req, res) {
  var options = {request_body: req.body};
  sp.post_assert(idp, options, function(err, saml_response) {
    if (err != null) {
      console.log(err);
      return res.send(500);
    }
 
    // Save name_id and session_index for logout 
    // Note:  In practice these should be saved in the user session, not globally. 
    name_id = saml_response.user.name_id;
    session_index = saml_response.user.session_index;
    console.log("saml response = " + JSON.stringify(saml_response)); 
    res.send("Hello " + saml_response.user.name_id + "<br>" + "I have to say... " + JSON.stringify(saml_response.user.attributes));
  });
}); 


// logout url
app.get("/logout", function(req, res) {
  var options = {
    name_id: name_id,
    session_index: session_index
  };
 
  sp.create_logout_request_url(idp, options, function(err, logout_url) {
    if (err != null)
      return res.send(500);
    res.redirect(logout_url);
  });
});
 
app.listen(6666);
