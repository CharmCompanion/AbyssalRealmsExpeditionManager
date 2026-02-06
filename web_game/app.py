import os
import json
from flask import Flask, render_template, request, jsonify
from PIL import Image

from sqlalchemy.orm.attributes import flag_modified
from web_game.models import db, SaveSlot
from web_game.game_data import (
    KINGDOM_DATA, KINGDOM_TO_DEITY, DEITY_BONUSES, BUILDING_TYPES,
    KINGDOM_MAP_FILES, STAT_CATEGORIES, ADVENTURER_CLASSES,
    generate_kingdom_resources, generate_stats, generate_starting_adventurers,
)
from web_game.game_logic import DungeonThreatSystem, ExpeditionBoard, AutonomousExpeditions

app = Flask(
    __name__,
    static_folder='static',
    template_folder='templates',
)

app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///game.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

with app.app_context():
    db.create_all()
    existing = SaveSlot.query.count()
    if existing < 20:
        for i in range(1, 21):
            slot = SaveSlot.query.filter_by(slot_number=i).first()
            if not slot:
                slot = SaveSlot(slot_number=i, is_empty=True)
                db.session.add(slot)
        db.session.commit()


@app.after_request
def no_cache(response):
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response


_boundary_cache = {}


def _save_to_dict(s):
    return {
        'id': s.id,
        'slot_number': s.slot_number,
        'lord_name': s.lord_name,
        'town_name': s.town_name,
        'kingdom_id': s.kingdom_id,
        'deity_id': s.deity_id,
        'seed': s.seed,
        'day': s.day,
        'gold': s.gold,
        'population': s.population,
        'food': s.food,
        'wood': s.wood,
        'stone': s.stone,
        'ore': s.ore,
        'gems': s.gems,
        'relics': s.relics,
        'knowledge': s.knowledge,
        'mana': s.mana,
        'location_name': s.location_name,
        'dot_x': s.dot_x,
        'dot_y': s.dot_y,
        'extra_dungeon_chance': s.extra_dungeon_chance,
        'game_data': s.game_data,
        'created_at': s.created_at.isoformat() if s.created_at else None,
        'updated_at': s.updated_at.isoformat() if s.updated_at else None,
        'is_empty': s.is_empty,
    }


@app.route('/')
def index():
    return render_template('index.html')


@app.route('/api/saves', methods=['GET'])
def get_saves():
    slots = SaveSlot.query.order_by(SaveSlot.slot_number).all()
    result = []
    for s in slots:
        if s.is_empty:
            result.append({'slot_number': s.slot_number, 'is_empty': True})
        else:
            result.append(_save_to_dict(s))
    return jsonify(result)


@app.route('/api/saves', methods=['POST'])
def create_save():
    data = request.get_json()
    slot_number = data.get('slot_number', data.get('slot'))
    lord_name = data.get('lord_name')
    town_name = data.get('town_name')
    kingdom_id = data.get('kingdom_id')
    seed = data.get('seed')
    sr = data.get('starting_resources', {})
    gold = sr.get('gold', data.get('gold', 100))
    population = sr.get('population', data.get('population', 10))
    food = sr.get('food', data.get('food', 0))
    wood = sr.get('wood', data.get('wood', 0))
    stone = sr.get('stone', data.get('stone', 0))
    ore = sr.get('ore', data.get('ore', 0))
    location_name = data.get('location_name', '')
    dot_x = data.get('dot_x', data.get('position_x', 0.5))
    dot_y = data.get('dot_y', data.get('position_y', 0.5))
    deity_id = KINGDOM_TO_DEITY.get(kingdom_id, 0)
    kingdom_resources = generate_kingdom_resources(kingdom_id, seed)
    stats = generate_stats(seed)

    dungeon_system = DungeonThreatSystem(base_seed=seed, extra_dungeon_spawn_chance=0.1)
    initial_dungeons = dungeon_system.generate_initial_sites(kingdom_id)

    buildings = {}
    for bname in BUILDING_TYPES:
        buildings[bname] = {'level': 0}

    lord_appearance = data.get('lord_appearance', {})
    game_data = {
        'buildings': buildings,
        'adventurers': generate_starting_adventurers(seed, 4),
        'dungeons': initial_dungeons,
        'expeditions': {},
        'expedition_board': {'jobs': []},
        'kingdom_resources': kingdom_resources,
        'stats': stats,
        'lord_appearance': lord_appearance,
    }

    slot = SaveSlot.query.filter_by(slot_number=slot_number).first()
    if not slot:
        slot = SaveSlot(slot_number=slot_number)
        db.session.add(slot)

    slot.lord_name = lord_name
    slot.town_name = town_name
    slot.kingdom_id = kingdom_id
    slot.deity_id = deity_id
    slot.seed = seed
    slot.day = 0
    slot.gold = gold
    slot.population = population
    slot.food = food
    slot.wood = wood
    slot.stone = stone
    slot.ore = ore
    slot.gems = kingdom_resources.get('gems', 0)
    slot.relics = kingdom_resources.get('relics', 0)
    slot.knowledge = kingdom_resources.get('knowledge', 0)
    slot.mana = kingdom_resources.get('mana', 0)
    slot.location_name = location_name
    slot.dot_x = dot_x
    slot.dot_y = dot_y
    slot.extra_dungeon_chance = 0.1
    slot.game_data = game_data
    slot.is_empty = False

    db.session.commit()
    return jsonify(_save_to_dict(slot))


@app.route('/api/saves/<int:slot>/load', methods=['POST'])
def load_save(slot):
    save = SaveSlot.query.filter_by(slot_number=slot).first()
    if not save or save.is_empty:
        return jsonify({'error': 'Save slot is empty'}), 404

    result = _save_to_dict(save)
    kingdom_info = KINGDOM_DATA.get(save.kingdom_id, {})
    deity_info = DEITY_BONUSES.get(save.deity_id, {})
    result['kingdom_name'] = kingdom_info.get('name', 'Unknown')
    result['deity_name'] = deity_info.get('name', 'Unknown')
    result['deity_desc'] = deity_info.get('desc', '')
    result['deity_passive_text'] = deity_info.get('passive_text', '')
    result['deity_active_text'] = deity_info.get('active_text', '')
    result['deity_bane_text'] = deity_info.get('bane_text', '')
    return jsonify(result)


@app.route('/api/saves/<int:slot>', methods=['DELETE'])
def delete_save(slot):
    save = SaveSlot.query.filter_by(slot_number=slot).first()
    if not save:
        return jsonify({'error': 'Slot not found'}), 404

    save.lord_name = None
    save.town_name = None
    save.kingdom_id = None
    save.deity_id = None
    save.seed = None
    save.day = 0
    save.gold = 100
    save.population = 10
    save.food = 0
    save.wood = 0
    save.stone = 0
    save.ore = 0
    save.gems = 0
    save.relics = 0
    save.knowledge = 0
    save.mana = 0
    save.location_name = None
    save.dot_x = 0.5
    save.dot_y = 0.5
    save.extra_dungeon_chance = 0.0
    save.game_data = {}
    save.is_empty = True

    db.session.commit()
    return jsonify({'slot_number': slot, 'is_empty': True})


@app.route('/api/saves/<int:slot>/copy', methods=['POST'])
def copy_save(slot):
    data = request.get_json()
    target_slot = data.get('target_slot')

    source = SaveSlot.query.filter_by(slot_number=slot).first()
    if not source or source.is_empty:
        return jsonify({'error': 'Source slot is empty'}), 404

    target = SaveSlot.query.filter_by(slot_number=target_slot).first()
    if not target:
        target = SaveSlot(slot_number=target_slot)
        db.session.add(target)

    target.lord_name = source.lord_name
    target.town_name = source.town_name
    target.kingdom_id = source.kingdom_id
    target.deity_id = source.deity_id
    target.seed = source.seed
    target.day = source.day
    target.gold = source.gold
    target.population = source.population
    target.food = source.food
    target.wood = source.wood
    target.stone = source.stone
    target.ore = source.ore
    target.gems = source.gems
    target.relics = source.relics
    target.knowledge = source.knowledge
    target.mana = source.mana
    target.location_name = source.location_name
    target.dot_x = source.dot_x
    target.dot_y = source.dot_y
    target.extra_dungeon_chance = source.extra_dungeon_chance
    target.game_data = json.loads(json.dumps(source.game_data)) if source.game_data else {}
    target.is_empty = False

    db.session.commit()
    return jsonify(_save_to_dict(target))


@app.route('/api/game/tick', methods=['POST'])
def game_tick():
    data = request.get_json()
    slot_number = data.get('slot_number')

    save = SaveSlot.query.filter_by(slot_number=slot_number).first()
    if not save or save.is_empty:
        return jsonify({'error': 'Save slot is empty'}), 404

    save.day = (save.day or 0) + 1
    gd = save.game_data or {}

    dungeons = gd.get('dungeons', [])
    dungeon_system = DungeonThreatSystem(
        base_seed=save.seed or 0,
        extra_dungeon_spawn_chance=save.extra_dungeon_chance or 0.0,
    )
    raids = dungeon_system.on_day(save.day, dungeons)
    gd['dungeons'] = dungeons

    if save.day % 3 == 0:
        board = ExpeditionBoard(base_seed=save.seed or 0)
        town_state = {
            'food': save.food,
            'gold': save.gold,
            'population': save.population,
        }
        jobs = board.generate_board(save.day, dungeons, town_state)
        gd['expedition_board'] = {'jobs': jobs}

    expeditions_data = gd.get('expeditions', {})
    exp_system = AutonomousExpeditions(base_seed=save.seed or 0)
    if expeditions_data.get('active'):
        exp_system.active = expeditions_data['active']
    exp_system.last_depart_day = expeditions_data.get('last_depart_day', -999999)

    jobs = gd.get('expedition_board', {}).get('jobs', [])
    town_state = {
        'food': save.food,
        'gold': save.gold,
        'population': save.population,
    }
    exp_result = exp_system.on_day(save.day, jobs, dungeon_system, town_state)

    if exp_result and exp_result.get('type') == 'report':
        report = exp_result['data']
        loot = report.get('loot', {})
        save.gold = (save.gold or 0) + loot.get('gold', 0)
        save.food = (save.food or 0) + loot.get('food', 0)
        save.wood = (save.wood or 0) + loot.get('wood', 0)
        save.stone = (save.stone or 0) + loot.get('stone', 0)
        save.ore = (save.ore or 0) + loot.get('ore', 0)

    gd['expeditions'] = {
        'active': exp_system.active if exp_system.active else {},
        'last_depart_day': exp_system.last_depart_day,
    }

    buildings = gd.get('buildings', {})
    for bname, bdata in buildings.items():
        level = bdata.get('level', 0)
        if level > 0 and bname in BUILDING_TYPES:
            production = BUILDING_TYPES[bname].get('production', {})
            for res, amount in production.items():
                daily = amount * level
                if res == 'gold':
                    save.gold = (save.gold or 0) + daily
                elif res == 'food':
                    save.food = (save.food or 0) + daily
                elif res == 'wood':
                    save.wood = (save.wood or 0) + daily
                elif res == 'stone':
                    save.stone = (save.stone or 0) + daily
                elif res == 'ore':
                    save.ore = (save.ore or 0) + daily
                elif res == 'knowledge':
                    save.knowledge = (save.knowledge or 0) + daily
                elif res == 'mana':
                    save.mana = (save.mana or 0) + daily

    save.game_data = gd
    flag_modified(save, 'game_data')
    db.session.commit()

    result = _save_to_dict(save)
    result['raids'] = raids
    if exp_result:
        result['expedition_event'] = exp_result
    return jsonify(result)


@app.route('/api/game/build', methods=['POST'])
def build():
    data = request.get_json()
    slot_number = data.get('slot_number')
    building_id = data.get('building_id')

    save = SaveSlot.query.filter_by(slot_number=slot_number).first()
    if not save or save.is_empty:
        return jsonify({'error': 'Save slot is empty'}), 404

    if building_id not in BUILDING_TYPES:
        return jsonify({'error': 'Unknown building'}), 400

    btype = BUILDING_TYPES[building_id]
    gd = save.game_data or {}
    buildings = gd.get('buildings', {})
    current = buildings.get(building_id, {'level': 0})
    current_level = current.get('level', 0)

    if current_level >= btype.get('max_level', 5):
        return jsonify({'error': 'Building already at max level'}), 400

    base_cost = btype.get('base_cost', {})
    cost_mult = current_level + 1
    costs = {}
    for res, amount in base_cost.items():
        costs[res] = amount * cost_mult

    if costs.get('gold', 0) > (save.gold or 0):
        return jsonify({'error': 'Not enough gold'}), 400
    if costs.get('wood', 0) > (save.wood or 0):
        return jsonify({'error': 'Not enough wood'}), 400
    if costs.get('stone', 0) > (save.stone or 0):
        return jsonify({'error': 'Not enough stone'}), 400
    if costs.get('ore', 0) > (save.ore or 0):
        return jsonify({'error': 'Not enough ore'}), 400
    if costs.get('food', 0) > (save.food or 0):
        return jsonify({'error': 'Not enough food'}), 400

    save.gold = (save.gold or 0) - costs.get('gold', 0)
    save.wood = (save.wood or 0) - costs.get('wood', 0)
    save.stone = (save.stone or 0) - costs.get('stone', 0)
    save.ore = (save.ore or 0) - costs.get('ore', 0)
    save.food = (save.food or 0) - costs.get('food', 0)

    current['level'] = current_level + 1
    buildings[building_id] = current
    gd['buildings'] = buildings
    save.game_data = gd
    flag_modified(save, 'game_data')

    db.session.commit()
    return jsonify(_save_to_dict(save))


@app.route('/api/game/expedition/start', methods=['POST'])
def start_expedition():
    data = request.get_json()
    slot_number = data.get('slot_number')
    job_index = data.get('job_index', 0)

    save = SaveSlot.query.filter_by(slot_number=slot_number).first()
    if not save or save.is_empty:
        return jsonify({'error': 'Save slot is empty'}), 404

    gd = save.game_data or {}
    board = gd.get('expedition_board', {})
    jobs = board.get('jobs', [])

    if job_index < 0 or job_index >= len(jobs):
        return jsonify({'error': 'Invalid job index'}), 400

    job = jobs[job_index]
    expeditions = gd.get('expeditions', {})
    expeditions['active'] = {
        'job': job,
        'depart_day': save.day,
        'return_day': (save.day or 0) + job.get('duration_days', 5),
        'party_size': 4,
    }
    gd['expeditions'] = expeditions
    save.game_data = gd
    flag_modified(save, 'game_data')

    db.session.commit()
    return jsonify(_save_to_dict(save))


@app.route('/api/saves/<int:slot>/update_dot', methods=['POST'])
def update_dot(slot):
    data = request.get_json()
    save = SaveSlot.query.filter_by(slot_number=slot).first()
    if not save or save.is_empty:
        return jsonify({'error': 'Save slot is empty'}), 404
    save.dot_x = data.get('dot_x', save.dot_x)
    save.dot_y = data.get('dot_y', save.dot_y)
    db.session.commit()
    return jsonify({'ok': True, 'dot_x': save.dot_x, 'dot_y': save.dot_y})


@app.route('/api/map/boundary/<int:kingdom_id>')
def map_boundary(kingdom_id):
    if kingdom_id in _boundary_cache:
        return jsonify({'valid_positions': _boundary_cache[kingdom_id]})

    map_files = KINGDOM_MAP_FILES.get(kingdom_id)
    if not map_files:
        return jsonify({'error': 'Kingdom not found'}), 404

    highlight_file = map_files.get('highlight', '')
    img_path = os.path.join(app.static_folder, 'images', 'map', highlight_file)

    if not os.path.exists(img_path):
        return jsonify({'error': 'Map file not found'}), 404

    img = Image.open(img_path).convert('RGBA')
    w, h = img.size
    pixels = img.load()

    positions = []
    step = 10
    for y in range(0, h, step):
        for x in range(0, w, step):
            r, g, b, a = pixels[x, y]
            if r / 255.0 > 0.9 and g / 255.0 > 0.9 and b / 255.0 > 0.9 and a > 20:
                positions.append([x / w, y / h])

    _boundary_cache[kingdom_id] = positions
    return jsonify({'valid_positions': positions})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
