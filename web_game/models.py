import os
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()


class SaveSlot(db.Model):
    __tablename__ = 'save_slots'
    id = db.Column(db.Integer, primary_key=True)
    slot_number = db.Column(db.Integer, unique=True, nullable=False)
    lord_name = db.Column(db.String(100))
    town_name = db.Column(db.String(100))
    kingdom_id = db.Column(db.Integer)
    deity_id = db.Column(db.Integer)
    seed = db.Column(db.Integer)
    day = db.Column(db.Integer, default=0)
    gold = db.Column(db.Integer, default=100)
    population = db.Column(db.Integer, default=10)
    food = db.Column(db.Integer, default=0)
    wood = db.Column(db.Integer, default=0)
    stone = db.Column(db.Integer, default=0)
    ore = db.Column(db.Integer, default=0)
    gems = db.Column(db.Integer, default=0)
    relics = db.Column(db.Integer, default=0)
    knowledge = db.Column(db.Integer, default=0)
    mana = db.Column(db.Integer, default=0)
    location_name = db.Column(db.String(100))
    dot_x = db.Column(db.Float, default=0.5)
    dot_y = db.Column(db.Float, default=0.5)
    extra_dungeon_chance = db.Column(db.Float, default=0.0)
    game_data = db.Column(db.JSON, default={})
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_empty = db.Column(db.Boolean, default=True)
