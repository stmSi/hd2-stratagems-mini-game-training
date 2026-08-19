extends Node

enum ARROW {DOWN, LEFT, UP, RIGHT}

const PRACTICE_CONFIG_PATH = "user://practice_config.cfg"
const CUSTOM_STRATAGEMS_PATH = "user://custom_stratagems.json"
const CUSTOM_ICON_DIRECTORY = "user://custom_stratagem_icons"
const CUSTOM_ICON_MAX_BYTES = 3 * 1024 * 1024
const CUSTOM_ICON_MAX_DIMENSION = 2048
const CUSTOM_ICON_DISPLAY_SIZE = 512
const MAIN_SCENE_PATH = "res://Src/main.tscn"
const TRAIN_SCENE_PATH = "res://Src/train.tscn"
const GITHUB_REPO_URL = "https://github.com/stmSi/hd2-stratagems-mini-game-training"
const GITHUB_RELEASES_URL = "https://github.com/stmSi/hd2-stratagems-mini-game-training/releases"
const DEFAULT_AUDIO_VOLUME = 0.7
const DEFAULT_SHOW_STRATAGEM_ARROWS = true
const DEFAULT_REQUIRE_HOLD = false
const DEFAULT_TOUCH_CONTROL_SCALE = 1.5
const MIN_TOUCH_CONTROL_SCALE = 0.8
const MAX_TOUCH_CONTROL_SCALE = 1.8
const MOBILE_PORTRAIT_VIEWPORT := Vector2i(390, 900)
const MOBILE_LANDSCAPE_VIEWPORT := Vector2i(900, 390)
const DEFAULT_CONTROLLER_HOLD_BUTTON := JOY_BUTTON_LEFT_SHOULDER
const DEFAULT_HOLD_BINDING = {
	"type": "mouse_button",
	"button_index": MOUSE_BUTTON_MIDDLE,
}
const DEFAULT_CONTROLLER_HOLD_BINDING = {
	"type": "joy_button",
	"button_index": DEFAULT_CONTROLLER_HOLD_BUTTON,
}
const DEFAULT_DIRECTION_BINDINGS = {
	"up_primary": {"type": "key", "keycode": KEY_W},
	"left_primary": {"type": "key", "keycode": KEY_A},
	"down_primary": {"type": "key", "keycode": KEY_S},
	"right_primary": {"type": "key", "keycode": KEY_D},
	"up_secondary": {"type": "key", "keycode": KEY_UP},
	"left_secondary": {"type": "key", "keycode": KEY_LEFT},
	"down_secondary": {"type": "key", "keycode": KEY_DOWN},
	"right_secondary": {"type": "key", "keycode": KEY_RIGHT},
}
const DEFAULT_CONTROLLER_DIRECTION_BINDINGS = {
	"up": {"type": "joy_button", "button_index": JOY_BUTTON_DPAD_UP},
	"left": {"type": "joy_button", "button_index": JOY_BUTTON_DPAD_LEFT},
	"down": {"type": "joy_button", "button_index": JOY_BUTTON_DPAD_DOWN},
	"right": {"type": "joy_button", "button_index": JOY_BUTTON_DPAD_RIGHT},
}
const DIRECTION_BINDING_SLOT_ORDER = [
	"up_primary",
	"up_secondary",
	"left_primary",
	"left_secondary",
	"down_primary",
	"down_secondary",
	"right_primary",
	"right_secondary",
]
const DIRECTION_BINDING_ARROW_MAP = {
	"up_primary": ARROW.UP,
	"up_secondary": ARROW.UP,
	"left_primary": ARROW.LEFT,
	"left_secondary": ARROW.LEFT,
	"down_primary": ARROW.DOWN,
	"down_secondary": ARROW.DOWN,
	"right_primary": ARROW.RIGHT,
	"right_secondary": ARROW.RIGHT,
}
const DEFAULT_CONTROLLER_DIRECTION_BUTTONS = {
	JOY_BUTTON_DPAD_UP: ARROW.UP,
	JOY_BUTTON_DPAD_LEFT: ARROW.LEFT,
	JOY_BUTTON_DPAD_DOWN: ARROW.DOWN,
	JOY_BUTTON_DPAD_RIGHT: ARROW.RIGHT,
}
const CONTROLLER_DIRECTION_BINDING_SLOT_ORDER = ["up", "left", "down", "right"]
const CONTROLLER_DIRECTION_BINDING_ARROW_MAP = {
	"up": ARROW.UP,
	"left": ARROW.LEFT,
	"down": ARROW.DOWN,
	"right": ARROW.RIGHT,
}
const KEYBOARD_TO_CONTROLLER_DIRECTION_SLOT_MAP = {
	"up_primary": "up",
	"up_secondary": "up",
	"left_primary": "left",
	"left_secondary": "left",
	"down_primary": "down",
	"down_secondary": "down",
	"right_primary": "right",
	"right_secondary": "right",
}
const PRIMARY_DIRECTION_BINDING_SLOTS = ["up_primary", "left_primary", "down_primary", "right_primary"]
const SECONDARY_DIRECTION_BINDING_SLOTS = ["up_secondary", "left_secondary", "down_secondary", "right_secondary"]
const MOUSE_BUTTON_LABELS = {
	MOUSE_BUTTON_LEFT: "Left Mouse",
	MOUSE_BUTTON_RIGHT: "Right Mouse",
	MOUSE_BUTTON_MIDDLE: "Middle Mouse",
	MOUSE_BUTTON_XBUTTON1: "Mouse 4",
	MOUSE_BUTTON_XBUTTON2: "Mouse 5",
}
const JOYPAD_BUTTON_LABELS = {
	JOY_BUTTON_A: "Cross / A",
	JOY_BUTTON_B: "Circle / B",
	JOY_BUTTON_X: "Square / X",
	JOY_BUTTON_Y: "Triangle / Y",
	JOY_BUTTON_BACK: "Share / View",
	JOY_BUTTON_GUIDE: "PS / Xbox",
	JOY_BUTTON_START: "Options / Menu",
	JOY_BUTTON_LEFT_STICK: "L3 / LS",
	JOY_BUTTON_RIGHT_STICK: "R3 / RS",
	JOY_BUTTON_LEFT_SHOULDER: "L1 / LB",
	JOY_BUTTON_RIGHT_SHOULDER: "R1 / RB",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}


func _ready() -> void:
	if not is_touch_device():
		return
	get_tree().root.size_changed.connect(_apply_mobile_content_scale)
	call_deferred("_apply_mobile_content_scale")


func _apply_mobile_content_scale() -> void:
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return
	var target_size := MOBILE_LANDSCAPE_VIEWPORT if window_size.x > window_size.y else MOBILE_PORTRAIT_VIEWPORT
	if get_tree().root.content_scale_size != target_size:
		get_tree().root.content_scale_size = target_size


static func is_touch_device() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval(
			"navigator.maxTouchPoints > 0 || 'ontouchstart' in window",
			true
		))
	return false

const STRATAGEM_CATEGORY_ORDER = ["priority", "orbital", "eagle", "support", "defensive", "mission"]
const STRATAGEM_CATEGORY_LABELS = {
	"priority": "Important",
	"orbital": "Orbital",
	"eagle": "Eagle",
	"support": "Support",
	"defensive": "Defensive",
	"mission": "Mission",
}
const STRATAGEM_CATEGORY_COLORS = {
	"priority": Color("ffe27a"),
	"orbital": Color("ff6f61"),
	"eagle": Color("ff8f3d"),
	"support": Color("7cb7ff"),
	"defensive": Color("7ecb6b"),
	"mission": Color("f0cf5a"),
}
const STRATAGEM_CATEGORY_OVERRIDES = {
	"ANTI_PERSONNEL_MINEFIELD": "defensive",
	"ANTI_TANK_EMPLACEMENT": "defensive",
	"ANTI_TANK_MINES": "defensive",
	"AUTOCANNON_SENTRY": "defensive",
	"BASTION_MK_XVI": "support",
	"EMS_MORTAR_SENTRY": "defensive",
	"FLAME_SENTRY": "defensive",
	"GAS_MINES": "defensive",
	"GAS_MORTAR_SENTRY": "defensive",
	"GATLING_SENTRY": "defensive",
	"GRENADIER_BATTLEMENT": "defensive",
	"HMG_EMPLACEMENT": "defensive",
	"INCENDIARY_MINES": "defensive",
	"LASER_SENTRY": "defensive",
	"MACHINE_GUN_SENTRY": "defensive",
	"MORTAR_SENTRY": "defensive",
	"ORBITAL_ILLUMINATION_FLARE": "mission",
	"ROCKET_SENTRY": "defensive",
	"SHIELD_GENERATOR_RELAY": "defensive",
	"TESLA_TOWER": "defensive",
	"CALL_IN_SUPER_DESTROYER": "mission",
	"CARGO_CONTAINER": "mission",
	"DARK_FLUID_VESSEL": "mission",
	"EAGLE_REARM": "mission",
	"HELLBOMB": "mission",
	"ONE_TRUE_FLAG": "support",
	"PORTABLE_HELLBOMB": "support",
	"PROSPECTING_DRILL": "mission",
	"REINFORCE": "priority",
	"RESUPPLY": "priority",
	"SEAF_ARTILLERY": "mission",
	"SEISMIC_PROBE": "mission",
	"SOLO_SILO": "support",
	"SOS_BEACON": "mission",
	"START_UPLOAD": "mission",
	"SUPER_EARTH_FLAG": "mission",
}

const AIRBURST_ROCKET_LAUNCHER_STRATAGEM_ICON = preload("uid://dscxckl43wyd5")
const ANTI_MATERIEL_RIFLE_STRATAGEM_ICON = preload("uid://3lygcnofir1j")
const ANTI_PERSONNEL_MINEFIELD_STRATAGEM_ICON = preload("uid://df5tmvekjyarr")
const ANTI_TANK_EMPLACEMENT_STRATAGEM_ICON = preload("uid://difqu18cy5yd")
const ANTI_TANK_MINES_STRATAGEM_ICON = preload("uid://duuytr52mar62")
const ARC_THROWER_STRATAGEM_ICON = preload("uid://cf5w5ojpdrk31")
const AUTOCANNON_SENTRY_STRATAGEM_ICON = preload("uid://dg1pmwfpwxg8d")
const AUTOCANNON_STRATAGEM_ICON = preload("uid://qvkhstjh5env")
const BALLISTIC_SHIELD_BACKPACK_STRATAGEM_ICON = preload("uid://bj6lvk3d7wty5")
const BASTION_MK_XVI_STRATAGEM_ICON = preload("uid://b51hhl2hic75g")
const BELT_FED_GRENADE_LAUNCHER_STRATAGEM_ICON = preload("uid://cnf0ea8ddv7al")
const BREACHING_HAMMER_STRATAGEM_ICON = preload("uid://c5g63ke74eocn")
const BREAKTHROUGH_EXOSUIT_STRATAGEM_ICON = preload("res://Assets/icons/Breakthrough Exosuit Stratagem Icon.svg")
const BULLET_STORM_STRATAGEM_ICON = preload("res://Assets/icons/Bullet Storm Stratagem Icon.svg")
const C_4_PACK_STRATAGEM_ICON = preload("uid://4lktsbtfl605")
const CALL_IN_SUPER_DESTROYER_STRATAGEM_ICON = preload("uid://dosb6u0yti4ki")
const CARGO_CONTAINER_STRATAGEM_ICON = preload("uid://htjle5c7cmp8")
const COMMANDO_STRATAGEM_ICON = preload("uid://lirw4mei1oux")
const CREMATOR_STRATAGEM_ICON = preload("uid://d3ouwlv0h6w5w")
const DARK_FLUID_VESSEL_STRATAGEM_ICON = preload("uid://clr4mvgd70lj")
const DE_ESCALATOR_STRATAGEM_ICON = preload("uid://bed4eygrm3qyd")
const DEFOLIATION_TOOL_STRATAGEM_ICON = preload("uid://sgfh8uyrc65e")
const DIRECTIONAL_SHIELD_STRATAGEM_ICON = preload("uid://im0m4eexv52n")
const DOG_BREATH_STRATAGEM_ICON = preload("uid://chaedbd1ktg0e")
const EAGLE_110_MM_ROCKET_PODS_STRATAGEM_ICON = preload("uid://vvv5i8xgvjkg")
const EAGLE_500_KG_BOMB_STRATAGEM_ICON = preload("uid://rkg8rusipbf3")
const EAGLE_AIRSTRIKE_STRATAGEM_ICON = preload("uid://p6o4ur1w6kt2")
const EAGLE_CLUSTER_BOMB_STRATAGEM_ICON = preload("uid://r257rli2nfua")
const EAGLE_NAPALM_AIRSTRIKE_STRATAGEM_ICON = preload("uid://cgitlfcxgmgnc")
const EAGLE_REARM_STRATAGEM_ICON = preload("uid://t3skgn7gdepm")
const EAGLE_SMOKE_STRIKE_STRATAGEM_ICON = preload("uid://eegltx2c3prf")
const EAGLE_STRAFING_RUN_STRATAGEM_ICON = preload("uid://1haqs5gv5563")
const EMANCIPATOR_EXOSUIT_STRATAGEM_ICON = preload("uid://bch88r1un3ty")
const EMS_MORTAR_SENTRY_STRATAGEM_ICON = preload("uid://ch8250yjt3v5g")
const EPOCH_STRATAGEM_ICON = preload("uid://bvmwqxbd127na")
const EXPENDABLE_ANTI_TANK_STRATAGEM_ICON = preload("uid://bpfp6r0bpliij")
const EXPENDABLE_NAPALM_STRATAGEM_ICON = preload("uid://bikjtd6gi4rk0")
const FAST_RECON_VEHICLE_STRATAGEM_ICON = preload("uid://dm8wa1g77nykx")
const FLAME_SENTRY_STRATAGEM_ICON = preload("uid://bv7g6014203vf")
const FLAMETHROWER_STRATAGEM_ICON = preload("uid://dbwo154fiw4v2")
const GAS_MINES_STRATAGEM_ICON = preload("uid://dv6f7ch5ybokq")
const GAS_MORTAR_SENTRY_STRATAGEM_ICON = preload("uid://c23yxemfpop4f")
const GATLING_SENTRY_STRATAGEM_ICON = preload("uid://di4exrkrdbdx0")
const GRENADE_LAUNCHER_STRATAGEM_ICON = preload("uid://c3fnopjyqdmyr")
const GRENADIER_BATTLEMENT_STRATAGEM_ICON = preload("uid://c7ootb65i05qt")
const GUARD_DOG_STRATAGEM_ICON = preload("uid://dbgv02y5xxfr7")
const HEAVY_MACHINE_GUN_STRATAGEM_ICON = preload("uid://vejdh7xk8p7j")
const HELLBOMB_STRATAGEM_ICON = preload("uid://biaire5ftqdu6")
const HMG_EMPLACEMENT_STRATAGEM_ICON = preload("uid://cw4wa8awxlwla")
const HOT_DOG_STRATAGEM_ICON = preload("uid://bdyygxfhpmlb0")
const HOVER_PACK_STRATAGEM_ICON = preload("uid://dk55dxfgq8ikk")
const INCINERATOR_FRV_STRATAGEM_ICON = preload("res://Assets/icons/Incinerator FRV Stratagem Icon.svg")
const INCENDIARY_MINES_STRATAGEM_ICON = preload("uid://bt5ddwp15grwp")
const JUMP_PACK_STRATAGEM_ICON = preload("uid://baq4rgdbfp0ud")
const K_9_STRATAGEM_ICON = preload("uid://ddx5rt34tg7rl")
const LASER_CANNON_STRATAGEM_ICON = preload("uid://cxrhht80mwk7m")
const LASER_SENTRY_STRATAGEM_ICON = preload("uid://cnhvv5gflv1s4")
const LEVELLER_STRATAGEM_ICON = preload("uid://dgjavbilvj33b")
const LUMBERER_EXOSUIT_STRATAGEM_ICON = preload("res://Assets/icons/Lumberer Exosuit Stratagem Icon.svg")
const MACHINE_GUN_SENTRY_STRATAGEM_ICON = preload("uid://cogq7o821obn6")
const MACHINE_GUN_STRATAGEM_ICON = preload("uid://dev15ju2djofe")
const MAXIGUN_STRATAGEM_ICON = preload("uid://dc0o8mn24bjie")
const MORTAR_SENTRY_STRATAGEM_ICON = preload("uid://ddl3q6k0okoa7")
const ONE_TRUE_FLAG_STRATAGEM_ICON = preload("uid://cwtd4ejr1nnsr")
const ORBITAL_120_MM_HE_BARRAGE_STRATAGEM_ICON = preload("uid://c4jhp5kk5xcct")
const ORBITAL_380_MM_HE_BARRAGE_STRATAGEM_ICON = preload("uid://b27b3v3io4xiy")
const ORBITAL_AIRBURST_STRIKE_STRATAGEM_ICON = preload("uid://bksdsu0tifvh5")
const ORBITAL_EMS_STRIKE_STRATAGEM_ICON = preload("uid://c7o02cswh3at4")
const ORBITAL_GAS_STRIKE_STRATAGEM_ICON = preload("uid://bldt6mlhfh6ls")
const ORBITAL_GATLING_BARRAGE_STRATAGEM_ICON = preload("uid://ch1yvw4jniilc")
const ORBITAL_ILLUMINATION_FLARE_STRATAGEM_ICON = preload("uid://80fg8061yvry")
const ORBITAL_LASER_STRATAGEM_ICON = preload("uid://b5lhwnq6xkulh")
const ORBITAL_NAPALM_BARRAGE_STRATAGEM_ICON = preload("uid://cbjrbnqpg2mjc")
const ORBITAL_PRECISION_STRIKE_STRATAGEM_ICON = preload("uid://b4t68t5xe3wnr")
const ORBITAL_RAILCANNON_STRIKE_STRATAGEM_ICON = preload("uid://ct6fc47lbkcc4")
const ORBITAL_SMOKE_STRIKE_STRATAGEM_ICON = preload("uid://dfr23w32rl8w6")
const ORBITAL_WALKING_BARRAGE_STRATAGEM_ICON = preload("uid://c7u1r2jv72t1x")
const PATRIOT_EXOSUIT_STRATAGEM_ICON = preload("uid://ddjh8j7cjpfwe")
const PORTABLE_HELLBOMB_STRATAGEM_ICON = preload("uid://wvayxqxxm3uu")
const PROSPECTING_DRILL_STRATAGEM_ICON = preload("uid://cy6x4c00g2lr1")
const QUASAR_CANNON_STRATAGEM_ICON = preload("uid://detlskg6etk71")
const RAILGUN_STRATAGEM_ICON = preload("uid://digjjovmwev1x")
const RECOILLESS_RIFLE_STRATAGEM_ICON = preload("uid://cp8vfp2dxency")
const REINFORCE_STRATAGEM_ICON = preload("uid://cw6mgo747jat")
const RESUPPLY_STRATAGEM_ICON = preload("uid://c1c4blidicqiw")
const ROCKET_SENTRY_STRATAGEM_ICON = preload("uid://bu5yux4yurx5l")
const ROVER_STRATAGEM_ICON = preload("uid://di5va3wtqorye")
const SEAF_ARTILLERY_STRATAGEM_ICON = preload("uid://be3cpqe7hytnl")
const SEISMIC_PROBE_STRATAGEM_ICON = preload("uid://bnpk6enp8sxgx")
const SHIELD_GENERATOR_PACK_STRATAGEM_ICON = preload("uid://cw8nt6dyc26no")
const SHIELD_GENERATOR_RELAY_STRATAGEM_ICON = preload("uid://c6iyruvlcm6n6")
const SOLO_SILO_STRATAGEM_ICON = preload("uid://cdwpk8bya7se3")
const SOS_BEACON_STRATAGEM_ICON = preload("uid://c8ebl7lm5d015")
const SPEAR_STRATAGEM_ICON = preload("uid://cjndmkhoi7r3d")
const SPEARGUN_STRATAGEM_ICON = preload("uid://co8ciopbkitan")
const STALWART_STRATAGEM_ICON = preload("uid://bf0b74eto1q82")
const START_UPLOAD_STRATAGEM_ICON = preload("uid://b548vm8q5o4lb")
const STERILIZER_STRATAGEM_ICON = preload("uid://bm2armvopxfsu")
const STRATAGEM_ARROW_DOWN = preload("uid://b4sgli4cp266i")
const STRATAGEM_ARROW_LEFT = preload("uid://cdcdfdbvxyd")
const STRATAGEM_ARROW_RIGHT = preload("uid://4qd5kbllk47s")
const STRATAGEM_ARROW_UP = preload("uid://b6kj2fqvf63gp")
const SUPER_EARTH_FLAG_STRATAGEM_ICON = preload("uid://qkfea0c10y6y")
const SUPPLY_PACK_STRATAGEM_ICON = preload("uid://dug4flgdpoyee")
const SUPPLY_FRV_STRATAGEM_ICON = preload("res://Assets/icons/Supply FRV Stratagem Icon.svg")
const TESLA_TOWER_STRATAGEM_ICON = preload("uid://7wdo66xvnp87")
const W_A_S_P__LAUNCHER_STRATAGEM_ICON = preload("uid://dj32pqfuw1d1p")
const WARP_PACK_STRATAGEM_ICON = preload("uid://bwmt438cmwrjy")

static var CUSTOM_STRATAGEMS: Dictionary = {}
static var _custom_stratagems_loaded := false

const STRATAGEMS = {
	"AIRBURST_ROCKET_LAUNCHER": {
		"name": "Airburst Rocket Launcher",
		"icon": AIRBURST_ROCKET_LAUNCHER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.LEFT, ARROW.RIGHT],
	},
	"ANTI_MATERIEL_RIFLE": {
		"name": "Anti-Materiel Rifle",
		"icon": ANTI_MATERIEL_RIFLE_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.UP, ARROW.DOWN],
	},
	"ANTI_PERSONNEL_MINEFIELD": {
		"name": "Anti-Personnel Minefield",
		"icon": ANTI_PERSONNEL_MINEFIELD_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.RIGHT],
	},
	"ANTI_TANK_EMPLACEMENT": {
		"name": "Anti-Tank Emplacement",
		"icon": ANTI_TANK_EMPLACEMENT_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.RIGHT, ARROW.RIGHT, ARROW.RIGHT],
	},
	"ANTI_TANK_MINES": {
		"name": "Anti-Tank Mines",
		"icon": ANTI_TANK_MINES_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.UP],
	},
	"ARC_THROWER": {
		"name": "Arc Thrower",
		"icon": ARC_THROWER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.LEFT],
	},
	"AUTOCANNON_SENTRY": {
		"name": "Autocannon Sentry",
		"icon": AUTOCANNON_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.UP, ARROW.LEFT, ARROW.UP],
	},
	"AUTOCANNON": {
		"name": "Autocannon",
		"icon": AUTOCANNON_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.RIGHT],
	},
	"BALLISTIC_SHIELD_BACKPACK": {
		"name": "Ballistic Shield Backpack",
		"icon": BALLISTIC_SHIELD_BACKPACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.DOWN, ARROW.UP, ARROW.LEFT],
	},
	"BASTION_MK_XVI": {
		"name": "Bastion MK XVI",
		"icon": BASTION_MK_XVI_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.DOWN, ARROW.UP],
	},
	"BELT_FED_GRENADE_LAUNCHER": {
		"name": "Belt-Fed Grenade Launcher",
		"icon": BELT_FED_GRENADE_LAUNCHER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.UP],
	},
	"BREACHING_HAMMER": {
		"name": "Breaching Hammer",
		"icon": BREACHING_HAMMER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.LEFT, ARROW.UP],
	},
	"BREAKTHROUGH_EXOSUIT": {
		"name": "Breakthrough Exosuit",
		"icon": BREAKTHROUGH_EXOSUIT_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN, ARROW.UP],
	},
	"BULLET_STORM": {
		"name": "Bullet Storm",
		"icon": BULLET_STORM_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.LEFT],
	},
	"C_4_PACK": {
		"name": "C-4 Pack",
		"icon": C_4_PACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.UP, ARROW.RIGHT, ARROW.UP],
	},
	"CALL_IN_SUPER_DESTROYER": {
		"name": "Call In Super Destroyer",
		"icon": CALL_IN_SUPER_DESTROYER_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.UP, ARROW.DOWN, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.LEFT, ARROW.RIGHT],
	},
	"CARGO_CONTAINER": {
		"name": "Cargo Container",
		"icon": CARGO_CONTAINER_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.UP, ARROW.DOWN, ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN],
	},
	"COMMANDO": {
		"name": "Commando",
		"icon": COMMANDO_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.DOWN, ARROW.RIGHT],
	},
	"CREMATOR": {
		"name": "Cremator",
		"icon": CREMATOR_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.UP, ARROW.LEFT],
	},
	"DARK_FLUID_VESSEL": {
		"name": "Dark Fluid Vessel",
		"icon": DARK_FLUID_VESSEL_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.UP],
	},
	"DE_ESCALATOR": {
		"name": "De-Escalator",
		"icon": DE_ESCALATOR_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.LEFT, ARROW.RIGHT],
	},
	"DEFOLIATION_TOOL": {
		"name": "Defoliation Tool",
		"icon": DEFOLIATION_TOOL_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN],
	},
	"DIRECTIONAL_SHIELD": {
		"name": "Directional Shield",
		"icon": DIRECTIONAL_SHIELD_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.RIGHT, ARROW.UP, ARROW.UP],
	},
	"DOG_BREATH": {
		"name": "Dog Breath",
		"icon": DOG_BREATH_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.RIGHT, ARROW.UP],
	},
	"EAGLE_110_MM_ROCKET_PODS": {
		"name": "Eagle 110 MM Rocket Pods",
		"icon": EAGLE_110_MM_ROCKET_PODS_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.UP, ARROW.LEFT],
	},
	"EAGLE_500_KG_BOMB": {
		"name": "Eagle 500 KG Bomb",
		"icon": EAGLE_500_KG_BOMB_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.DOWN, ARROW.DOWN],
	},
	"EAGLE_AIRSTRIKE": {
		"name": "Eagle Airstrike",
		"icon": EAGLE_AIRSTRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.RIGHT],
	},
	"EAGLE_CLUSTER_BOMB": {
		"name": "Eagle Cluster Bomb",
		"icon": EAGLE_CLUSTER_BOMB_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.DOWN, ARROW.RIGHT],
	},
	"EAGLE_NAPALM_AIRSTRIKE": {
		"name": "Eagle Napalm Airstrike",
		"icon": EAGLE_NAPALM_AIRSTRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.UP],
	},
	"EAGLE_REARM": {
		"name": "Eagle Rearm",
		"icon": EAGLE_REARM_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.RIGHT],
	},
	"EAGLE_SMOKE_STRIKE": {
		"name": "Eagle Smoke Strike",
		"icon": EAGLE_SMOKE_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.UP, ARROW.DOWN],
	},
	"EAGLE_STRAFING_RUN": {
		"name": "Eagle Strafing Run",
		"icon": EAGLE_STRAFING_RUN_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.RIGHT, ARROW.RIGHT],
	},
	"EMANCIPATOR_EXOSUIT": {
		"name": "Emancipator Exosuit",
		"icon": EMANCIPATOR_EXOSUIT_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.LEFT, ARROW.DOWN, ARROW.UP],
	},
	"EMS_MORTAR_SENTRY": {
		"name": "EMS Mortar Sentry",
		"icon": EMS_MORTAR_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.RIGHT],
	},
	"EPOCH": {
		"name": "Epoch",
		"icon": EPOCH_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.LEFT, ARROW.RIGHT],
	},
	"EXPENDABLE_ANTI_TANK": {
		"name": "Expendable Anti-Tank",
		"icon": EXPENDABLE_ANTI_TANK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.RIGHT],
	},
	"EXPENDABLE_NAPALM": {
		"name": "Expendable Napalm",
		"icon": EXPENDABLE_NAPALM_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.LEFT],
	},
	"FAST_RECON_VEHICLE": {
		"name": "Fast Recon Vehicle",
		"icon": FAST_RECON_VEHICLE_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.UP],
	},
	"FLAME_SENTRY": {
		"name": "Flame Sentry",
		"icon": FLAME_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.UP],
	},
	"FLAMETHROWER": {
		"name": "Flamethrower",
		"icon": FLAMETHROWER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.DOWN, ARROW.UP],
	},
	"GAS_MINES": {
		"name": "Gas Mines",
		"icon": GAS_MINES_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.LEFT, ARROW.RIGHT],
	},
	"GAS_MORTAR_SENTRY": {
		"name": "Gas Mortar Sentry",
		"icon": GAS_MORTAR_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN],
	},
	"GATLING_SENTRY": {
		"name": "Gatling Sentry",
		"icon": GATLING_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.LEFT],
	},
	"GRENADE_LAUNCHER": {
		"name": "Grenade Launcher",
		"icon": GRENADE_LAUNCHER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.LEFT, ARROW.DOWN],
	},
	"GRENADIER_BATTLEMENT": {
		"name": "Grenadier Battlement",
		"icon": GRENADIER_BATTLEMENT_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT],
	},
	"GUARD_DOG": {
		"name": "Guard Dog",
		"icon": GUARD_DOG_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.RIGHT, ARROW.DOWN],
	},
	"HEAVY_MACHINE_GUN": {
		"name": "Heavy Machine Gun",
		"icon": HEAVY_MACHINE_GUN_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.DOWN, ARROW.DOWN],
	},
	"HELLBOMB": {
		"name": "Hellbomb",
		"icon": HELLBOMB_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.UP],
	},
	"HMG_EMPLACEMENT": {
		"name": "HMG Emplacement",
		"icon": HMG_EMPLACEMENT_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.RIGHT, ARROW.RIGHT, ARROW.LEFT],
	},
	"HOT_DOG": {
		"name": "Guard Dog Hot",
		"icon": HOT_DOG_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.LEFT, ARROW.LEFT],
	},
	"HOVER_PACK": {
		"name": "Hover Pack",
		"icon": HOVER_PACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT],
	},
	"INCENDIARY_MINES": {
		"name": "Incendiary Mines",
		"icon": INCENDIARY_MINES_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.LEFT, ARROW.DOWN],
	},
	"INCINERATOR_FRV": {
		"name": "Incinerator FRV",
		"icon": INCINERATOR_FRV_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.UP],
	},
	"JUMP_PACK": {
		"name": "Jump Pack",
		"icon": JUMP_PACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.DOWN, ARROW.UP],
	},
	"K_9": {
		"name": "Guard Dog K-9",
		"icon": K_9_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.RIGHT, ARROW.LEFT],
	},
	"LASER_CANNON": {
		"name": "Laser Cannon",
		"icon": LASER_CANNON_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.LEFT],
	},
	"LASER_SENTRY": {
		"name": "Laser Sentry",
		"icon": LASER_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.RIGHT],
	},
	"LEVELLER": {
		"name": "Leveller",
		"icon": LEVELLER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.DOWN],
	},
	"LUMBERER_EXOSUIT": {
		"name": "Lumberer Exosuit",
		"icon": LUMBERER_EXOSUIT_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.RIGHT, ARROW.LEFT, ARROW.UP],
	},
	"MACHINE_GUN_SENTRY": {
		"name": "Machine Gun Sentry",
		"icon": MACHINE_GUN_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.RIGHT, ARROW.UP],
	},
	"MACHINE_GUN": {
		"name": "Machine Gun",
		"icon": MACHINE_GUN_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.RIGHT],
	},
	"MAXIGUN": {
		"name": "Maxigun",
		"icon": MAXIGUN_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.UP],
	},
	"MORTAR_SENTRY": {
		"name": "Mortar Sentry",
		"icon": MORTAR_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN],
	},
	"ONE_TRUE_FLAG": {
		"name": "One True Flag",
		"icon": ONE_TRUE_FLAG_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.RIGHT, ARROW.UP],
	},
	"ORBITAL_120_MM_HE_BARRAGE": {
		"name": "Orbital 120 MM HE Barrage",
		"icon": ORBITAL_120_MM_HE_BARRAGE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN],
	},
	"ORBITAL_380_MM_HE_BARRAGE": {
		"name": "Orbital 380 MM HE Barrage",
		"icon": ORBITAL_380_MM_HE_BARRAGE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.LEFT, ARROW.DOWN, ARROW.DOWN],
	},
	"ORBITAL_AIRBURST_STRIKE": {
		"name": "Orbital Airburst Strike",
		"icon": ORBITAL_AIRBURST_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.RIGHT],
	},
	"ORBITAL_EMS_STRIKE": {
		"name": "Orbital EMS Strike",
		"icon": ORBITAL_EMS_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.LEFT, ARROW.DOWN],
	},
	"ORBITAL_GAS_STRIKE": {
		"name": "Orbital Gas Strike",
		"icon": ORBITAL_GAS_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN, ARROW.RIGHT],
	},
	"ORBITAL_GATLING_BARRAGE": {
		"name": "Orbital Gatling Barrage",
		"icon": ORBITAL_GATLING_BARRAGE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.UP],
	},
	"ORBITAL_ILLUMINATION_FLARE": {
		"name": "Orbital Illumination Flare",
		"icon": ORBITAL_ILLUMINATION_FLARE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.RIGHT, ARROW.LEFT, ARROW.LEFT, ARROW.LEFT],
	},
	"ORBITAL_LASER": {
		"name": "Orbital Laser",
		"icon": ORBITAL_LASER_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.DOWN],
	},
	"ORBITAL_NAPALM_BARRAGE": {
		"name": "Orbital Napalm Barrage",
		"icon": ORBITAL_NAPALM_BARRAGE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.UP],
	},
	"ORBITAL_PRECISION_STRIKE": {
		"name": "Orbital Precision Strike",
		"icon": ORBITAL_PRECISION_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.UP],
	},
	"ORBITAL_RAILCANNON_STRIKE": {
		"name": "Orbital Railcannon Strike",
		"icon": ORBITAL_RAILCANNON_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.UP, ARROW.DOWN, ARROW.DOWN, ARROW.RIGHT],
	},
	"ORBITAL_SMOKE_STRIKE": {
		"name": "Orbital Smoke Strike",
		"icon": ORBITAL_SMOKE_STRIKE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.RIGHT, ARROW.DOWN, ARROW.UP],
	},
	"ORBITAL_WALKING_BARRAGE": {
		"name": "Orbital Walking Barrage",
		"icon": ORBITAL_WALKING_BARRAGE_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN],
	},
	"PATRIOT_EXOSUIT": {
		"name": "Patriot Exosuit",
		"icon": PATRIOT_EXOSUIT_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.LEFT, ARROW.DOWN, ARROW.DOWN],
	},
	"PORTABLE_HELLBOMB": {
		"name": "Portable Hellbomb",
		"icon": PORTABLE_HELLBOMB_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.UP, ARROW.UP, ARROW.UP],
	},
	"PROSPECTING_DRILL": {
		"name": "Prospecting Drill",
		"icon": PROSPECTING_DRILL_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN, ARROW.DOWN],
	},
	"QUASAR_CANNON": {
		"name": "Quasar Cannon",
		"icon": QUASAR_CANNON_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.RIGHT],
	},
	"RAILGUN": {
		"name": "Railgun",
		"icon": RAILGUN_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.RIGHT],
	},
	"RECOILLESS_RIFLE": {
		"name": "Recoilless Rifle",
		"icon": RECOILLESS_RIFLE_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.RIGHT, ARROW.LEFT],
	},
	"REINFORCE": {
		"name": "Reinforce",
		"icon": REINFORCE_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.DOWN, ARROW.RIGHT, ARROW.LEFT, ARROW.UP],
	},
	"RESUPPLY": {
		"name": "Resupply",
		"icon": RESUPPLY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.UP, ARROW.RIGHT],
	},
	"ROCKET_SENTRY": {
		"name": "Rocket Sentry",
		"icon": ROCKET_SENTRY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.RIGHT, ARROW.LEFT],
	},
	"ROVER": {
		"name": "Guard Dog Rover",
		"icon": ROVER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.UP, ARROW.RIGHT, ARROW.RIGHT],
	},
	"SEAF_ARTILLERY": {
		"name": "SEAF Artillery",
		"icon": SEAF_ARTILLERY_STRATAGEM_ICON,
		"sequence": [ARROW.RIGHT, ARROW.UP, ARROW.UP, ARROW.DOWN],
	},
	"SEISMIC_PROBE": {
		"name": "Seismic Probe",
		"icon": SEISMIC_PROBE_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.UP, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN, ARROW.DOWN],
	},
	"SHIELD_GENERATOR_PACK": {
		"name": "Shield Generator Pack",
		"icon": SHIELD_GENERATOR_PACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.LEFT, ARROW.RIGHT, ARROW.LEFT, ARROW.RIGHT],
	},
	"SHIELD_GENERATOR_RELAY": {
		"name": "Shield Generator Relay",
		"icon": SHIELD_GENERATOR_RELAY_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.LEFT, ARROW.RIGHT],
	},
	"SOLO_SILO": {
		"name": "Solo Silo",
		"icon": SOLO_SILO_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.DOWN, ARROW.DOWN],
	},
	"SOS_BEACON": {
		"name": "SOS Beacon",
		"icon": SOS_BEACON_STRATAGEM_ICON,
		"sequence": [ARROW.UP, ARROW.DOWN, ARROW.RIGHT, ARROW.UP],
	},
	"SPEAR": {
		"name": "Spear",
		"icon": SPEAR_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.UP, ARROW.DOWN, ARROW.DOWN],
	},
	"SPEARGUN": {
		"name": "Speargun",
		"icon": SPEARGUN_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.RIGHT],
	},
	"STALWART": {
		"name": "Stalwart",
		"icon": STALWART_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.LEFT],
	},
	"START_UPLOAD": {
		"name": "Start Upload",
		"icon": START_UPLOAD_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.RIGHT, ARROW.UP, ARROW.UP, ARROW.UP],
	},
	"STERILIZER": {
		"name": "Sterilizer",
		"icon": STERILIZER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.UP, ARROW.DOWN, ARROW.LEFT],
	},
	"SUPER_EARTH_FLAG": {
		"name": "Super Earth Flag",
		"icon": SUPER_EARTH_FLAG_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.DOWN, ARROW.UP],
	},
	"SUPPLY_PACK": {
		"name": "Supply Pack",
		"icon": SUPPLY_PACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.UP, ARROW.DOWN],
	},
	"SUPPLY_FRV": {
		"name": "Supply FRV",
		"icon": SUPPLY_FRV_STRATAGEM_ICON,
		"sequence": [ARROW.LEFT, ARROW.DOWN, ARROW.LEFT, ARROW.LEFT, ARROW.DOWN, ARROW.UP, ARROW.RIGHT],
	},
	"TESLA_TOWER": {
		"name": "Tesla Tower",
		"icon": TESLA_TOWER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.UP, ARROW.RIGHT, ARROW.UP, ARROW.LEFT, ARROW.RIGHT],
	},
	"W_A_S_P__LAUNCHER": {
		"name": "W.A.S.P. Launcher",
		"icon": W_A_S_P__LAUNCHER_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.DOWN, ARROW.UP, ARROW.DOWN, ARROW.RIGHT],
	},
	"WARP_PACK": {
		"name": "Warp Pack",
		"icon": WARP_PACK_STRATAGEM_ICON,
		"sequence": [ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT, ARROW.DOWN, ARROW.LEFT, ARROW.RIGHT],
	},
}


static func load_custom_stratagems(force_reload := false) -> void:
	if _custom_stratagems_loaded and not force_reload:
		return

	CUSTOM_STRATAGEMS.clear()
	_custom_stratagems_loaded = true
	if not FileAccess.file_exists(CUSTOM_STRATAGEMS_PATH):
		return

	var file := FileAccess.open(CUSTOM_STRATAGEMS_PATH, FileAccess.READ)
	if not file:
		push_warning("Failed to open custom stratagem data.")
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Array:
		push_warning("Custom stratagem data is invalid and was ignored.")
		return

	for raw_entry in parsed as Array:
		if raw_entry is not Dictionary:
			continue
		var entry := raw_entry as Dictionary
		var strat_id := str(entry.get("id", ""))
		var name := str(entry.get("name", "")).strip_edges()
		var category := str(entry.get("category", "support"))
		var sequence := sanitize_stratagem_sequence(entry.get("sequence", []))
		if not _is_valid_custom_stratagem_id(strat_id):
			continue
		if name.is_empty() or name.length() > 48 or sequence.is_empty():
			continue
		if not STRATAGEM_CATEGORY_ORDER.has(category):
			category = "support"

		var icon_path := _get_custom_icon_path(strat_id)
		var icon: Texture2D = _load_custom_icon(icon_path)
		if not icon:
			icon = START_UPLOAD_STRATAGEM_ICON
		CUSTOM_STRATAGEMS[strat_id] = {
			"name": name,
			"icon": icon,
			"sequence": sequence,
			"category": category,
			"custom": true,
		}


static func get_all_stratagems() -> Dictionary:
	load_custom_stratagems()
	var catalogue := STRATAGEMS.duplicate()
	for strat_id in CUSTOM_STRATAGEMS:
		catalogue[strat_id] = CUSTOM_STRATAGEMS[strat_id]
	return catalogue


static func get_custom_stratagems() -> Dictionary:
	load_custom_stratagems()
	return CUSTOM_STRATAGEMS.duplicate()


static func has_stratagem(strat_id: String) -> bool:
	load_custom_stratagems()
	return STRATAGEMS.has(strat_id) or CUSTOM_STRATAGEMS.has(strat_id)


static func get_stratagem(strat_id: String) -> Dictionary:
	load_custom_stratagems()
	if CUSTOM_STRATAGEMS.has(strat_id):
		return CUSTOM_STRATAGEMS[strat_id]
	if STRATAGEMS.has(strat_id):
		return STRATAGEMS[strat_id]
	return {}


static func is_custom_stratagem(strat_id: String) -> bool:
	load_custom_stratagems()
	return CUSTOM_STRATAGEMS.has(strat_id)


static func save_custom_stratagem(
	strat_id: String,
	name: String,
	category: String,
	sequence_value: Variant,
	icon_bytes := PackedByteArray(),
	icon_file_name := ""
) -> Dictionary:
	load_custom_stratagems()
	name = name.strip_edges()
	if name.is_empty():
		return {"ok": false, "error": "Enter a stratagem name."}
	if name.length() > 48:
		return {"ok": false, "error": "Names can be at most 48 characters."}
	if not STRATAGEM_CATEGORY_ORDER.has(category):
		return {"ok": false, "error": "Choose a valid category."}

	var sequence := sanitize_stratagem_sequence(sequence_value)
	if sequence.is_empty():
		return {"ok": false, "error": "Enter a code using 1–20 directions."}
	if not strat_id.is_empty() and not CUSTOM_STRATAGEMS.has(strat_id):
		return {"ok": false, "error": "That custom stratagem no longer exists."}

	var is_new := strat_id.is_empty()
	if is_new:
		strat_id = _create_custom_stratagem_id()
	if icon_bytes.is_empty() and is_new:
		return {"ok": false, "error": "Choose a PNG, JPG, WebP, or SVG icon."}

	var icon: Texture2D
	if not icon_bytes.is_empty():
		var decoded := _decode_custom_icon(icon_bytes, icon_file_name)
		if not bool(decoded.get("ok", false)):
			return decoded
		var image := decoded["image"] as Image
		var icon_directory_error := DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(CUSTOM_ICON_DIRECTORY)
		)
		if icon_directory_error != OK:
			return {"ok": false, "error": "Could not create local icon storage."}
		var save_error := image.save_png(_get_custom_icon_path(strat_id))
		if save_error != OK:
			return {"ok": false, "error": "Could not save the custom icon."}
		icon = ImageTexture.create_from_image(image)
	else:
		icon = CUSTOM_STRATAGEMS[strat_id]["icon"]

	CUSTOM_STRATAGEMS[strat_id] = {
		"name": name,
		"icon": icon,
		"sequence": sequence,
		"category": category,
		"custom": true,
	}
	var write_error := _write_custom_stratagems()
	if write_error != OK:
		return {"ok": false, "error": "Could not save custom stratagem data."}
	return {"ok": true, "id": strat_id}


static func delete_custom_stratagem(strat_id: String) -> int:
	load_custom_stratagems()
	if not CUSTOM_STRATAGEMS.has(strat_id):
		return ERR_DOES_NOT_EXIST
	CUSTOM_STRATAGEMS.erase(strat_id)
	var icon_path := _get_custom_icon_path(strat_id)
	if FileAccess.file_exists(icon_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(icon_path))
		if remove_error != OK:
			push_warning("Failed to remove custom icon: %s" % icon_path)
	return _write_custom_stratagems()


static func sanitize_stratagem_sequence(raw_value: Variant) -> Array:
	var sanitized: Array = []
	if raw_value is not Array:
		return sanitized
	for raw_arrow in raw_value as Array:
		var arrow := int(raw_arrow)
		if arrow < ARROW.DOWN or arrow > ARROW.RIGHT:
			return []
		sanitized.append(arrow)
		if sanitized.size() > 20:
			return []
	return sanitized


static func create_custom_icon_preview(icon_bytes: PackedByteArray, file_name: String) -> Dictionary:
	var decoded := _decode_custom_icon(icon_bytes, file_name)
	if not bool(decoded.get("ok", false)):
		return decoded
	return {
		"ok": true,
		"texture": ImageTexture.create_from_image(decoded["image"] as Image),
	}


static func _decode_custom_icon(icon_bytes: PackedByteArray, file_name: String) -> Dictionary:
	if icon_bytes.is_empty() or icon_bytes.size() > CUSTOM_ICON_MAX_BYTES:
		return {"ok": false, "error": "Icons must be smaller than 3 MB."}
	var extension := file_name.get_extension().to_lower()
	var image := Image.new()
	var load_error := ERR_FILE_UNRECOGNIZED
	match extension:
		"png":
			load_error = image.load_png_from_buffer(icon_bytes)
		"jpg", "jpeg":
			load_error = image.load_jpg_from_buffer(icon_bytes)
		"webp":
			load_error = image.load_webp_from_buffer(icon_bytes)
		"svg":
			load_error = image.load_svg_from_buffer(icon_bytes)
		_:
			return {"ok": false, "error": "Use a PNG, JPG, WebP, or SVG file."}
	if load_error != OK or image.is_empty():
		return {"ok": false, "error": "The selected icon could not be decoded."}
	if image.get_width() > CUSTOM_ICON_MAX_DIMENSION or image.get_height() > CUSTOM_ICON_MAX_DIMENSION:
		return {"ok": false, "error": "Icons can be at most 2048 × 2048 pixels."}

	var longest_side := maxi(image.get_width(), image.get_height())
	if longest_side > CUSTOM_ICON_DISPLAY_SIZE:
		var scale_factor := float(CUSTOM_ICON_DISPLAY_SIZE) / float(longest_side)
		image.resize(
			maxi(1, roundi(image.get_width() * scale_factor)),
			maxi(1, roundi(image.get_height() * scale_factor)),
			Image.INTERPOLATE_LANCZOS
		)
	return {"ok": true, "image": image}


static func _load_custom_icon(icon_path: String) -> Texture2D:
	if not FileAccess.file_exists(icon_path):
		return null
	var image := Image.load_from_file(icon_path)
	if not image or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


static func _write_custom_stratagems() -> int:
	var serialized: Array = []
	var strat_ids := CUSTOM_STRATAGEMS.keys()
	strat_ids.sort()
	for strat_id in strat_ids:
		var strat: Dictionary = CUSTOM_STRATAGEMS[strat_id]
		serialized.append({
			"id": strat_id,
			"name": strat["name"],
			"category": strat["category"],
			"sequence": strat["sequence"],
		})
	var file := FileAccess.open(CUSTOM_STRATAGEMS_PATH, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(serialized, "\t"))
	file.close()
	if OS.has_feature("web"):
		JavaScriptBridge.force_fs_sync()
	return OK


static func _create_custom_stratagem_id() -> String:
	var strat_id := ""
	while strat_id.is_empty() or STRATAGEMS.has(strat_id) or CUSTOM_STRATAGEMS.has(strat_id):
		strat_id = "CUSTOM_%d_%04d" % [int(Time.get_unix_time_from_system()), randi_range(0, 9999)]
	return strat_id


static func _is_valid_custom_stratagem_id(strat_id: String) -> bool:
	return strat_id.begins_with("CUSTOM_") and strat_id.is_valid_identifier()


static func _get_custom_icon_path(strat_id: String) -> String:
	return CUSTOM_ICON_DIRECTORY.path_join("%s.png" % strat_id)


static func get_stratagem_category(strat_id: String) -> String:
	load_custom_stratagems()
	if CUSTOM_STRATAGEMS.has(strat_id):
		return str(CUSTOM_STRATAGEMS[strat_id].get("category", "support"))
	if STRATAGEM_CATEGORY_OVERRIDES.has(strat_id):
		return STRATAGEM_CATEGORY_OVERRIDES[strat_id]
	if strat_id.begins_with("ORBITAL_"):
		return "orbital"
	if strat_id.begins_with("EAGLE_"):
		return "eagle"
	return "support"


static func load_practice_config() -> Dictionary:
	load_custom_stratagems()
	var config := ConfigFile.new()
	var data := {
		"selected_strat_ids": [],
		"randomize_mode": false,
		"audio_volume": DEFAULT_AUDIO_VOLUME,
		"show_stratagem_arrows": DEFAULT_SHOW_STRATAGEM_ARROWS,
		"require_holding": DEFAULT_REQUIRE_HOLD,
		"touch_control_scale": DEFAULT_TOUCH_CONTROL_SCALE,
		"hold_binding": get_default_hold_binding(),
		"controller_hold_binding": get_default_controller_hold_binding(),
		"direction_bindings": get_default_direction_bindings(),
		"controller_direction_bindings": get_default_controller_direction_bindings(),
		"practice_stats": {},
	}

	if config.load(PRACTICE_CONFIG_PATH) != OK:
		return data

	var sanitized_ids: Array[String] = []
	var stored_ids: Array = config.get_value("practice", "selected_strat_ids", [])
	for value in stored_ids:
		var strat_id := str(value)
		if has_stratagem(strat_id) and not sanitized_ids.has(strat_id):
			sanitized_ids.append(strat_id)

	data["selected_strat_ids"] = sanitized_ids
	data["randomize_mode"] = bool(config.get_value("practice", "randomize_mode", false))
	data["audio_volume"] = clampf(float(config.get_value("practice", "audio_volume", DEFAULT_AUDIO_VOLUME)), 0.0, 1.0)
	data["show_stratagem_arrows"] = bool(config.get_value("practice", "show_stratagem_arrows", DEFAULT_SHOW_STRATAGEM_ARROWS))
	data["require_holding"] = bool(config.get_value("practice", "require_holding", DEFAULT_REQUIRE_HOLD))
	data["touch_control_scale"] = sanitize_touch_control_scale(
		config.get_value("practice", "touch_control_scale", DEFAULT_TOUCH_CONTROL_SCALE)
	)
	var raw_hold_binding: Variant = config.get_value("practice", "hold_binding", get_default_hold_binding())
	var raw_direction_bindings: Variant = config.get_value("practice", "direction_bindings", get_default_direction_bindings())
	var raw_controller_hold_binding: Variant = config.get_value("practice", "controller_hold_binding", get_default_controller_hold_binding())
	var raw_controller_direction_bindings: Variant = config.get_value("practice", "controller_direction_bindings", get_default_controller_direction_bindings())

	data["hold_binding"] = sanitize_input_binding(raw_hold_binding, get_default_hold_binding(), true, false)
	data["direction_bindings"] = sanitize_direction_bindings(raw_direction_bindings)
	data["controller_hold_binding"] = sanitize_input_binding(
		raw_controller_hold_binding,
		get_default_controller_hold_binding(),
		false,
		true
	)
	data["controller_direction_bindings"] = sanitize_controller_direction_bindings(raw_controller_direction_bindings)

	# Migrate legacy controller bindings previously stored in the keyboard slots.
	if data["controller_hold_binding"] == get_default_controller_hold_binding():
		var legacy_controller_hold := sanitize_input_binding(
			raw_hold_binding,
			get_default_controller_hold_binding(),
			false,
			true
		)
		if str(legacy_controller_hold.get("type", "")) == "joy_button":
			data["controller_hold_binding"] = legacy_controller_hold

	if raw_controller_direction_bindings is not Dictionary:
		var migrated_controller_bindings: Dictionary = data["controller_direction_bindings"]
		if raw_direction_bindings is Dictionary:
			for slot_id in DIRECTION_BINDING_SLOT_ORDER:
				var legacy_controller_binding := sanitize_input_binding(
					(raw_direction_bindings as Dictionary).get(slot_id, {}),
					{},
					false,
					true
				)
				if str(legacy_controller_binding.get("type", "")) != "joy_button":
					continue
				var controller_slot := str(KEYBOARD_TO_CONTROLLER_DIRECTION_SLOT_MAP.get(slot_id, ""))
				if controller_slot.is_empty():
					continue
				migrated_controller_bindings[controller_slot] = legacy_controller_binding
		data["controller_direction_bindings"] = sanitize_controller_direction_bindings(migrated_controller_bindings)
	data["practice_stats"] = sanitize_practice_stats(
		config.get_value("practice", "practice_stats", {})
	)
	return data


static func save_practice_config(
	selected_strat_ids: Array[String],
	randomize_mode: bool,
	audio_volume: float = DEFAULT_AUDIO_VOLUME,
	show_stratagem_arrows: bool = DEFAULT_SHOW_STRATAGEM_ARROWS,
	require_holding: bool = DEFAULT_REQUIRE_HOLD,
	touch_control_scale: float = DEFAULT_TOUCH_CONTROL_SCALE,
	hold_binding: Dictionary = DEFAULT_HOLD_BINDING,
	direction_bindings: Dictionary = DEFAULT_DIRECTION_BINDINGS,
	controller_hold_binding: Dictionary = DEFAULT_CONTROLLER_HOLD_BINDING,
	controller_direction_bindings: Dictionary = DEFAULT_CONTROLLER_DIRECTION_BINDINGS,
	practice_stats: Dictionary = {}
) -> int:
	var config := ConfigFile.new()
	config.set_value("practice", "selected_strat_ids", selected_strat_ids)
	config.set_value("practice", "randomize_mode", randomize_mode)
	config.set_value("practice", "audio_volume", clampf(audio_volume, 0.0, 1.0))
	config.set_value("practice", "show_stratagem_arrows", show_stratagem_arrows)
	config.set_value("practice", "require_holding", require_holding)
	config.set_value("practice", "touch_control_scale", sanitize_touch_control_scale(touch_control_scale))
	config.set_value("practice", "hold_binding", sanitize_input_binding(hold_binding, get_default_hold_binding(), true, false))
	config.set_value("practice", "direction_bindings", sanitize_direction_bindings(direction_bindings))
	config.set_value("practice", "controller_hold_binding", sanitize_input_binding(controller_hold_binding, get_default_controller_hold_binding(), false, true))
	config.set_value("practice", "controller_direction_bindings", sanitize_controller_direction_bindings(controller_direction_bindings))
	config.set_value("practice", "practice_stats", sanitize_practice_stats(practice_stats))
	var save_error := config.save(PRACTICE_CONFIG_PATH)
	if save_error == OK and OS.has_feature("web"):
		JavaScriptBridge.force_fs_sync()
	return save_error


static func sanitize_touch_control_scale(raw_value: Variant) -> float:
	return clampf(float(raw_value), MIN_TOUCH_CONTROL_SCALE, MAX_TOUCH_CONTROL_SCALE)


static func get_trainable_strat_ids(strat_ids: Array[String]) -> Array[String]:
	var trainable_ids: Array[String] = []
	for strat_id in strat_ids:
		var strat := get_stratagem(strat_id)
		if not strat.is_empty() and not strat["sequence"].is_empty():
			trainable_ids.append(strat_id)
	return trainable_ids


static func scale_volume_db(base_db: float, audio_volume: float) -> float:
	var scaled_linear := db_to_linear(base_db) * clampf(audio_volume, 0.0, 1.0)
	if scaled_linear <= 0.0001:
		return -80.0
	return linear_to_db(scaled_linear)


static func get_default_hold_binding() -> Dictionary:
	return DEFAULT_HOLD_BINDING.duplicate(true)


static func get_default_controller_hold_binding() -> Dictionary:
	return DEFAULT_CONTROLLER_HOLD_BINDING.duplicate(true)


static func get_default_direction_bindings() -> Dictionary:
	return DEFAULT_DIRECTION_BINDINGS.duplicate(true)


static func get_default_controller_direction_bindings() -> Dictionary:
	return DEFAULT_CONTROLLER_DIRECTION_BINDINGS.duplicate(true)


static func sanitize_direction_bindings(raw_value: Variant) -> Dictionary:
	var sanitized := get_default_direction_bindings()
	if raw_value is not Dictionary:
		return sanitized

	var raw_bindings := raw_value as Dictionary
	for slot_id in DIRECTION_BINDING_SLOT_ORDER:
		sanitized[slot_id] = sanitize_input_binding(
			raw_bindings.get(slot_id, sanitized[slot_id]),
			DEFAULT_DIRECTION_BINDINGS[slot_id],
			false,
			false
		)
	return sanitized


static func sanitize_controller_direction_bindings(raw_value: Variant) -> Dictionary:
	var sanitized := get_default_controller_direction_bindings()
	if raw_value is not Dictionary:
		return sanitized

	var raw_bindings := raw_value as Dictionary
	for slot_id in CONTROLLER_DIRECTION_BINDING_SLOT_ORDER:
		sanitized[slot_id] = sanitize_input_binding(
			raw_bindings.get(slot_id, sanitized[slot_id]),
			DEFAULT_CONTROLLER_DIRECTION_BINDINGS[slot_id],
			false,
			true
		)
	return sanitized


static func sanitize_input_binding(raw_value: Variant, fallback_binding: Dictionary, allow_mouse := false, allow_joy := false) -> Dictionary:
	var fallback := fallback_binding.duplicate(true)
	if raw_value is not Dictionary:
		return fallback

	var raw_binding := raw_value as Dictionary
	var binding_type := str(raw_binding.get("type", ""))
	if binding_type == "key":
		var keycode := int(raw_binding.get("keycode", KEY_NONE))
		if keycode != KEY_NONE:
			return {
				"type": "key",
				"keycode": keycode,
			}
	elif binding_type == "joy_button" and allow_joy:
		var joy_button := int(raw_binding.get("button_index", -1))
		if is_supported_joypad_button(joy_button):
			return {
				"type": "joy_button",
				"button_index": joy_button,
			}
	elif binding_type == "mouse_button" and allow_mouse:
		var button_index := int(raw_binding.get("button_index", 0))
		if is_supported_mouse_button(button_index):
			return {
				"type": "mouse_button",
				"button_index": button_index,
			}

	return fallback


static func sanitize_practice_stats(raw_value: Variant) -> Dictionary:
	var sanitized := {}
	if raw_value is not Dictionary:
		return sanitized

	var raw_stats := raw_value as Dictionary
	for raw_key in raw_stats.keys():
		var strat_id := str(raw_key)
		if not has_stratagem(strat_id):
			continue
		if raw_stats[raw_key] is not Dictionary:
			continue

		var raw_entry := raw_stats[raw_key] as Dictionary
		var successful := maxi(0, int(raw_entry.get("successful", 0)))
		var unsuccessful := maxi(0, int(raw_entry.get("unsuccessful", 0)))
		var total_success_time := maxf(0.0, float(raw_entry.get("total_success_time", 0.0)))
		if successful == 0 and unsuccessful == 0 and is_zero_approx(total_success_time):
			continue

		sanitized[strat_id] = {
			"successful": successful,
			"unsuccessful": unsuccessful,
			"total_success_time": total_success_time,
		}

	return sanitized


static func binding_from_key_event(event: InputEventKey) -> Dictionary:
	return {
		"type": "key",
		"keycode": int(event.keycode),
	}


static func binding_from_mouse_button_event(event: InputEventMouseButton) -> Dictionary:
	return {
		"type": "mouse_button",
		"button_index": int(event.button_index),
	}


static func binding_from_joypad_button_event(event: InputEventJoypadButton) -> Dictionary:
	return {
		"type": "joy_button",
		"button_index": int(event.button_index),
	}


static func binding_matches_event(binding: Dictionary, event: InputEvent) -> bool:
	var binding_type := str(binding.get("type", ""))
	if binding_type == "key" and event is InputEventKey:
		return int(binding.get("keycode", KEY_NONE)) == int((event as InputEventKey).keycode)
	if binding_type == "joy_button" and event is InputEventJoypadButton:
		return int(binding.get("button_index", -1)) == int((event as InputEventJoypadButton).button_index)
	if binding_type == "mouse_button" and event is InputEventMouseButton:
		return int(binding.get("button_index", 0)) == int((event as InputEventMouseButton).button_index)
	return false


static func is_binding_pressed(binding: Dictionary, joypad_device := -1) -> bool:
	var binding_type := str(binding.get("type", ""))
	if binding_type == "key":
		return Input.is_key_pressed(int(binding.get("keycode", KEY_NONE)))
	if binding_type == "joy_button":
		var joy_button := int(binding.get("button_index", -1))
		if not is_supported_joypad_button(joy_button):
			return false
		if joypad_device >= 0:
			return Input.is_joy_button_pressed(joypad_device, joy_button)
		for connected_device in Input.get_connected_joypads():
			if Input.is_joy_button_pressed(connected_device, joy_button):
				return true
		return false
	if binding_type == "mouse_button":
		return Input.is_mouse_button_pressed(int(binding.get("button_index", 0)))
	return false


static func get_binding_label(binding: Dictionary) -> String:
	var binding_type := str(binding.get("type", ""))
	if binding_type == "mouse_button":
		return MOUSE_BUTTON_LABELS.get(int(binding.get("button_index", 0)), "Mouse")
	if binding_type == "joy_button":
		var joy_button := int(binding.get("button_index", -1))
		return JOYPAD_BUTTON_LABELS.get(joy_button, "Pad Button %d" % joy_button)

	var keycode := int(binding.get("keycode", KEY_NONE))
	if keycode == KEY_NONE:
		return "Unbound"
	return OS.get_keycode_string(keycode)


static func get_direction_binding_summary(direction_bindings: Dictionary) -> String:
	var primary := get_binding_slot_group_label(direction_bindings, PRIMARY_DIRECTION_BINDING_SLOTS)
	var secondary := get_binding_slot_group_label(direction_bindings, SECONDARY_DIRECTION_BINDING_SLOTS)
	if secondary.is_empty():
		return primary
	if primary == secondary:
		return primary
	return "%s or %s" % [primary, secondary]


static func get_controller_direction_binding_summary(controller_direction_bindings: Dictionary) -> String:
	var labels: Array[String] = []
	var is_default_dpad := true
	for slot_id in CONTROLLER_DIRECTION_BINDING_SLOT_ORDER:
		var binding: Dictionary = controller_direction_bindings.get(slot_id, DEFAULT_CONTROLLER_DIRECTION_BINDINGS[slot_id])
		labels.append(get_binding_label(binding))
		if binding != DEFAULT_CONTROLLER_DIRECTION_BINDINGS[slot_id]:
			is_default_dpad = false
	if is_default_dpad:
		return "D-Pad"
	return "/".join(labels)


static func get_binding_slot_group_label(direction_bindings: Dictionary, slot_ids: Array) -> String:
	var labels: Array[String] = []
	for slot_id in slot_ids:
		labels.append(get_binding_label(direction_bindings.get(slot_id, DEFAULT_DIRECTION_BINDINGS[slot_id])))
	return "/".join(labels)


static func get_arrow_for_direction_event(event: InputEvent, direction_bindings: Dictionary) -> int:
	for slot_id in DIRECTION_BINDING_SLOT_ORDER:
		var binding: Dictionary = direction_bindings.get(slot_id, DEFAULT_DIRECTION_BINDINGS[slot_id])
		if binding_matches_event(binding, event):
			return DIRECTION_BINDING_ARROW_MAP[slot_id]
	return -1


static func get_arrow_for_controller_event(event: InputEvent, controller_direction_bindings: Dictionary) -> int:
	for slot_id in CONTROLLER_DIRECTION_BINDING_SLOT_ORDER:
		var binding: Dictionary = controller_direction_bindings.get(slot_id, DEFAULT_CONTROLLER_DIRECTION_BINDINGS[slot_id])
		if binding_matches_event(binding, event):
			return CONTROLLER_DIRECTION_BINDING_ARROW_MAP[slot_id]

	if event is InputEventJoypadButton:
		return DEFAULT_CONTROLLER_DIRECTION_BUTTONS.get(int((event as InputEventJoypadButton).button_index), -1)
	return -1


static func is_supported_mouse_button(button_index: int) -> bool:
	return MOUSE_BUTTON_LABELS.has(button_index)


static func is_supported_joypad_button(button_index: int) -> bool:
	return button_index >= 0 and button_index < JOY_BUTTON_MAX


static func is_default_controller_hold_pressed(joypad_device := -1) -> bool:
	if joypad_device >= 0:
		return Input.is_joy_button_pressed(joypad_device, DEFAULT_CONTROLLER_HOLD_BUTTON)
	for connected_device in Input.get_connected_joypads():
		if Input.is_joy_button_pressed(connected_device, DEFAULT_CONTROLLER_HOLD_BUTTON):
			return true
	return false


static func is_hold_input_active(binding: Dictionary, controller_binding: Dictionary = DEFAULT_CONTROLLER_HOLD_BINDING, joypad_device := -1) -> bool:
	return is_binding_pressed(binding, joypad_device) or is_binding_pressed(controller_binding, joypad_device)


static func get_default_controller_hold_label() -> String:
	return JOYPAD_BUTTON_LABELS.get(DEFAULT_CONTROLLER_HOLD_BUTTON, "L1 / LB")


static func get_hold_binding_summary(binding: Dictionary, controller_binding: Dictionary = DEFAULT_CONTROLLER_HOLD_BINDING) -> String:
	var configured_label := get_binding_label(binding)
	var controller_label := get_binding_label(controller_binding)
	if configured_label == controller_label:
		return configured_label
	return "%s or %s" % [configured_label, controller_label]
