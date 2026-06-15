# Appendix B  OAuth 2.0 authorization and OpenID Connect authentication


Table B.1 summarizes the use cases of OAuth 2.0 (authorization) vs. OpenID Con-
nect (authentication). 
Table B.1    Use cases of OAuth 2.0 (authorization) vs. OpenID Connect (authentication)
OAuth2 (authorization)
## OpenID Connect (authentication)
Grant access to your API.
User login
Get access to user data in other systems.
Make your accounts available in other systems.
An ID token consists of three parts: 
¡ Header—Contains several fields, such as the algorithm used to encode the 
signature. 
¡ Claims—The ID token body/payload. The client decodes the claims to obtain the 
user information. 
¡ Signature—The client can use the signature to verify that the ID token has not 
been changed. That is, the signature can be independently verified by the client 
application without having to contact the authorization server. 
The client can also use the access token to request the authorization server’s user info 
endpoint for more information about the user, such as the user’s profile picture. Table 
B.2 describes which grant type to use for your use case. 
Table B.2    Which grant type to use for your use case
Web application with server backend
Authorization code flow
Native mobile app
Authorization code flow with PKCE 
(Proof Key for Code Exchange) (outside 
the scope of this book)
JavaScript Single-Page App (SPA) with 
API backend
Implicit flow
Microservices and APIs
Client credentials flow


 445 -->

C
The C4 model (https://c4model.com/) is a system architecture diagram technique 
created by Simon Brown to decompose a system into various levels of abstraction. 
This section is a brief introduction to the C4 model. The website has good intro-
ductions and in-depth coverage of the C4 model, so we will only briefly go over the 
C4 model here; readers should refer to the website for more details. The C4 model 
defines four levels of abstraction.
A context diagram represents the system as a single box, surrounded by its users 
and other systems that it interacts with. Figure C.1 is an example context diagram 
of a new internet banking system that we wish to design on top of our existing main-
frame banking system. Its users will be our personal banking customers, who will use 
our internet banking system via UI apps we develop for them. Our internet banking 
system will also use our existing email system. In figure C.1, we draw our users and 
systems as boxes and connect them with arrows to represent the requests between 
them. 
**C4 Model**


 446 -->

