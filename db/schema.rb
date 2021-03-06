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

ActiveRecord::Schema.define(version: 20170410133509) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_players", force: :cascade do |t|
    t.integer "player_id"
    t.integer "game_id"
    t.float   "xp_gained"
    t.float   "elo_delta"
    t.index ["game_id"], name: "index_game_players_on_game_id", using: :btree
    t.index ["player_id"], name: "index_game_players_on_player_id", using: :btree
  end

  create_table "games", force: :cascade do |t|
    t.datetime "resolution_time"
    t.integer  "player_id"
    t.integer  "mission_id"
    t.integer  "draw"
    t.index ["draw"], name: "index_games_on_draw", using: :btree
    t.index ["mission_id"], name: "index_games_on_mission_id", using: :btree
    t.index ["player_id"], name: "index_games_on_player_id", using: :btree
    t.index ["resolution_time"], name: "index_games_on_resolution_time", using: :btree
  end

  create_table "missions", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "name", limit: 18
  end

  add_foreign_key "game_players", "games"
  add_foreign_key "games", "missions"
end
