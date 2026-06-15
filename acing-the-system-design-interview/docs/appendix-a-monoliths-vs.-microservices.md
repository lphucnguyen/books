# Appendix A  Monoliths vs. microservices


provided API may fetch much more data than required by the UI, which causes 
unnecessary latency. For APIs that are developed internally, the UI team may 
wish to request some API redesign and rework for less complex and more effi-
## cient API requests.
A.4.6	
### Interfaces
Services can be written in different languages and communicate with each other via a 
text or binary protocol. In the case of text protocols like JSON or XML, these strings 
need to be translated to and from objects. There is additional code required for vali-
dation and error and exception handling for missing fields. To allow graceful degrada-
tion, our service may need to process objects with missing fields. To handle the case of 
our dependent services returning such data, we may need to implement backup steps 
such as caching data from dependent services and returning this old data, or perhaps 
also return data with missing fields ourselves. This may cause implementation to differ 
from documentation.
A.5	
## References
This appendix uses material from the book Microservices for the Enterprise: Designing, 
Developing, and Deploying by Kasun Indrasiri and Prabath Siriwardena (2018, Apress).


<!-- PAGE 435 -->
 435 -->

B
OAuth 2.0 authorization 
and OpenID Connect 
authentication1
B.1	
## Authorization vs. authentication
Authorization is the process of giving a user (a person or system) permission to access 
a specific resource or function. Authentication is identity verification of a user. OAuth 
2.0 is a common authorization algorithm. (The OAuth 1.0 protocol was published 
in April 2010, while OAuth 2.0 was published in October 2012.) OpenID Connect is 
an extension to OAuth 2.0 for authentication. Authentication and authorization/
access control are typical security requirements of a service. OAuth 2.0 and OpenID 
Connect may be briefly discussed in an interview regarding authorization and 
authentication. 
A common misconception online is the idea of “login with OAuth2.” Such online 
resources mix up the distinct concepts of authorization and authentication. This 
section is an introduction to authorization with OAuth2 and authentication with 
OpenID Connect and makes their authorization versus authentication distinction 
clear. 
1	 This section uses material from the video “OAuth 2.0 and OpenID Connect (in plain English),” http:// 
oauthacademy.com/talk, an excellent introductory lecture by Nate Barbettini, and https://auth0.com/docs. 
Also refer to https://oauth.net/2/ for more information.


<!-- PAGE 436 -->
 436 -->

