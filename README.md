**Gladiabots Stats**

A ruby on rails application that can parse Gladiabots player and game dump files and generate graphs

Application code is in app/

**Install Instructions**

1. Clone repo
2. Install ruby 2.4 or 2.3
3. CD into repo folder
4. Install bundler gem:
```
gem install bundler
```
5. Install gems for application. Run in repo folder:
```
bundle install
```
6. Migrate the sqlite3 database:
```
rake db:migrate
```
7. Run the development server:
```
rails s
```
