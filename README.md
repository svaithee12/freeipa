freeipa
=======

Small scripts and customization for FreeIPA / Red Hat IdM

Short summary of "features":
* Pulls the last successfull login from FreeIPA / IdM.
* If the user has not logged in within a specified timerange, the user is disabled.
* If the user has not logged in in an ever longer range then that, an email is send so that the administrator can clean the user up.
