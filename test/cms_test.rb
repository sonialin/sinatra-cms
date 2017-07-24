ENV["RACK-ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(full_data_path)
  end

  def teardown
    FileUtils.rm_rf(full_data_path)
  end

  def create_document(name, content="")
    File.open(File.join(full_data_path, name), "w") do |f|
      f.write(content)
    end
  end

  def test_index
    create_document "history.txt"
    create_document "about.md"
    
    get "/"
    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response["Content-Type"]
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "about.md"
  end

  def test_viewing_doc
    create_document "history.txt", "2003 - "

    get "/files/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_equal last_response.body, "2003 - "
  end

  def test_create
    post "/new", file_name: "testfile.txt"
    assert_equal 302, last_response.status
    get last_response['location']
    
    assert_includes last_response.body, "The file testfile.txt has been created."
    get "/"
    assert_includes last_response.body, "testfile.txt"
  end

  def test_create_no_name
    post "/new", file_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "The file name cannot be empty"
  end

  def test_view_markdown
    create_document "about.md", "# Ruby is ..."

    get "/files/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is ...</h1>"
  end

  def test_edit_doc
    create_document "about.md"

    get "/files/about.md/edit"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "</textarea>"
  end

  def test_update_doc
    create_document "history.txt"
    get "/files/history.txt"
    assert_equal last_response.body, ""

    post "/files/history.txt/edit", content: "here's some content"
    assert_equal 302, last_response.status
    get last_response['location']
    assert_includes last_response.body, "history.txt has been udpated."

    get "/files/history.txt"
    assert_equal 200, last_response.status
    assert_equal last_response.body, "here's some content"
  end

  def test_file_not_found
    get "/files/nothere.txt"

    get last_response['location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, "The file nothere.txt does not exist."
  end

  def test_delete
    create_document "testfile.txt"

    post "/files/testfile.txt/delete"
    assert_equal 302, last_response.status
    get last_response['location']
    assert_includes last_response.body, "testfile.txt has been deleted."
  end

  def test_sign_in
    get "/signin"
    assert_includes last_response.body, "username"
    assert_includes last_response.body, "password"
    assert_includes last_response.body, '<button type="submit">'

    post "/signin", username: "admin", password: "1234"
    assert_equal 302, last_response.status
    get last_response['location']
    assert_includes last_response.body, "You are signed in."
    assert_includes last_response.body, "Sign out"
  end

  def test_sign_out
    post "/signin", username: "admin", password: "1234"
    get last_response['location']
    assert_includes last_response.body, "You are signed in."

    post "/signout"
    get last_response['location']
    assert_includes last_response.body, "You have been signed out."
    assert_includes last_response.body, "Sign in"
  end

  def test_signin_invalid_credentials
    post "/signin", username: "invalid", password: "invalid"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Please enter valid credentials."
  end
end