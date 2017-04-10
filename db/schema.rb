# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170401233303) do

  create_table "game_players", force: :cascade do |t|
    t.integer  "player_id"
    t.integer  "game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_players_on_game_id"
    t.index ["player_id"], name: "index_game_players_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "resolutionTime"
    t.integer  "player_id"
    t.integer  "mission_id"
    t.integer  "eloDelta"
    t.integer  "xpGained"
    t.integer  "draw"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["mission_id"], name: "index_games_on_mission_id"
    t.index ["player_id"], name: "index_games_on_player_id"
  end

  create_table "missions", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string   "name"
    t.integer  "elo"
    t.integer  "xp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
