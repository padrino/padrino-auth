require File.expand_path('../helper', __FILE__)
require 'padrino-helpers'

describe "Padrino::Access" do
  before do
    mock_app do
      set :credentials_accessor, :visitor
      set :login_model, :character
      register Padrino::Rendering
      enable :sessions
      register Padrino::Login
      get(:index){ 'index' }
      get(:restricted){ 'secret' }
      helpers Padrino::Helpers::AssetTagHelpers
      helpers Padrino::Helpers::OutputHelpers
      helpers Padrino::Helpers::TagHelpers
      helpers Padrino::Helpers::FormHelpers
      helpers do
        def authorized?
          return !['/restricted'].include?(request.env['PATH_INFO']) unless visitor
          case 
          when visitor.id == :bender
            true
          else
            false            
          end
        end
      end
    end
    Character.all.each do |user|
      instance_variable_set :"@#{user.id}", user
    end
  end

  it 'should pass unrestricted area' do
    get '/'
    assert_equal 200, status
  end

  it 'should be redirected from restricted area to login page' do
    get '/restricted'
    assert_equal 302, status
    get response.location
    assert_equal 200, status
    assert_match /<form .*<input .*/, body
  end

  it 'should not be able to authenticate with wrong password' do
    post '/login', :email => :bender, :password => '123'
    assert_equal 200, status
    assert_match 'Wrong password', body
  end

  it 'should be able to authenticate with email and password' do
    post '/login', :email => :bender, :password => 'BBR'
    assert_equal 302, status
  end

  it 'should be redirected back' do
    get '/restricted'
    post response.location, :email => :bender, :password => 'BBR'
    assert_match /\/restricted$/, response.location
  end

  it 'should be redirected to root if no location was saved' do
    post '/login', :email => :bender, :password => 'BBR'
    assert_match /\/$/, response.location
  end

  it 'should be allowed in restricted area after logging in' do
    post '/login', :email => :bender, :password => 'BBR'
    get '/restricted'
    assert_equal 'secret', body
  end

  it 'should not be allowed in restricted area after logging in an account lacking privileges' do
    post '/login', :email => :leela, :password => 'TL'
    get '/restricted'
    assert_equal 403, status
  end
end

describe "Padrino::Login session" do
  before do
    mock_app do
      set :credentials_accessor, :visitor
      set :login_model, :character
      use Rack::Session::Pool
      register Padrino::Login
      get(:index){ session[:visited] = true; 'index' }
      get(:restricted){ 'secret' }
      helpers do
        def authorized?
          !!visitor || request.env['PATH_INFO'] == '/'
        end
      end
    end
  end

  def session_cookie
    last_response.headers['set-cookie'].to_s[/rack\.session=([^;]+)/, 1]
  end

  it 'should renew the session id at login' do
    get '/'
    old_id = session_cookie
    refute_nil old_id

    post '/login', :email => :bender, :password => 'BBR'
    assert response.redirect?
    new_id = session_cookie
    refute_nil new_id
    refute_equal old_id, new_id

    get '/restricted'
    assert_equal 'secret', body

    clear_cookies
    set_cookie "rack.session=#{old_id}"
    get '/restricted'
    assert_equal 302, status
  end
end

describe "Padrino::Login return location" do
  before do
    mock_app do
      set :credentials_accessor, :visitor
      set :login_model, :character
      enable :sessions
      register Padrino::Login
      get(:index){ 'index' }
      get(:restricted){ 'secret' }
      get(:keep){ session[:return_to] = params[:to]; 'kept' }
      helpers do
        def authorized?
          !!visitor || ['/', '/keep'].include?(request.env['PATH_INFO'])
        end
      end
    end
  end

  def log_in_after(path, env = {})
    get path, {}, env
    assert_equal 302, status
    post '/login', :email => :bender, :password => 'BBR'
    response.location
  end

  it 'should return to the requested path with its query string' do
    assert_equal 'http://example.org/restricted?page=2', log_in_after('/restricted?page=2')
  end

  it 'should return to this site after a request with an absolute target' do
    location = log_in_after('/restricted', 'REQUEST_URI' => 'http://other.host/restricted')
    assert_equal 'http://example.org/restricted', location
  end

  it 'should return to the root for a path starting with two slashes' do
    @app.disable :absolute_redirects
    location = log_in_after('/restricted', 'PATH_INFO' => '//other.host/restricted', 'REQUEST_URI' => '//other.host/restricted')
    assert_equal '/', location
  end

  it 'should return to the root for a path starting with a slash and a backslash' do
    @app.disable :absolute_redirects
    location = log_in_after('/restricted', 'PATH_INFO' => '/\\other.host/restricted', 'REQUEST_URI' => '/\\other.host/restricted')
    assert_equal '/', location
  end

  it 'should only return to a stored location on this site' do
    @app.disable :absolute_redirects
    ['http://other.host/x', '//other.host/x', '/\\other.host/x'].each do |stored|
      get '/keep', :to => stored
      assert_equal 'kept', body
      post '/login', :email => :bender, :password => 'BBR'
      assert_equal '/', response.location, stored
    end
    get '/keep', :to => '/restricted?page=2'
    post '/login', :email => :bender, :password => 'BBR'
    assert_equal '/restricted?page=2', response.location
  end

  it 'should return to the full path of an app mounted under a sub-path' do
    @app.set :uri_root, '/sub'
    mounted = Rack::URLMap.new('/sub' => @app)
    define_singleton_method(:app) { Rack::Lint.new(mounted) }
    get '/sub/restricted?page=2', {}, 'REQUEST_URI' => '/sub/restricted?page=2'
    assert_equal 302, status
    assert_equal 'http://example.org/sub/login', response.location
    post '/sub/login', :email => :bender, :password => 'BBR'
    assert_equal 'http://example.org/sub/restricted?page=2', response.location
  end
end
