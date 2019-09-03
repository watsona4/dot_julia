# SecretSanta.jl
SecretSanta.jl is a Julia package for generating Secret Santa matchings and emailing participants.

## Build status

| [Linux][ci-link]  | [OSX][ci-link]    | [Codecov][cov-link]   |
| :---------------: | :---------------: | :-------------------: |
| ![ci-badge]       | ![ci-badge]       | ![cov-badge]          |

[ci-badge]: https://travis-ci.com/tasseff/SecretSanta.jl.svg?branch=master "Travis build status"
[ci-link]: https://travis-ci.com/tasseff/SecretSanta.jl "Travis build status"
[cov-badge]: https://codecov.io/gh/tasseff/SecretSanta.jl/branch/master/graph/badge.svg
[cov-link]: https://codecov.io/gh/tasseff/SecretSanta.jl

## Usage
### JSON Schema
Setup is controlled via a JSON document, an example of which can be found [here](test/test.json).
First, email settings are controlled via the `email` block:
```json
"email": {
    "smtp_server": "smtp.example.com",
    "smtp_port": 465,
    "username": "user@example.com",
    "password": "123456",
    "subject": "Your Secret Santa recipient is {recipient}!",
    "message": "Hello, {sender}! Your Secret Santa recipient is {recipient} ({recipient_email}). The maximum spending limit is $100.00. Merry Christmas!"
}
```
When using the email option, the package assumes the user has access to an SMTP email server.
If using Gmail, you will need to [allow less secure apps to access your account](https://myaccount.google.com/lesssecureapps).
Within this JSON block, `smtp_server` and `smtp_port` are the address and port of the SMTP server; `username` and `password` are the credentials for the corresponding email account; and `subject` and `message` define the email template that will be used when emailing participants.
Here, `{recipient}` and `{recipient_email}` correspond to the giftee, and `{sender}` corresponds to the gifter.

The `participants` block defines information relevant to Secret Santa participants.
Each participant is defined as an object with a `name`, `email`, and list of participants to `exclude` from the participant's possible matchings (e.g., husband and wife).
Here is an example participant object:
```json
 {
    "email": "olstnick@example.com",
    "name": "Saint Nicholas",
    "exclude": [
        "lovedafather@example.com"
     ]
}
```
This is a participant entry for [Saint Nicholas](https://en.wikipedia.org/wiki/Saint_Nicholas), whose email is `olstnick@example.com`.
This email serves as his unique identifier.
The exclude field will prevent him from gifting [Arius](https://en.wikipedia.org/wiki/Arius), whose email is `lovedafather@example.com`.
Other participant entries can be defined similarly.

### Performing a Test Run
Performing a test run can be completed via the Julia interface, e.g.,
```julia
using SecretSanta
SecretSanta.run("/path/to/input.json", test = true)
```

### Sending the Emails
Performing a live run can be completed via the Julia interface, e.g.,
```julia
using SecretSanta
SecretSanta.run("/path/to/input.json", test = false)
```
Note that matchings will be hidden from the user that executes the command.
