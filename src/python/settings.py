import os 

natural = {"natural": [
    "fell",
    "grassland",
    "heath",
    "moor",
    "scrub",
    "shrubbery",
    "tree",
    "tree_row"
    "tree_stump",
    "tundra",
    "wood"
    ]
}

semi_natural = {"landuse": [
    "farmland",
    "farmyard",
    "paddy",
    "animal_keeping",
    "flowerbed","forest",
    "meadow",
    "orchard",
    "grass",
    "meadow"
    ]
}

green = {"leisure": [
    "garden",
    "golf_course",
    "nature_reserve",
    "park"
    ]
}

urban = {"landuse": [
    "commercial", 
    "construction",
    "education",
    "fairground",
    "industrial",
    "residential",
    "retail",
    "institutional",
    "railway",
    "aerodrome",
    "landfill",
    "port",
    "depot",
    "quarry",
    "military"
    ]
}

amenity = {"amenity": True}

building = {"building": True}

tourism = {"tourism": True}

highway = {"highway": True}

amusement = {"leisure": [
    "adult_gaming_centre",
    "amusement_arcade",
    "bandstand",
    "beach_resort",
    "bleachers",
    "bowling_alley",
    "common",
    "dance",
    "disc_golf_course",
    "fitness_centre",
    "fitness_station",
    "hackerspace",
    "ice_rink",
    "marina",
    "miniature_golf",
    "outdoor_seating",
    "playground",
    "resort",
    "sauna",
    "slipway",
    "sports_centre",
    "sport_hall",
    "stadium",
    "summer_camp",
    "swimming_pool",
    "tanning_salon",
    "track",
    "trampoline_park",
    "water_park"
    ]
}

aeroway = {"aeroway": [
    "aerodrome",
    "apron",
    "gate",
    "hangar",
    "helipad",
    "heliport",
    "runway",
    "taxiway",
    "terminal",
    "windsock"
    ]
}

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../"))
PATH = f'{PROJECT_ROOT}/data'
