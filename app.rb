require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'


enable:sessions



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
    p session[:id]
    redirect('/worodeble')
  else
    "FEL LÖSEN"
  end
end

get('/worodeble') do
  id=session[:id].to_i

  p session[:id]
  db=SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash=true
  result=db.execute("SELECT * FROM users WHERE id=?",id)
  p result

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

slim(:clothing)
end

get('/add') do
  title = params[:title]
  part = params[:part]
  color = params[:color]
  brand = params[:brand]
  
  db = SQLite3::Database.new('db/worodeble.db')
  db.results_as_hash = true
  db.execute("INSERT INTO clothingitem (user_id, name, type, color, brand) VALUES (?, ?, ?, ?, ?)", session[:id], title, part, color, brand)
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