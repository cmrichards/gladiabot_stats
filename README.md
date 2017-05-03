<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">A <a href="https://twitter.com/Gladiabots">@Gladiabots</a> player just made a 100 times awesomer stats page than mine XD<a href="https://t.co/dZVlp88eAv">https://t.co/dZVlp88eAv</a><a href="https://twitter.com/hashtag/GameDev?src=hash">#GameDev</a> <a href="https://twitter.com/hashtag/IndieGame?src=hash">#IndieGame</a> <a href="https://t.co/DUTOUWjWZ4">pic.twitter.com/DUTOUWjWZ4</a></p>&mdash; Sébastien Dubois (@GFX47) <a href="https://twitter.com/GFX47/status/852571204850503680">April 13, 2017</a></blockquote>




**Gladiabots Stats**

A ruby on rails application that can parse Gladiabots player/game dump files and scrape the official stats site for realtime data in order to generate pretty graphs.

It runs here: http://gladiabots-stats.info.tm

You can add this to your forum signature to link directly to your stats:

http://gladiabots-stats.info.tm/mrchris

or this to view your stats against an opponent:

http://gladiabots-stats.info.tm/mrchris/vs/linusoccolt


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

Screenshots: 

![mobile_friendly](https://cloud.githubusercontent.com/assets/808/25611303/8dab50ae-2f1e-11e7-99ba-f65728c91bb1.png)
![global_stats](https://cloud.githubusercontent.com/assets/808/25611304/8dadd0cc-2f1e-11e7-89ee-c5baf74e5339.png)
![player_stats](https://cloud.githubusercontent.com/assets/808/25611305/8dc52ac4-2f1e-11e7-95c4-915032851217.png)
