# a10-tkc-ssl-offload
Setup a Thunder node to Offload SSL processing from a Cloud Application running on Kubernetes and using the A10 Thunder Kubernetes Connector (TKC) to configure the Thunder node

This demo setups a Thunder node with SSL cert & key so that it can process the SSL/TLS of an HTTPS connection, decrypt the payload, and send down to the Application Pods in the Kubernetes Cloud just the HTTP packets. This will reduce the processing load on the Application Pods by not having to decrypt/encrypt SSL.

Notice there there is an "ID.tf" file that I use to mark my Kubernetes main node with which demo I am running. This most likely will not be needed in your environment, so feel free to delete it.

