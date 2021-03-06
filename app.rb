require "sinatra"
require 'koala'
require 'coffee-script'

enable :sessions
set :raise_errors, false
set :show_exceptions, false

require 'data_mapper'

DataMapper.setup(:default, ENV['HEROKU_SHARED_POSTGRESQL_COBALT_URL'] || 'postgres://localhost/my_database')

class Drawing
  include DataMapper::Resource
  property :id,         Serial
  property :user_id,    String
  property :noun,       String
  property :uri,        Text
  property :created_at, DateTime

  has n, :votes
end

class Vote
  include DataMapper::Resource
  property :id,         Serial
  property :user_id,    String
  property :drawing_id, Integer
  property :created_at, DateTime

  belongs_to :drawing
end

DataMapper.auto_upgrade!

# Scope defines what permissions that we are asking the user to grant.
# In this example, we are asking for the ability to publish stories
# about using the app, access to what the user likes, and to be able
# to use their pictures.  You should rewrite this scope with whatever
# permissions your app needs.
# See https://developers.facebook.com/docs/reference/api/permissions/
# for a full list of permissions
FACEBOOK_SCOPE = 'user_likes,user_photos,user_photo_video_tags'

unless ENV["FACEBOOK_APP_ID"] && ENV["FACEBOOK_SECRET"]
  abort("missing env vars: please set FACEBOOK_APP_ID and FACEBOOK_SECRET with your app credentials")
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
end

helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end

  def authenticator
    @authenticator ||= Koala::Facebook::OAuth.new(ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_SECRET"], url("/auth/facebook/callback"))
  end

  def nouns
    %w(ball rabbit house condiment wish)
  end

  def max_friends_using_app_qty
    4
  end
end

# the facebook session expired! reset ours and restart the process
error(Koala::Facebook::APIError) do
  session[:access_token] = nil
  redirect "/auth/facebook"
end

get "/" do
  # Get base API Connection
  @graph  = Koala::Facebook::API.new(session[:access_token])

  # Get public details of current application
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])

  if session[:access_token]
    @user    = @graph.get_object("me")
    @friends = @graph.get_connections('me', 'friends')
    @photos  = @graph.get_connections('me', 'photos')
    @likes   = @graph.get_connections('me', 'likes').first(4)

    # for other data you can always run fql
    @friends_using_app = @graph.fql_query("SELECT uid, name, is_app_user, pic_square
                                           FROM user WHERE uid in
                                           (SELECT uid2 FROM friend WHERE uid1 = me())
                                           AND is_app_user = 1")

    @max_friends_using_app_qty = max_friends_using_app_qty
  end
  erb :index
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

# used to close the browser window opened to post to wall/send to friends
get "/close" do
  "<body onload='window.close();'/>"
end

get "/sign_out" do
  session[:access_token] = nil
  redirect '/'
end

get "/auth/facebook" do
  session[:access_token] = nil
  redirect authenticator.url_for_oauth_code(:permissions => FACEBOOK_SCOPE)
end

get '/auth/facebook/callback' do
	session[:access_token] = authenticator.get_access_token(params[:code])
	redirect '/'
end

get '/draw' do
  # Get base API Connection
  @graph  = Koala::Facebook::API.new(session[:access_token])

  # Get public details of current application
  @app  =  @graph.get_object(ENV["FACEBOOK_APP_ID"])

  if session[:access_token]
    @user    = @graph.get_object("me")
    @friends = @graph.get_connections('me', 'friends')
    @photos  = @graph.get_connections('me', 'photos')
    @likes   = @graph.get_connections('me', 'likes').first(4)

    # for other data you can always run fql
    @friends_using_app = @graph.fql_query("SELECT uid, name, is_app_user, pic_square
                                           FROM user WHERE uid in
                                           (SELECT uid2 FROM friend WHERE uid1 = me())
                                           AND is_app_user = 1")

    @max_friends_using_app_qty = max_friends_using_app_qty

    @noun = nouns.sample
  end
  erb :draw
end

get '/vote' do
  erb :vote
end
