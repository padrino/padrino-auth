require File.expand_path('../helper', __FILE__)

describe "Padrino::Access" do
  before do
    mock_app do
      set :credentials_reader, :visitor
      register Padrino::Access
      set_access :*, :allow => :login
      set :users, Character.all
      get(:login, :with => :id) do
        user = settings.users.find{ |user| user.id.to_s == params[:id] }
        self.send(:"#{settings.credentials_reader}=", user)
      end
      get(:index){ 'foo' }
      get(:bend){ 'bend' }
      get(:drink){ 'bend' }
      get(:subject){ self.send(settings.credentials_reader).inspect }
      get(:stop_partying){ 'stop partying' }
      controller :surface do
        get(:live) { 'live on the surface' }
      end
      controller :sewers do
        get(:live) { 'live in the sewers' }
        get(:visit) { 'visit the sewers' }
      end
      set :fake_session, {}
      helpers do
        def visitor
          settings.fake_session[:visitor]
        end
        def visitor=(user)
          settings.fake_session[:visitor] = user
        end
      end
    end
    Character.all.each do |user|
      instance_variable_set :"@#{user.id}", user
    end
  end

  it 'should register with authorization module' do
    assert @app.respond_to? :set_access
    assert_kind_of Padrino::Permissions, @app.permissions
  end

  it 'should properly detect access subject' do
    set_access :*
    get '/login/ami'
    get '/subject'
    assert_equal @ami.inspect, body
  end

  it 'should reset access properly' do
    set_access :*
    allow
    @app.reset_access!
    deny
  end

  it 'should set group access' do
    # only humans should be allowed on TV
    set_access :humans
    allow @fry
    deny @bender
  end

  it 'should set individual access' do
    # only Fry should be allowed to romance Leela
    set_access @fry
    allow @fry
    deny @ami
  end

  it 'should set mixed individual and group access' do
    # only humans and Leela should be allowed on the surface
    set_access :humans
    set_access @leela
    allow @fry
    allow @leela
  end

  it 'should set action-specific access' do
    # bender should be allowed to bend, and he's denied to stop partying
    set_access @bender, :allow => :bend
    set_access @fry, :allow => :stop_partying
    allow @bender, '/bend'
    deny @bender, '/stop_partying'
    allow @fry, '/stop_partying'
    deny @fry, '/bend'
  end

  it 'should set multiple action' do
    # bender should be allowed to bend and drink
    set_access @bender, :allow => [:drink, :bend]
    allow @bender, '/drink'
    allow @bender, '/bend'
  end

  it 'should set object-specific access' do
    # only humans and Leela should be allowed to live on the surface
    # only mutants should be allowed to live in the sewers though humans can visit
    set_access :humans, :allow => :live, :with => :surface
    set_access :mutants, :allow => :live, :with => :sewers
    set_access @leela, :allow => :live, :with => :surface
    set_access :humans, :allow => :visit, :with => :sewers
    allow @fry, '/surface/live'
    deny @fry, '/sewers/live'
    allow @fry, '/sewers/visit'
    allow @leela, '/surface/live'
    allow @leela, '/sewers/live'
  end

  it 'should detect object when setting access from controller' do
    # only humans and lobsters should have binocular vision
    @app.controller :binocular do
      set_access :humans, :lobsters
      get(:vision) { 'binocular vision' }
    end
    deny @fry, '/'
    allow @fry, '/binocular/vision'
    allow @zoidberg, '/binocular/vision'
    deny @leela, '/binocular/vision'
  end

  it 'should check access to an object with access_object?' do
    # only robots should be allowed to bend girders
    set_access :*, :allow => :girders
    set_access :robots, :allow => :bend, :with => :girders
    @app.get(:girders) { access_object?(:girders, :bend).inspect }
    allow @bender, '/girders'
    assert_equal 'true', body
    allow @fry, '/girders'
    assert_equal 'false', body
  end
end

describe "Padrino::Permissions" do
  Member = Struct.new(:id, :role)
  Visitor = Struct.new(:id, :role)

  before do
    @permissions = Padrino::Permissions.new
    @permissions.add :admins, :allow => :manage, :with => :users
    @permissions.add :members, :allow => :read, :with => :posts
  end

  it 'should re-check role permissions when the role changes' do
    subject = Member.new(1, :admins)
    assert @permissions.check(subject, :allow => :manage, :with => :users)
    subject.role = :members
    refute @permissions.check(subject, :allow => :manage, :with => :users)
    assert @permissions.check(subject, :allow => :read, :with => :posts)
  end

  it 'should re-check role permissions when the role changes after more permits are added' do
    subject = Member.new(1, :admins)
    @permissions.add subject, :allow => :write, :with => :posts
    assert @permissions.check(subject, :allow => :manage, :with => :users)
    @permissions.add :guests, :allow => :read, :with => :news
    subject.role = :members
    refute @permissions.check(subject, :allow => :manage, :with => :users)
    assert @permissions.check(subject, :allow => :write, :with => :posts)
  end

  it 'should check subjects of different classes with the same id by their own role' do
    assert @permissions.check(Member.new(1, :admins), :allow => :manage, :with => :users)
    refute @permissions.check(Visitor.new(1, :members), :allow => :manage, :with => :users)
  end

  it 'should check a subject without a role by its own and public permits' do
    subject = Member.new(2, nil)
    @permissions.add subject, :allow => :write, :with => :posts
    @permissions.add :*, :allow => :read, :with => :news
    assert @permissions.check(subject, :allow => :write, :with => :posts)
    assert @permissions.check(subject, :allow => :read, :with => :news)
    refute @permissions.check(subject, :allow => :manage, :with => :users)
  end
end
