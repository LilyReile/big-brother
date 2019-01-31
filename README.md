## Big Brother

My little brother takes advantage of the fact that our mother is not tech-savvy enough to check his grades on his school's site.

Enter Big Brother.

This AWS SAM project scrapes his grades from his school's site and sends his mother reports via SMS (Twilio).

It persists grades in a DynamoDB table that it uses to keep track of which grades have been reported.

It's invoked daily by an AWS CloudWatch scheduled event.
