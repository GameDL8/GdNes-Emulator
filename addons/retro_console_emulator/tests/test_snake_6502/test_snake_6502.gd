extends Control

const GAME_CODE: PackedByteArray = [
#	0x0600  1     2     3     4    5      6     7     8    9     a      b    c     d      e    f
	0x20, 0x06, 0x06, 0x20, 0x38, 0x06, 0x20, 0x0d, 0x06, 0x20, 0x2a, 0x06, 0x60, 0xa9, 0x02, 0x85,
#	0x0610
	0x02, 0xa9, 0x04, 0x85, 0x03, 0xa9, 0x11, 0x85, 0x10, 0xa9, 0x10, 0x85, 0x12, 0xa9, 0x0f, 0x85,
#	0x0620
	0x14, 0xa9, 0x04, 0x85, 0x11, 0x85, 0x13, 0x85, 0x15, 0x60, 0xa5, 0xfe, 0x85, 0x00, 0xa5, 0xfe,
#	0x0630
	0x29, 0x03, 0x18, 0x69, 0x02, 0x85, 0x01, 0x60, 0x20, 0x4d, 0x06, 0x20, 0x8d, 0x06, 0x20, 0xc3,
#	0x0640
	0x06, 0x20, 0x19, 0x07, 0x20, 0x20, 0x07, 0x20, 0x2d, 0x07, 0x4c, 0x38, 0x06, 0xa5, 0xff, 0xc9,
#	0x0650
	0x77, 0xf0, 0x0d, 0xc9, 0x64, 0xf0, 0x14, 0xc9, 0x73, 0xf0, 0x1b, 0xc9, 0x61, 0xf0, 0x22, 0x60,
#	0x0660
	0xa9, 0x04, 0x24, 0x02, 0xd0, 0x26, 0xa9, 0x01, 0x85, 0x02, 0x60, 0xa9, 0x08, 0x24, 0x02, 0xd0,
#	0x0670
	0x1b, 0xa9, 0x02, 0x85, 0x02, 0x60, 0xa9, 0x01, 0x24, 0x02, 0xd0, 0x10, 0xa9, 0x04, 0x85, 0x02,
#	0x0680
	0x60, 0xa9, 0x02, 0x24, 0x02, 0xd0, 0x05, 0xa9, 0x08, 0x85, 0x02, 0x60, 0x60, 0x20, 0x94, 0x06,
#	0x0690
	0x20, 0xa8, 0x06, 0x60, 0xa5, 0x00, 0xc5, 0x10, 0xd0, 0x0d, 0xa5, 0x01, 0xc5, 0x11, 0xd0, 0x07,
#	0x06A0
	0xe6, 0x03, 0xe6, 0x03, 0x20, 0x2a, 0x06, 0x60, 0xa2, 0x02, 0xb5, 0x10, 0xc5, 0x10, 0xd0, 0x06,
#	0x06B0
	0xb5, 0x11, 0xc5, 0x11, 0xf0, 0x09, 0xe8, 0xe8, 0xe4, 0x03, 0xf0, 0x06, 0x4c, 0xaa, 0x06, 0x4c,
#	0x06C0
	0x35, 0x07, 0x60, 0xa6, 0x03, 0xca, 0x8a, 0xb5, 0x10, 0x95, 0x12, 0xca, 0x10, 0xf9, 0xa5, 0x02,
#	0x06D0
	0x4a, 0xb0, 0x09, 0x4a, 0xb0, 0x19, 0x4a, 0xb0, 0x1f, 0x4a, 0xb0, 0x2f, 0xa5, 0x10, 0x38, 0xe9,
#	0x06E0
	0x20, 0x85, 0x10, 0x90, 0x01, 0x60, 0xc6, 0x11, 0xa9, 0x01, 0xc5, 0x11, 0xf0, 0x28, 0x60, 0xe6,
#	0x06F0
	0x10, 0xa9, 0x1f, 0x24, 0x10, 0xf0, 0x1f, 0x60, 0xa5, 0x10, 0x18, 0x69, 0x20, 0x85, 0x10, 0xb0,
#	0x0700
	0x01, 0x60, 0xe6, 0x11, 0xa9, 0x06, 0xc5, 0x11, 0xf0, 0x0c, 0x60, 0xc6, 0x10, 0xa5, 0x10, 0x29,
#	0x0710
	0x1f, 0xc9, 0x1f, 0xf0, 0x01, 0x60, 0x4c, 0x35, 0x07, 0xa0, 0x00, 0xa5, 0xfe, 0x91, 0x00, 0x60,
#	0x0720
	0xa6, 0x03, 0xa9, 0x00, 0x81, 0x10, 0xa2, 0x00, 0xa9, 0x01, 0x81, 0x10, 0x60, 0xa2, 0x00, 0xea,
#	0x0730
	0xea, 0xca, 0xd0, 0xfb, 0x60
]


class Snake6502Cpu extends NesCPU:
	var last_button_pressed: int
	
	const INPUT_MAP: Dictionary = { #[StringName, int]
		&"ui_up": 0x77,
		&"ui_down": 0x73,
		&"ui_left": 0x61,
		&"ui_right": 0x64,
	}
	var _nop_count: int = 0
	const NOP_PER_FRAME: int = 20
	
	func _init() -> void:
		super()
		instructionset[0xEA] = OpCode.new(0xEA, &"NOP", 1, 2, await_frame)
	
	func await_frame():
		_nop_count += 1
		if _nop_count >= NOP_PER_FRAME:
			_nop_count = 0
			await Engine.get_main_loop().physics_frame
	
	func load(p_program: PackedByteArray):
		for i in p_program.size():
			memory.mem_write(0x0600 + i, p_program[i])
		memory.mem_write_16(0xFFFC, 0x0600)

	func _about_to_execute_instruction():
		memory.mem_write(0xFE, randi_range(0x00, 0xFF))
		memory.mem_write(0xFF, last_button_pressed)

	
	
	func byte_to_color(p_byte: int) -> Color:
		if p_byte == 0:
			return Color.BLACK
		match (p_byte % 15):
			0:
				return Color.VIOLET
			1:
				return Color.WHITE
			2, 9:
				return Color.GRAY
			3, 10:
				return Color.RED
			4, 11:
				return Color.GREEN
			5, 12:
				return Color.BLUE
			6, 13:
				return Color.DARK_MAGENTA
			7, 14:
				return Color.YELLOW
			_:
				return Color.CYAN

var cpu := Snake6502Cpu.new()
var apple_observer = cpu.memory.create_memory_observer(0x00, 0x01, MemoryObserver.ObserverFlags.WRITE_8)
var _apple: int = 0
var snake_head_observer = cpu.memory.create_memory_observer(0x10, 0x11, MemoryObserver.ObserverFlags.WRITE_8)
var _snake_head: int = 0
var snake_body_observer = cpu.memory.create_memory_observer(0x12, 0x22, MemoryObserver.ObserverFlags.WRITE_8)
var zero_page_observer = cpu.memory.create_memory_observer(0x00, 0xFD, MemoryObserver.ObserverFlags.WRITE_8)
var screen_observer = cpu.memory.create_memory_observer(0x0200, 0x05FF, MemoryObserver.ObserverFlags.WRITE_8)

func _input(event: InputEvent) -> void:
	for action in cpu.INPUT_MAP.keys():
		if event.is_action(action):
			if event.is_pressed():
				cpu.last_button_pressed = cpu.INPUT_MAP[action]
			else:
				cpu.last_button_pressed = 0
			get_viewport().set_input_as_handled()


func _ready():
#	cpu.screen_changed.connect(render_screen)
	_refresh_screen()
	zero_page_observer.memory_write.connect(_on_zero_page_observer_memory_write)
	apple_observer.memory_write.connect(_on_apple_observer_memory_write)
	snake_head_observer.memory_write.connect(_on_snake_head_observer_memory_write)
	screen_observer.memory_write.connect(_on_screen_observer_memory_write)
	cpu.load_and_run(GAME_CODE)


#func render_screen(screen_buffer: PackedByteArray):
#	var to_print = String()
#	for i in range(screen_buffer.size()):
#		var color_index: int = screen_buffer[i]
#		to_print += "0x%0.2X   0x%0.2X, " % [i + 0x200, color_index]
#		if (i+1) % 32 == 0:
#			to_print += "\n"
#		var pixel: Color = cpu.byte_to_color(color_index)
#		if color_index != 0:
#			print(pixel)
#		var pixel_texture: TextureRect = get_child(i) as TextureRect
#		pixel_texture.self_modulate = pixel
#	print (to_print)

func _refresh_screen():
	var screen_frame: PackedByteArray = cpu.memory.slice(0x0200, 0x05FF)
	for i in range(screen_frame.size()):
		_update_screen_pixel(i, cpu.byte_to_color(screen_frame[i]))

func _on_apple_observer_memory_write(p_address: int, _p_old_value: int, p_new_value: int):
	if p_address == 0x00:
		_apple &= 0xF0
		_apple |= p_new_value
	elif p_address == 0x01:
		_apple &= 0x0F
		_apple |= p_new_value << 8
		var pixel_index = _apple - 0x200
		var x = pixel_index % 32
		var y = pixel_index / 32
		print("Apple is now at location 0x%0.2X (%d, %d)" % [_apple, x, y])

func _on_snake_head_observer_memory_write(p_address: int, _p_old_value: int, p_new_value: int):
	if p_address == 0x10:
		_snake_head &= 0xF0
		_snake_head |= p_new_value
	elif p_address == 0x11:
		_snake_head &= 0x0F
		_snake_head |= p_new_value << 8
		var pixel_index = _snake_head - 0x200
		var x = pixel_index % 32
		var y = pixel_index / 32
		print("Snake Head is now at location 0x%0.2X (%d, %d)" % [_snake_head, x, y])

func _on_zero_page_observer_memory_write(p_address: int, p_old_value: int, p_new_value: int):
#	print("0x%0.2X >> $0x%0.2X >> 0x%0.2X" % [p_old_value, p_address, p_new_value])
	pass

func _on_screen_observer_memory_write(p_address: int, _p_old_value: int, p_new_value: int):
	_update_screen_pixel(p_address - 0x0200, cpu.byte_to_color(p_new_value))

func _update_screen_pixel(p_pixel_index: int, p_color: Color):
	var pixel_texture: TextureRect = get_child(p_pixel_index) as TextureRect
	pixel_texture.self_modulate = p_color
