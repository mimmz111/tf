require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'


enable:sessions

before do
  db=SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash=true
  if session[:tag] != "admin" && request.path_info.include?('/admin')
    redirect ('/worodeble')
  end
end


get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username=params[:username]
  password=params[:password]
  db=SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash=true
  result=db.execute("SELECT * FROM users WHERE username=?",username).first
  pwdigest=result["pwdigest"]
  id=result["id"]
  if BCrypt::Password.new(pwdigest)==password
    session[:id]=id
    session[:username] = username
    if username== "admin"
      session[:tag]="admin"
    else
      session[:tag]="user"
    end
    redirect('/worodeble')
  else
    "FEL LÖSEN"
  end
end

get('/worodeble') do
  id=session[:id].to_i
  db=SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash=true
  result=db.execute("SELECT * FROM users WHERE id=?",id)
  slim(:"worodeble/index",locals:{worodeble:result})
end



post('/users') do
  username=params[:username]
  password=params[:password]
  password_confirm=params[:password_confirm]

  if (password==password_confirm)
    password_digest= BCrypt::Password.create(password)
    db=SQLite3::Database.new('db/worodeble.db')
    db.execute("INSERT INTO users (username,pwdigest) VALUES(?,?)",username,password_digest)
    redirect('/')
  else
    "Lösenorden matchade inte"

  end
end


get('/clothing') do
  id=session[:id].to_i
  db=SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash=true
  @worodeble=db.execute("SELECT name, type, color, brand, clothingitem_id FROM clothingitem WHERE user_id=?",id)
slim(:clothing)
end

post ('/clothing/:clothing_id/delete') do
  clothingitem_id = params[:clothing_id].to_i
  db = SQLite3::Database.new('db/worodeble.db')
  db.execute("DELETE FROM clothingitem WHERE clothingitem_id=?", clothingitem_id)
  redirect('/clothing')
end

get('/add') do
slim(:add)
end

post('/add') do
  title = params[:title]
  part = params[:part]
  color = params[:color]
  brand = params[:brand]
  db = SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash = true
  db.execute("INSERT INTO clothingitem (user_id, name, type, color, brand) VALUES (?, ?, ?, ?, ?)", session[:id], title, part, color, brand)
  redirect('/clothing')
end

get ('/search') do
  slim (:search)
end

post ('/search') do
  query = params[:query]
  db = SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash = true
  query_string = "%#{query}%"
  results = db.execute("SELECT * FROM clothingitem WHERE name LIKE ? OR type LIKE ? OR brand LIKE ? OR color LIKE ? OR user_id LIKE ?", query_string, query_string, query_string, query_string, query_string)
  user_id = db.execute("SELECT id FROM users WHERE username = ?", query)
  unless user_id == []
    user_results = db.execute("SELECT * FROM clothingitem WHERE user_id = ?", user_id.first["id"])
    results << user_results
    results = results.first
  end
  unless results == nil
    results.uniq!
  end
  session[:searchresults] = results
  redirect('/search_result')
end

get ('/search_result') do
  @db = SQLite3::Database.new('db/worodeble.db')
  @db.results_as_hash = true
  @results = session[:searchresults]
  slim :search_result
end

get ('/admin') do
  @db = SQLite3::Database.new('db/worodeble.db')
  @db.results_as_hash = true
  @allusers=@db.execute("SELECT * FROM users")
  slim(:admin)
end

post ('/admin/:id/delete') do
  username = params[:id].to_i
  db = SQLite3::Database.new('db/worodeble.db')
  db.execute("DELETE FROM users WHERE id=?", username)
  db.execute("DELETE FROM clothingitem WHERE user_id=?", username)
  redirect('/admin')
end

get ('/global') do
  @db=SQLite3::Database.new('db/worodeble.db')
  @db.results_as_hash=true
  @global=@db.execute("SELECT * FROM clothingitem")
  @like==@db.execute("SELECT * FROM clothing_user_rel_like")
  slim(:global)
end

post('/like/:id') do
  clothingitem_id = params[:id]
  user_id = session[:id]
  db=SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash=true
  db.execute("INSERT INTO clothing_user_rel_like (user_id, clothing_id) VALUES (?,?)",user_id, clothingitem_id)
  redirect('/global')
end




#relationstabbell 
