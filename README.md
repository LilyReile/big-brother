# Big Brother

My little brother takes advantage of the fact that our mother is not tech-savvy enough to check the grades on his school website.

Enter Big Brother.

This AWS SAM project scrapes his grades and sends his mother reports via SMS.

![Big Brother SMS](https://raw.githubusercontent.com/DylanReile/big-brother/master/images/big_brother.png)

## Technical Overview
Aside from giving my little brother some accountability, the goal of this project was to learn bleeding-edge serverless technologies.
Instead of servers, AWS SAM allows developers to outline project resources in a [template file](/template.yaml).

The resources used here are:
1. An AWS Lambda function targeting the Ruby 2.5 runtime with a specified [entry point](/lib/big_brother.rb).
2. An AWS DynamoDB table used to keep track of which grades have been reported.
3. An AWS CloudWatch scheduled rule that invokes the lambda function daily.

That's it! Aside from that, this is a regular Ruby project.

Bundler is used for dependency management.

RSpec is used for unit tests.

AWS CodePipeline provides continuous integration and continuous delivery.

AWS CloudWatch provides automatic monitoring and logging.

## Notable Design Decisions

### Encrypted VCR Cassettes
This was a real thinker. [VCR](https://github.com/vcr/vcr) is a gem that allows HTTP interactions to be recorded. These "cassettes" are then replayed in specs in order to stub out third-party requests. On one hand, these cassettes contain sensitive information inappropriate for a public repo. On the other hand, the CI environment (AWS CodeBuild) needs them to run the unit tests.

My initial solution was to manually redact the sensitive information--editing a few thousand lines wouldn't be too bad. However, every developer who has written a web scraper knows that they frequently break due to markup changes on the third-party site. When that inevitably happens, I would need to regenerate the cassettes and manually redact them again.

Instead of this sisyphean task, I decided to commit encrypted versions of the cassettes. CI installs [YAML Vault](https://github.com/joker1007/yaml_vault), pulls the secret key from AWS SSM, and [decrypts the cassettes](/buildspec.yml#L17) before running RSpec.

### Custom Twilio Client
The official Twilio gem has a dependency on Nokogiri, which has a dependency on native binary extensions. It is possible to provide native libraries through AWS Lambda Layers, but the configuration is more complex than just POSTing with Faraday.

### Web Scraping
Without the luxury of an API, I was forced to scrape the school's legacy ASP.net WebForms site. This requires an inelegant sequence of calls mimicked by watching the Network tab in the Chrome developer console.

### AWS Systems Manager Parameter Store
AWS SSM provides an elegant way to handle sensitive environment variables. Simply store them via the AWS SSM CLI and reference them by name in the [template](/template.yaml#L18).
