Rack-DeflectRedis
=================

Rack middleware to counter DoS Attacks by blocking bad requests before they reach your app using Redis as backend

This middleware is designed for small deployments, which most likely are not utilizing load balancing from other software or hardware. Using Redis as the backend is particularly useful in cloud hosting environments like Heroku and others where the only shared information between the nodes is the network attached database.

Deflect currently supports the following functionality:

 * Saturation prevention (small DoS attacks, or request abuse)
 * Blocking from the apps response (via special headers)
 * Whitelisting of known good remote addresses
 * Applies only for given REQUEST_METHODS (defaults to all types)
 * Logging
 * Falling back to block / allow all when redis fails

Options:
===

*   :log                When false logging will be bypassed, otherwise pass an object responding to #puts
*   :log_format         Alter the logging format
*   :log_date_format    Alter the logging date format
*   :request_threshold  Number of requests allowed within the set :interval. Defaults to 100
*   :interval           Duration in seconds until the request counter is reset. Defaults to 5
*   :block_duration     Duration in seconds that a remote address will be blocked. Defaults to 900 (15 minutes)
*   :skip_for           Array of remote addresses which bypass Deflect. NOTE: this does not block others
*   :default_block      When true, blocks requests when redis failed for whatever reason
*   :request_methods    Regexp object. This middleware is only applied if the regexp matches the request method
*   :redis_host => "127.0.0.1"
*   :redis_port => 6379
*   :redis_db => 0
*   :redis_timeout => 5 
*   :redis_password => nil

Examples:
===
```ruby
use Rack::DeflectRedis, :log => $stdout, :request_threshold => 20, :interval => 5, :block_duration => 60
```
This will deny all requests for 60 secounds after 20 requests were made within 5 secs.

CREDIT:
===
 Marvin Frick <marv@hostin.is> based on Rack::Deflect by TJ Holowaychuk <tj@vision-media.ca>