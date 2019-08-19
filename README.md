# gmail-expensify-forwarder

Forwards emails from Gmail to Expensify.

# Why?

1. All forwarding addresses within Gmail need to be verified.
2. Expensify doesn't know how to forward verification codes to individual accounts.
3. Consequently, you can't add `receipts@expensify.com` as a verified forwarding address.
4. Every other email provider that I've tried to use to get around this either:
  1. Blocks me as spam (looking at you, Outlook), or
  2. Refuses to forward the email due to technical limitations.
5. IFTTT's Gmail integration can't send messages based on labels anymore due to API
  limitations.
6. Zapier works, but I don't want to pay them $20/month for this service.

# How to run

`docker-compose run --rm forwarder`.
