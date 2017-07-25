require 'sinatra'
require 'sinatra/reloader'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def full_data_path
  if ENV['RACK-ENV'] == "test"
    File.expand_path("../test/data",__FILE__)
  else
    File.expand_path("../data",__FILE__)
  end
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file)
end

def load_file(file_path)
  file = File.read(file_path)

  if File.extname(file_path) == '.txt'
    headers['Content-Type'] = "text/plain"
    file
  elsif File.extname(file_path) == '.md'
    erb render_markdown(file)
  end
end

def create_file(file_name)
  file_path = File.join(full_data_path, file_name)
  File.write(file_path, "w")
end

def signed_in?
  session[:username]
end

def require_sign_in
  if !signed_in?
    session[:message] = "You need to sign in to do that."
    redirect "/"
  end
end

get "/" do
  @files = Dir.glob(full_data_path + "/*").map {|path| File.basename(path)}
  headers["Content-Type"] = "text/html;charset=utf-8"
  erb :index
end

get "/files/:file_name" do
  file_name = params[:file_name]
  file_path = full_data_path + "/" + file_name
  if File.exist?(file_path)
    load_file(file_path)
  else
    session[:message] = "The file #{file_name} does not exist."
    redirect "/"
  end
end

get "/new" do
  require_sign_in

  erb :new
end

post "/new" do
  require_sign_in

  file_name = params[:file_name]
  if file_name != ""
    create_file(file_name)
    session[:message] = "#{file_name} has been created."
    redirect "/"
  else
    status 422
    session[:message] = "File name cannot be empty."
    erb :new
  end
end

get "/files/:file_name/edit" do
  require_sign_in

  @file_name = params[:file_name]
  file_path = File.join(full_data_path, @file_name)
  @content = File.read(file_path)
  erb :edit
end

post "/files/:file_name/edit" do
  require_sign_in

  file_name = params[:file_name]
  content = params[:content]
  file_path = File.join(full_data_path, file_name)
  
  File.write(file_path, content)

  session[:message] = "#{file_name} has been udpated."
  redirect "/"
end

post "/files/:file_name/delete" do
  require_sign_in

  file_name = params[:file_name]
  file_path = File.join(full_data_path, file_name)

  File.delete(file_path)
  session[:message] = "#{file_name} has been deleted."
  redirect "/"
end

get "/signin" do
  erb :signin
end

post "/signin" do
  username = params[:username]
  password = params[:password]
  if username == "admin" && password == "1234"
    session[:message] = "You are signed in."
    session[:username] = username
    redirect "/"
  else
    session[:message] = "Please enter valid credentials."
    status 422
    erb :signin
  end
end

post "/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end
