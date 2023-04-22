class_name NesCPU extends CPU

# chip name is 2A03, based on 6502

enum AddressingMode {
	Immediate,
	ZeroPage,
	ZeroPage_X,
	ZeroPage_Y,
	Absolute,
	Absolute_X,
	Absolute_Y,
	Indirect_X,
	Indirect_Y,
	NoneAddressing
}

var register_a := Register8bits.new()
var register_x := Register8bits.new()
var register_y := Register8bits.new()
var flags := NesRegisterFlags.new()

func _init() -> void:
	registers[&"A"] = register_a
	registers[&"X"] = register_x
	registers[&"Y"] = register_y
	registers[&"P"] = flags
	memory = Memory.new(0xFFFF)
	
	#register instructions
	var instructions: Array[OpCode] = [
		# LDA
		OpCode.new(0xA9, &"LDA", 2, 2, load_register8.bind(register_a, AddressingMode.Immediate)),
		OpCode.new(0xA5, &"LDA", 2, 3, load_register8.bind(register_a, AddressingMode.ZeroPage)),
		OpCode.new(0xAD, &"LDA", 3, 4, load_register8.bind(register_a, AddressingMode.Absolute)),
		OpCode.new(0xB5, &"LDA", 2, 4, load_register8.bind(register_a, AddressingMode.ZeroPage_X)),
		OpCode.new(0xBD, &"LDA", 3, 4, load_register8.bind(register_a, AddressingMode.Absolute_X)),
		OpCode.new(0xB9, &"LDA", 3, 4, load_register8.bind(register_a, AddressingMode.Absolute_Y)),
		OpCode.new(0xA1, &"LDA", 2, 6, load_register8.bind(register_a, AddressingMode.Indirect_X)),
		OpCode.new(0xB1, &"LDA", 2, 5, load_register8.bind(register_a, AddressingMode.Indirect_Y)),
		# STA
		OpCode.new(0x85, &"STA", 2, 3, store_from_register.bind(register_a, AddressingMode.ZeroPage)),
		OpCode.new(0x8D, &"STA", 3, 4, store_from_register.bind(register_a, AddressingMode.Absolute)),
		OpCode.new(0x95, &"STA", 2, 4, store_from_register.bind(register_a, AddressingMode.ZeroPage_X)),
		OpCode.new(0x9D, &"STA", 3, 5, store_from_register.bind(register_a, AddressingMode.Absolute_X)),
		OpCode.new(0x99, &"STA", 3, 5, store_from_register.bind(register_a, AddressingMode.Absolute_Y)),
		OpCode.new(0x81, &"STA", 2, 6, store_from_register.bind(register_a, AddressingMode.Indirect_X)),
		OpCode.new(0x91, &"STA", 2, 6, store_from_register.bind(register_a, AddressingMode.Indirect_Y)),
		# STX
		OpCode.new(0x86, &"STX", 2, 3, store_from_register.bind(register_x, AddressingMode.ZeroPage)),
		OpCode.new(0x8E, &"STX", 3, 4, store_from_register.bind(register_x, AddressingMode.Absolute)),
		OpCode.new(0x96, &"STX", 2, 4, store_from_register.bind(register_x, AddressingMode.ZeroPage_Y)),
		# STY
		OpCode.new(0x84, &"STY", 2, 3, store_from_register.bind(register_y, AddressingMode.ZeroPage)),
		OpCode.new(0x8C, &"STY", 3, 4, store_from_register.bind(register_y, AddressingMode.Absolute)),
		OpCode.new(0x94, &"STY", 2, 4, store_from_register.bind(register_y, AddressingMode.ZeroPage_X)),
		# TAX
		OpCode.new(0xAA, &"TAX", 1, 2, transfer_register_from_to.bind(register_a, register_x)),
		# TAY
		OpCode.new(0xA8, &"TAY", 1, 2, transfer_register_from_to.bind(register_a, register_y)),
		# INX
		OpCode.new(0xE8, &"INX", 1, 2, increment_register.bind(register_x)),
		# INY
		OpCode.new(0xC8, &"INY", 1, 2, increment_register.bind(register_y)),
	]
	
	for instruction in instructions:
		instructionset[instruction.code] = instruction

func reset():
	is_running = false
	register_a.value = 0
	register_x.value = 0
	register_y.value = 0
	flags.value = 0
	program_counter.value = memory.mem_read_16(0xFFFC)

func load(p_program: PackedByteArray):
	for i in p_program.size():
		memory.mem_write(0x8000 + i, p_program[i])
	memory.mem_write_16(0xFFFC, 0x8000)

## VIRTUAL: This method runs the program loaded into the CPU's memory.
func run():
	assert(memory != null, "Memory not initialized")
	is_running = true
	while is_running:
		var opcode = memory.mem_read(program_counter.value)
		program_counter.value += 1
		
		var instruction: OpCode = instructionset.get(opcode, null)
		assert(instruction, "Unknown instruction with code %d" % opcode)
		assert(instruction.callback.is_valid(), "Invalid callable for opcode %d" % opcode)
		instruction.callback.call()
		program_counter.value += (instruction.size - 1)


func get_operand_address(p_mode: int) -> int:
	assert(p_mode in AddressingMode.values(), "Unknown address mode")
	match p_mode as AddressingMode:
		AddressingMode.Immediate:
			#LDA  #$0x10
			#0xA9 0x10
			return program_counter.value
		AddressingMode.ZeroPage:
			#LDA  $0x10
			#0xA5 0x10
			return memory.mem_read(program_counter.value)
		AddressingMode.Absolute:
			#LDA  $0x1090
			#0xAD 0x90 0x10 ; bytes are inverted because of little endianess
			return memory.mem_read_16(program_counter.value)
		AddressingMode.ZeroPage_X:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_x.value) % 0xFF
			return addr
		AddressingMode.ZeroPage_Y:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_y.value) % 0xFF
			return addr
		AddressingMode.Absolute_X:
			var base: int = memory.mem_read_16(self.program_counter.value)
			var addr: int = (base + register_x.value) % 0xFFFF
			return addr
		AddressingMode.Absolute_Y:
			var base: int = memory.mem_read_16(self.program_counter.value)
			var addr: int = (base + register_y.value) % 0xFFFF
			return addr
		AddressingMode.Indirect_X:
			var base = memory.mem_read(self.program_counter.value)
			var ptr: int = (base + self.register_x.value) % 0xFF
			var ptr1 = (ptr + 1) % 0xFF
			var lo = memory.mem_read(ptr)
			var hi = memory.mem_read(ptr1)
			return (hi << 8) | (lo)
		AddressingMode.Indirect_Y:
			var base: int = memory.mem_read(self.program_counter.value);
			var lo: int = memory.mem_read(base);
			var hi: int = memory.mem_read((base + 1) % 0xFF);
			var deref_base: int = (hi << 8) | (lo);
			var deref: int = (deref_base + self.register_y.value) % 0xFFFF
			return deref
		_:
			assert(false, "Adressing mode not supported!")
			return 0x00


#LDA
func load_register8(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	p_register.value = value
	update_z_n_flags(value)


#STA
func store_from_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr = self.get_operand_address(p_addressing_mode)
	memory.mem_write(addr, p_register.value)


#TAX
func transfer_register_from_to(p_from: Register8bits, p_to: Register8bits):
	p_to.value = p_from.value
	update_z_n_flags(p_from.value)

#INC
func increment_register(p_register: Register8bits):
	var val: int = p_register.value + 1
	p_register.value = val & 0b11111111
	update_z_n_flags(p_register.value)

func update_z_n_flags(p_value: int):
	flags.Z.value = (p_value == 0)
	flags.N.value = (p_value & 0b10000000)


class NesRegisterFlags extends CPU.RegisterFlags:
	var C = BitFlag.new(self, 0)
	var Z = BitFlag.new(self, 1)
	var I = BitFlag.new(self, 2)
	var D = BitFlag.new(self, 3)
	var B = BitFlag.new(self, 4)
	var V = BitFlag.new(self, 6)
	var N = BitFlag.new(self, 7)
