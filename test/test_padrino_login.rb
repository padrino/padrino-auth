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
