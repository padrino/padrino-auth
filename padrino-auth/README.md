## Authorization and authentication modules for Padrino framework

### Overview

This padrino-auth provides the means to authenticate and authorize users.
These modules are designed to be independent but compatible with each other.

### Padrino::Login, an authentication module for Padrino

Authentication means identifying the user by comparing provided parameters
(usually login or email and password) with the credentials stored in the
application database and selecting the matched one. This module provides
a simple login form and related helpers methods including saving and
restoring user location.

#### Usage

##### Holding a session

Make sure you have sessions enabled: `enable :sessions`.

If you use a different persistence storage you will have to make #session hash
available to call in your app. `Padrino::Login` stores credentials `id` in
session[settings.session_key]. You can customize session_key by calling
`set :session_key, :current_credentials_id`. Default session_key name is
`"_login_#{app.app_name}"`.

##### Taming a model

By default `Padrino::Login` uses credentials model name `Account`. You can
customize it by setting `set :login_model, :user`.

Usually a set of credentials are stored in application database. To access
stored credentials `Padrino::Login` uses `Account.authenticate` class method.
The Account model must provide this class method in at least two forms:
authenticate with email/password, or with id. `Account.authenticate` is called

 * with hash like `{ :email => 'user@example.com', :password => 'mypass' }`
   to authenticate by email and password in response to user request
 * with hash `{ :id => 42 }` to restore credentials from session

##### Accessing credentials (optional)

To be able to access current credentials of the signed user your app will
have to provide application helpers. By default `Padrino::Login` adds simple
reader and writer with names `credentials` and `credentials=(user)`. You can
customize helper name by setting `set :credentials_accessor, :visitor` and you
can override default accessor by defining your own reader and writer helpers
with the said names.

 * the reader is called before checking if the user is signed in
 * the writer is called after authenticating user's credentials or restoring
   it from session

##### Bypassing authentication (optional)

By default this option is disabled. To enable it you can call
`enable :login_bypass`. 

In development environment it sometimes is convenient to be able to bypass
authentication. If you do this you also have to extend your model
`Account.authenticate` class method to be able to return default credentials in
response to hash `{ :bypass => true }`. This way if the user authenticates with
parameter `bypass` she will be assigned the credentials returned by you model
and redirected to the stored location.

##### Customizing the login process (optional)

By default `Padrino::Login` registers a simple login controller for your app
and binds it to `/login`.

To customize this url it you can call `set :login_url, '/signin'`. Also it's
possible to disable registering the default controller by calling
`disable :login_controller`. If you do so you should provide a controller for
your custom login url which on request of authentication will call
`#authenticate` helper. If the result is true it should call
`#restore_location`, else it should show an error. Or you can do whatever you
like, it's your controller after all.

##### Synergizing with Padrino::Access and other things (info)

`Padrino::Login` tries to inform `Padrino::Access` that `/login` url should be
accessible for unauthenticated users by setting default
`set(:login_permissions) { set_access(:*, :allow => :*, :with => :login) }`.
Yes, it's a Proc and `Padrino::Access` tries to call it when registers itself.

If you name your controller another way you must redefine this. If you use
another authorization solution you also should configure it to allow visiting
`/login` url without having to authenticate.

##### Redirecting the user (info)

To authenticate users `Padrino::Login` defines Sinatra `before_filter` which
checks things and acts accordingly.

The first thing is if the user is already logged in. It uses the credentials
reader we mentioned before, or tries to restore credentials from session.

The second thing is if the user is authorized to look at the requested page.
To do so `Padrino::Login` calls `#authorized?` helper and checks it's bollean
result. If this helper does not exist then your app is considered not requiring
authorization. If it exists and responds with `true` then `before_filter`
passes. If the helper exists and returns `false` then the user's location
is saved and the user herself is redirected to login url.

`#authorized?` helper should be defined in your app if you want access control.

##### Finally registering

Call `register Padrino::Login` and you are ready to roll.

### Padrino::Access, an authorization module for Padrino

https://github.com/padrino/padrino-framework/wiki/Padrino-authorization-module

### Examples

[EXAMPLES.md](EXAMPLES.md)
