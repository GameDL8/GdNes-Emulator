class_name CPU6502 extends CPU

# chip name is 2A03, based on 6502

enum AddressingMode {
	Immediate,
	ZeroPage,
	ZeroPage_X,
	ZeroPage_Y,
	Absolute,
	Absolute_X,
	Absolute_Y,
	Indirect,
	Indirect_X,
	Indirect_Y,
	NoneAddressing
}


const STACK: int       = 0x0100
const STACK_RESET: int = 0xfd


var register_a := Register8bits.new(&"A")
var register_x := Register8bits.new(&"X")
var register_y := Register8bits.new(&"Y")
var flags := NesRegisterFlags.new(&"P")
var stack_pointer: int = STACK_RESET

func _init() -> void:
	registers[register_a.name] = register_a
	registers[register_x.name] = register_x
	registers[register_y.name] = register_y
	registers[flags.name] = flags
	memory = NesMemory.new()
	
	#register instructions
	var instructions: Array[OpCode] = [
		# BRK on NES system forces an interrupt
		OpCode.new(0x00, &"BRK", 1, 1, nes_break),
		# ADC - Add with Carry
		OpCode.new(0x69, &"ADC", 2, 2, add_with_carry_to_register, register_a.name, AddressingMode.Immediate),
		OpCode.new(0x65, &"ADC", 2, 3, add_with_carry_to_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x75, &"ADC", 2, 4, add_with_carry_to_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x6D, &"ADC", 3, 4, add_with_carry_to_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x7D, &"ADC", 3, 4, add_with_carry_to_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x79, &"ADC", 3, 4, add_with_carry_to_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x61, &"ADC", 2, 6, add_with_carry_to_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x71, &"ADC", 2, 5, add_with_carry_to_register, register_a.name, AddressingMode.Indirect_Y),
		# AND
		OpCode.new(0x29, &"AND", 2, 2, bitwise_and_with_register, register_a.name, AddressingMode.Immediate),
		OpCode.new(0x25, &"AND", 2, 3, bitwise_and_with_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x35, &"AND", 2, 4, bitwise_and_with_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x2D, &"AND", 3, 4, bitwise_and_with_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x3D, &"AND", 3, 4, bitwise_and_with_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x39, &"AND", 3, 4, bitwise_and_with_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x21, &"AND", 2, 6, bitwise_and_with_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x31, &"AND", 2, 5, bitwise_and_with_register, register_a.name, AddressingMode.Indirect_Y),
		# ASL
		OpCode.new(0x0A, &"ASL", 1, 2, arithmetic_shift_left_register, register_a.name),
		OpCode.new(0x06, &"ASL", 2, 5, arithmetic_shift_left_memory, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x16, &"ASL", 2, 6, arithmetic_shift_left_memory, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x0E, &"ASL", 3, 6, arithmetic_shift_left_memory, StringName(), AddressingMode.Absolute),
		OpCode.new(0x1E, &"ASL", 3, 7, arithmetic_shift_left_memory, StringName(), AddressingMode.Absolute_X),
		# BCC - BCS
		OpCode.new(0x90, &"BCC", 2, 2, branch_if_flag_matches.bind(flags.C, false)),
		OpCode.new(0xB0, &"BCS", 2, 2, branch_if_flag_matches.bind(flags.C, true)),
		# BEQ - BNE
		OpCode.new(0xF0, &"BEQ", 2, 2, branch_if_flag_matches.bind(flags.Z, true)),
		OpCode.new(0xD0, &"BNE", 2, 2, branch_if_flag_matches.bind(flags.Z, false)),
		# BIT
		OpCode.new(0x24, &"BIT", 2, 3, bit_test_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x2C, &"BIT", 3, 4, bit_test_register, register_a.name, AddressingMode.Absolute),
		# BMI - BPL
		OpCode.new(0x30, &"BMI", 2, 2, branch_if_flag_matches.bind(flags.N, true)),
		OpCode.new(0x10, &"BPL", 2, 2, branch_if_flag_matches.bind(flags.N, false)),
		# BVC - BVS
		OpCode.new(0x50, &"BVC", 2, 2, branch_if_flag_matches.bind(flags.V, false)),
		OpCode.new(0x70, &"BVS", 2, 2, branch_if_flag_matches.bind(flags.V, true)),
		# CLC - CLD - CLI - CLV
		OpCode.new(0x18, &"CLC", 1, 2, set_flag.bind(flags.C, false)),
		OpCode.new(0xD8, &"CLD", 1, 2, set_flag.bind(flags.D, false)),
		OpCode.new(0x58, &"CLI", 1, 2, set_flag.bind(flags.I, false)),
		OpCode.new(0xB8, &"CLV", 1, 2, set_flag.bind(flags.V, false)),
		# SEC - SED - SEI
		OpCode.new(0x38, &"SEC", 1, 2, set_flag.bind(flags.C, true)),
		OpCode.new(0xF8, &"SED", 1, 2, set_flag.bind(flags.D, true)),
		OpCode.new(0x78, &"SEI", 1, 2, set_flag.bind(flags.I, true)),
		# CMP
		OpCode.new(0xC9, &"CMP", 2, 2, compare_register, register_a.name, AddressingMode.Immediate),
		OpCode.new(0xC5, &"CMP", 2, 3, compare_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0xD5, &"CMP", 2, 4, compare_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0xCD, &"CMP", 3, 4, compare_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0xDD, &"CMP", 3, 4, compare_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0xD9, &"CMP", 3, 4, compare_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0xC1, &"CMP", 2, 6, compare_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0xD1, &"CMP", 2, 5, compare_register, register_a.name, AddressingMode.Indirect_Y),
		# CPX
		OpCode.new(0xE0, &"CPX", 2, 2, compare_register, register_x.name, AddressingMode.Immediate),
		OpCode.new(0xE4, &"CPX", 2, 3, compare_register, register_x.name, AddressingMode.ZeroPage),
		OpCode.new(0xEC, &"CPX", 3, 4, compare_register, register_x.name, AddressingMode.Absolute),
		# CPY
		OpCode.new(0xC0, &"CPY", 2, 2, compare_register, register_y.name, AddressingMode.Immediate),
		OpCode.new(0xC4, &"CPY", 2, 3, compare_register, register_y.name, AddressingMode.ZeroPage),
		OpCode.new(0xCC, &"CPY", 3, 4, compare_register, register_y.name, AddressingMode.Absolute),
		# LDA
		OpCode.new(0xA9, &"LDA", 2, 2, load_register8, register_a.name, AddressingMode.Immediate),
		OpCode.new(0xA5, &"LDA", 2, 3, load_register8, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0xAD, &"LDA", 3, 4, load_register8, register_a.name, AddressingMode.Absolute),
		OpCode.new(0xB5, &"LDA", 2, 4, load_register8, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0xBD, &"LDA", 3, 4, load_register8, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0xB9, &"LDA", 3, 4, load_register8, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0xA1, &"LDA", 2, 6, load_register8, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0xB1, &"LDA", 2, 5, load_register8, register_a.name, AddressingMode.Indirect_Y),
		# LDX
		OpCode.new(0xA2, &"LDX", 2, 2, load_register8, register_x.name, AddressingMode.Immediate),
		OpCode.new(0xA6, &"LDX", 2, 3, load_register8, register_x.name, AddressingMode.ZeroPage),
		OpCode.new(0xB6, &"LDX", 2, 4, load_register8, register_x.name, AddressingMode.ZeroPage_Y),
		OpCode.new(0xAE, &"LDX", 3, 4, load_register8, register_x.name, AddressingMode.Absolute),
		OpCode.new(0xBE, &"LDX", 3, 4, load_register8, register_x.name, AddressingMode.Absolute_Y),
		# LDY
		OpCode.new(0xA0, &"LDY", 2, 2, load_register8, register_y.name, AddressingMode.Immediate),
		OpCode.new(0xA4, &"LDY", 2, 3, load_register8, register_y.name, AddressingMode.ZeroPage),
		OpCode.new(0xB4, &"LDY", 2, 4, load_register8, register_y.name, AddressingMode.ZeroPage_X),
		OpCode.new(0xAC, &"LDY", 3, 4, load_register8, register_y.name, AddressingMode.Absolute),
		OpCode.new(0xBC, &"LDY", 3, 4, load_register8, register_y.name, AddressingMode.Absolute_X),
		# LSR
		OpCode.new(0x4A, &"LSR", 1, 2, logical_shift_right_register, register_a.name),
		OpCode.new(0x46, &"LSR", 2, 5, logical_shift_right_memory, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x56, &"LSR", 2, 6, logical_shift_right_memory, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x4E, &"LSR", 3, 6, logical_shift_right_memory, StringName(), AddressingMode.Absolute),
		OpCode.new(0x5E, &"LSR", 3, 7, logical_shift_right_memory, StringName(), AddressingMode.Absolute_X),
		# NOP
		OpCode.new(0xEA, &"NOP", 1, 2, no_operation),
		# ORA
		OpCode.new(0x09, &"ORA", 2, 2, inclusive_or_with_register, register_a.name, AddressingMode.Immediate),
		OpCode.new(0x05, &"ORA", 2, 3, inclusive_or_with_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x15, &"ORA", 2, 4, inclusive_or_with_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x0D, &"ORA", 3, 4, inclusive_or_with_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x1D, &"ORA", 3, 4, inclusive_or_with_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x19, &"ORA", 3, 4, inclusive_or_with_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x01, &"ORA", 2, 6, inclusive_or_with_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x11, &"ORA", 2, 5, inclusive_or_with_register, register_a.name, AddressingMode.Indirect_Y),
		# PHA
		OpCode.new(0x48, &"PHA", 1, 3, push_register_to_stack, register_a.name),
		# PHP
		OpCode.new(0x08, &"PHP", 1, 3, push_register_to_stack.bind(flags)),
		# PLA
		OpCode.new(0x68, &"PLA", 1, 4, pull_register_from_stack, register_a.name),
		# PLP
		OpCode.new(0x28, &"PLP", 1, 4, pull_register_from_stack.bind(flags)),
		# ROL
		OpCode.new(0x2A, &"ROL", 1, 2, rotate_left_register, register_a.name),
		OpCode.new(0x26, &"ROL", 2, 5, rotate_left_memory, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x36, &"ROL", 2, 6, rotate_left_memory, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x2E, &"ROL", 3, 6, rotate_left_memory, StringName(), AddressingMode.Absolute),
		OpCode.new(0x3E, &"ROL", 3, 7, rotate_left_memory, StringName(), AddressingMode.Absolute_X),
		# ROL
		OpCode.new(0x6A, &"ROR", 1, 2, rotate_right_register, register_a.name),
		OpCode.new(0x66, &"ROR", 2, 5, rotate_right_memory, StringName(), AddressingMode.ZeroPage),
		OpCode.new(0x76, &"ROR", 2, 6, rotate_right_memory, StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0x6E, &"ROR", 3, 6, rotate_right_memory, StringName(), AddressingMode.Absolute),
		OpCode.new(0x7E, &"ROR", 3, 7, rotate_right_memory, StringName(), AddressingMode.Absolute_X),
		# RTI
		OpCode.new(0x40, &"RTI", 1, 6, return_from_interrupt),
		# RTS
		OpCode.new(0x60, &"RTS", 1, 6, return_from_subroutine),
		# SBC
		OpCode.new(0xE9, &"SBC", 2, 2, substract_with_carry_to_register, register_a.name, AddressingMode.Immediate),
		OpCode.new(0xE5, &"SBC", 2, 3, substract_with_carry_to_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0xF5, &"SBC", 2, 4, substract_with_carry_to_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0xED, &"SBC", 3, 4, substract_with_carry_to_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0xFD, &"SBC", 3, 4, substract_with_carry_to_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0xF9, &"SBC", 3, 4, substract_with_carry_to_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0xE1, &"SBC", 2, 6, substract_with_carry_to_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0xF1, &"SBC", 2, 5, substract_with_carry_to_register, register_a.name, AddressingMode.Indirect_Y),
		
		# STA
		OpCode.new(0x85, &"STA", 2, 3, store_from_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x8D, &"STA", 3, 4, store_from_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x95, &"STA", 2, 4, store_from_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x9D, &"STA", 3, 5, store_from_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x99, &"STA", 3, 5, store_from_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x81, &"STA", 2, 6, store_from_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x91, &"STA", 2, 6, store_from_register, register_a.name, AddressingMode.Indirect_Y),
		# STX
		OpCode.new(0x86, &"STX", 2, 3, store_from_register, register_x.name, AddressingMode.ZeroPage),
		OpCode.new(0x8E, &"STX", 3, 4, store_from_register, register_x.name, AddressingMode.Absolute),
		OpCode.new(0x96, &"STX", 2, 4, store_from_register, register_x.name, AddressingMode.ZeroPage_Y),
		# STY
		OpCode.new(0x84, &"STY", 2, 3, store_from_register, register_y.name, AddressingMode.ZeroPage),
		OpCode.new(0x8C, &"STY", 3, 4, store_from_register, register_y.name, AddressingMode.Absolute),
		OpCode.new(0x94, &"STY", 2, 4, store_from_register, register_y.name, AddressingMode.ZeroPage_X),
		# TAX
		OpCode.new(0xAA, &"TAX", 1, 2, transfer_register_from_to.bind(register_a, register_x)),
		# TAY
		OpCode.new(0xA8, &"TAY", 1, 2, transfer_register_from_to.bind(register_a, register_y)),
		# TSX
		OpCode.new(0xBA, &"TSX", 1, 2, transfer_stack_pointer_to_register.bind(register_x)),
		# TXA
		OpCode.new(0x8A, &"TXA", 1, 2, transfer_register_from_to.bind(register_x, register_a)),
		# TXS
		OpCode.new(0x9A, &"TXS", 1, 2, transfer_register_to_stack_pointer.bind(register_x)),
		# TYA
		OpCode.new(0x98, &"TYA", 1, 2, transfer_register_from_to.bind(register_y, register_a)),
		# INC
		OpCode.new(0xe6, &"INC", 2, 5, increment_memory.bind(1), StringName(), AddressingMode.ZeroPage),
		OpCode.new(0xf6, &"INC", 2, 6, increment_memory.bind(1), StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xee, &"INC", 3, 6, increment_memory.bind(1), StringName(), AddressingMode.Absolute),
		OpCode.new(0xfe, &"INC", 3, 7, increment_memory.bind(1), StringName(), AddressingMode.Absolute_X),
		# DEC
		OpCode.new(0xc6, &"DEC", 2, 5, increment_memory.bind(-1), StringName(), AddressingMode.ZeroPage),
		OpCode.new(0xd6, &"DEC", 2, 6, increment_memory.bind(-1), StringName(), AddressingMode.ZeroPage_X),
		OpCode.new(0xce, &"DEC", 3, 6, increment_memory.bind(-1), StringName(), AddressingMode.Absolute),
		OpCode.new(0xde, &"DEC", 3, 7, increment_memory.bind(-1), StringName(), AddressingMode.Absolute_X),
		# INX
		OpCode.new(0xE8, &"INX", 1, 2, increment_register.bind(1), register_x.name),
		# INY
		OpCode.new(0xC8, &"INY", 1, 2, increment_register.bind(1), register_y.name),
		# JMP
		OpCode.new(0x4C, &"JMP", 3, 3, jump, StringName(), AddressingMode.Absolute),
		OpCode.new(0x6C, &"JMP", 3, 5, jump, StringName(), AddressingMode.Indirect),
		# JSR
		OpCode.new(0x20, &"JSR", 3, 6, jump_to_subrountine, StringName(), AddressingMode.Absolute),
		# DEX
		OpCode.new(0xCA, &"DEX", 1, 2, increment_register.bind(-1), register_x.name),
		# DEY
		OpCode.new(0x88, &"DEY", 1, 2, increment_register.bind(-1), register_y.name),
		# EOR
		OpCode.new(0x49, &"EOR", 2, 2, exclusive_or_with_register, register_a.name, AddressingMode.Immediate),
		OpCode.new(0x45, &"EOR", 2, 3, exclusive_or_with_register, register_a.name, AddressingMode.ZeroPage),
		OpCode.new(0x55, &"EOR", 2, 4, exclusive_or_with_register, register_a.name, AddressingMode.ZeroPage_X),
		OpCode.new(0x4D, &"EOR", 3, 4, exclusive_or_with_register, register_a.name, AddressingMode.Absolute),
		OpCode.new(0x5D, &"EOR", 3, 4, exclusive_or_with_register, register_a.name, AddressingMode.Absolute_X),
		OpCode.new(0x59, &"EOR", 3, 4, exclusive_or_with_register, register_a.name, AddressingMode.Absolute_Y),
		OpCode.new(0x41, &"EOR", 2, 6, exclusive_or_with_register, register_a.name, AddressingMode.Indirect_X),
		OpCode.new(0x51, &"EOR", 2, 5, exclusive_or_with_register, register_a.name, AddressingMode.Indirect_Y),
	]
	
	for instruction in instructions:
		instructionset[instruction.code] = instruction
		var bind_args: Array
		if instruction.addresing_mode != -1:
			var cb : Callable = instruction.callback.bind(instruction.addresing_mode)
			instruction.callback = cb
		if instruction.register != StringName():
			if registers.has(instruction.register):
				instruction.callback = instruction.callback.bind(registers[instruction.register])
			elif flags.bit_flags.has(instruction.register):
				instruction.callback = instruction.callback.bind(flags.bit_flags[instruction.register])
			else:
				assert(false, "Unknown register name '%s'" % instruction.register)

func reset():
	is_running = false
	register_a.value = 0
	register_x.value = 0
	register_y.value = 0
	flags.value = 0b100100
	stack_pointer = STACK_RESET
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
		await _about_to_execute_instruction()
		var opcode: int = memory.mem_read(program_counter.value)
		program_counter.value += 1
		var current_pc = program_counter.value
		
		var instruction: OpCode = instructionset.get(opcode, null)
		assert(instruction, "Unknown instruction with code %d" % opcode)
		assert(instruction.callback.is_valid(), "Invalid callable for opcode %d" % opcode)
		await instruction.callback.call()
		if current_pc == program_counter.value:
			# There was not a jump
			program_counter.value += (instruction.size - 1)


# VIRTUAL OVERRIDE
func _about_to_execute_instruction():
	pass


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
			#0xAD 0x90 0x10  bytes are inverted because of little endianess
			return memory.mem_read_16(program_counter.value)
		AddressingMode.ZeroPage_X:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_x.value)
			if addr > 0xFF:
				addr -= 0x0100
			return addr
		AddressingMode.ZeroPage_Y:
			var pos: int = memory.mem_read(self.program_counter.value)
			var addr: int = (pos + register_y.value)
			if addr > 0xFF:
				addr -= 0x0100
			return addr
		AddressingMode.Absolute_X:
			var base: int = memory.mem_read_16(self.program_counter.value)
			var addr: int = (base + register_x.value)
			if addr > 0xFFFF:
				addr -= 0x10000
			return addr
		AddressingMode.Absolute_Y:
			var base: int = memory.mem_read_16(self.program_counter.value)
			var addr: int = (base + register_y.value)
			if addr > 0xFFFF:
				addr -= 0x10000
			return addr
		AddressingMode.Indirect:
			var addr_addr: int = memory.mem_read_16(program_counter.value)
			var addr: int = memory.mem_read_16(addr_addr)
			var addr1 = (addr + 1)
			if addr1 > 0xFF:
				addr1 -= 0x0100
			var lo = memory.mem_read(addr)
			var hi = memory.mem_read(addr1)
			return (hi << 8) | (lo)
		AddressingMode.Indirect_X:
			var base = memory.mem_read(self.program_counter.value)
			var ptr: int = (base + self.register_x.value)
			if ptr > 0xFF:
				ptr -= 0x0100
			var ptr1 = (ptr + 1)
			if ptr1 > 0xFF:
				ptr1 -= 0x0100
			var lo = memory.mem_read(ptr)
			var hi = memory.mem_read(ptr1)
			return (hi << 8) | (lo)
		AddressingMode.Indirect_Y:
			var base: int = memory.mem_read(self.program_counter.value)
			var lo: int = memory.mem_read(base)
			base += 1
			if base > 0xFF:
				base -= 0x0100
			var hi: int = memory.mem_read(base)
			var deref_base: int = (hi << 8) | (lo)
			var deref: int = (deref_base + self.register_y.value)
			if deref > 0xFFFF:
				deref -= 0x10000
			return deref
		_:
			assert(false, "Adressing mode not supported!")
			return 0x00


# BRK
func nes_break():
	flags.B.value = true
	flags.B2.value = true
	stack_push_16(program_counter.value)
	stack_push_8(flags.value)
	is_running = false


# ADC - Add with Carry
func add_with_carry_to_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var previous: int = p_register.value
	var result: int = p_register.value + value
	if flags.C.value == true:
		result += 1
	p_register.value = result & 0xFF
	update_c_flag(result)
	update_v_flag(previous, value, result)
	update_z_n_flags(p_register.value)


#AND
func bitwise_and_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	p_register.value &= value
	update_z_n_flags(p_register.value)


#ASL
func arithmetic_shift_left_register(p_register: Register8bits):
	var value: int = p_register.value
	var shifted: int = value << 1
	var result: int = shifted & 0xFF
	p_register.value = result
	update_c_flag(shifted)
	update_z_n_flags(result)


func arithmetic_shift_left_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var shifted: int = value << 1
	var result: int = shifted & 0xFF
	memory.mem_write(addr, result)
	update_c_flag(shifted)
	update_z_n_flags(result)

#LSR
func logical_shift_right_register(p_register: Register8bits):
	var value: int = p_register.value
	flags.C.value = value & 0x01
	var shifted: int = value >> 1
	p_register.value = shifted
	update_z_n_flags(shifted)


func logical_shift_right_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	flags.C.value = value & 0x01
	var shifted: int = value >> 1
	memory.mem_write(addr, shifted)
	update_z_n_flags(shifted)


#NOP
func no_operation():
	pass


#ORA
func inclusive_or_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var or_result: int = p_register.value | value
	p_register.value = or_result
	update_z_n_flags(or_result)


#PHA - PHP
# p_register can be Register8bits or NesRegisterFlags
func push_register_to_stack(p_register: Variant):
	if p_register is NesRegisterFlags:
		flags.B.value = true
		flags.B2.value = true
	stack_push_8(p_register.value)
	if p_register is NesRegisterFlags:
		flags.B.value = false


#PLA - PLP
# p_register can be Register8bits or NesRegisterFlags
func pull_register_from_stack(p_register: Variant):
	p_register.value = stack_pop_8()
	if p_register == flags:
		flags.B.value = false
		flags.B2.value = true
	else:
		update_z_n_flags(p_register.value)


#ROL
func rotate_left_register(p_register: Register8bits):
	var old_value = p_register.value
	var value: int = old_value << 1
	value |= 0x01 if flags.C.value else 0x00
	flags.C.value = 0b10000000 & old_value
	value &= 0xFF
	p_register.value = value
	update_z_n_flags(value)
	if flags.value == 0xA5:
		breakpoint


func rotate_left_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var old_value = memory.mem_read(addr)
	var value: int = old_value << 1
	value |= 0x01 if flags.C.value else 0x00
	flags.C.value = 0b10000000 & old_value
	value &= 0xFF
	memory.mem_write(addr, value)
	update_z_n_flags(value)


#ROR
func rotate_right_register(p_register: Register8bits):
	var value: int = p_register.value
	value |= 0b100000000 if flags.C.value else 0x00
	flags.C.value = true if value & 0x01 else false
	value = value >> 1
	p_register.value = value
	update_z_n_flags(value)


func rotate_right_memory(p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	value |= 0b100000000 if flags.C.value else 0x00
	flags.C.value = true if value & 0x01 else false
	value = value >> 1
	memory.mem_write(addr, value)
	update_z_n_flags(value)


#RTI
func return_from_interrupt():
	flags.value = stack_pop_8()
	flags.B.value = false
	flags.B2.value = true
	program_counter.value = stack_pop_16()
	is_running = true


#RTS
func return_from_subroutine():
	program_counter.value = stack_pop_16() + 1

#SBC
func substract_with_carry_to_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var previous = p_register.value
	var negative = ((~value) & 0xFF)
	var result: int = p_register.value + negative
	if flags.C.value == true:
		result += 1
	p_register.value = result & 0xFF
	update_c_flag(result)
	update_v_flag(previous, negative, result)
	update_z_n_flags(p_register.value)

#BCC - BCS
func branch_if_flag_matches(p_flag: BitFlag, p_is_set: bool):
	if p_flag.value == p_is_set:
		var addr: int = program_counter.value
		var jump: int = memory.mem_read(addr)
		if jump & 0b10000000:
			jump = -(((~jump) & 0b01111111)+1)
		jump += 1
		program_counter.value += jump


#BIT
func bit_test_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value & p_register.value
	flags.Z.value = (result == 0)
	flags.N.value = value & (1 << 7)
	flags.V.value = value & (1 << 6)


#CLC - CLD - CLI - CLV
#SEC - SED - SEI - SEV
func set_flag(p_flag: BitFlag, p_is_set: bool):
	p_flag.value = p_is_set


#CMP - CPX - CPY
func compare_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr: int = get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = p_register.value - value
	if result < 0:
		result += 0xFF + 1
	set_flag(flags.C, p_register.value >= value)
	update_z_n_flags(result)


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


#TSX
func transfer_stack_pointer_to_register(p_register: Register8bits):
	p_register.value = stack_pointer
	update_z_n_flags(stack_pointer)


#TXS
func transfer_register_to_stack_pointer(p_register: Register8bits):
	stack_pointer = p_register.value


#INC
func increment_memory(p_addressing_mode: AddressingMode, p_by_amount: int):
	var addr = self.get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value + p_by_amount
	if result > 0xFF:
		result -= 0x0100
	elif result < 0x00:
		result += 0x0100
	memory.mem_write(addr, result)
	update_z_n_flags(result)

#INX - INY - DEX - DEY
func increment_register(p_register: Register8bits, p_by_amount: int):
	var val: int = p_register.value + p_by_amount
	if val > 0xFF:
		val -= 0x0100
	elif val < 0x00:
		val += 0x0100
	p_register.value = val
	update_z_n_flags(p_register.value)


#JMP
func jump(p_addressing_mode: AddressingMode):
	match p_addressing_mode:
		AddressingMode.Absolute:
			var addr: int = memory.mem_read_16(program_counter.value)
			program_counter.value = addr
		AddressingMode.Indirect:
			var addr_addr: int = memory.mem_read_16(program_counter.value)
			var addr: int = memory.mem_read_16(addr_addr)
			# 6502 bug mode with with page boundary:
			# if address $3000 contains $40, $30FF contains $80, and $3100 contains $50,
			# the result of JMP ($30FF) will be a transfer of control to $4080 rather than $5080 as you intended
			# i.e. the 6502 took the low byte of the address from $30FF and the high byte from $3000
			if addr_addr & 0x00FF == 0x00FF:
				var lo: int = memory.mem_read(addr_addr)
				var hi: int = memory.mem_read(addr_addr & 0xFF00)
				addr = hi << 8 | lo
			program_counter.value = addr
		_:
			assert(false, "Invalid addressing mode %d for Jump instruction" % p_addressing_mode)


#JSR
func jump_to_subrountine(p_addressing_mode: AddressingMode):
	assert(p_addressing_mode == AddressingMode.Absolute, "Invalid adressing mode %d for jump to subrutine instruction" % p_addressing_mode)
	stack_push_16(program_counter.value + 2 - 1)
	var addr: int = memory.mem_read_16(program_counter.value)
	program_counter.value = addr


#EOR
func exclusive_or_with_register(p_register: Register8bits, p_addressing_mode: AddressingMode):
	var addr = self.get_operand_address(p_addressing_mode)
	var value: int = memory.mem_read(addr)
	var result: int = value ^ p_register.value
	p_register.value = result
	update_z_n_flags(result)


func update_c_flag(p_value: int):
	var did_carry: bool = p_value & 0xFF00
	flags.C.value = did_carry


func update_v_flag(p_a: int, p_b: int, p_result: int):
	var sign_bit: int = 0b10000000
	if (p_a ^ p_result) & (p_b ^ p_result) & sign_bit != 0:
		flags.V.value = true
	else:
		flags.V.value = false


func update_z_n_flags(p_value: int):
	flags.Z.value = (p_value == 0)
	flags.N.value = (p_value & 0b10000000)



func stack_push_8(p_8bit_address: int):
	memory.mem_write(_get_stack_address(), p_8bit_address)
	_on_stack_push()


func stack_pop_8() -> int:
	_on_stack_pop()
	var value: int = memory.mem_read(_get_stack_address())
	return value


func stack_push_16(p_16bit_address: int):
	var hi: int = p_16bit_address >> 8
	var lo: int = p_16bit_address & 0xFF
	stack_push_8(hi)
	stack_push_8(lo)


func stack_pop_16() -> int:
	var lo: int = stack_pop_8()
	var hi: int = stack_pop_8()
	return (hi << 8) | lo


func _get_stack_address() -> int:
	return STACK + stack_pointer


func _on_stack_push():
	stack_pointer -= 1
	if stack_pointer < 0:
		stack_pointer += 0x0100


func _on_stack_pop():
	stack_pointer += 1
	if stack_pointer > 0xFF:
		stack_pointer -= 0x0100


class NesRegisterFlags extends CPU.RegisterFlags:
	var C = BitFlag.new(self, &"C", 0)
	var Z = BitFlag.new(self, &"Z", 1)
	var I = BitFlag.new(self, &"I", 2)
	var D = BitFlag.new(self, &"D", 3)
	var B = BitFlag.new(self, &"B", 4)
	var B2 = BitFlag.new(self, &"B2", 5)
	var V = BitFlag.new(self, &"V", 6)
	var N = BitFlag.new(self, &"N", 7)
	var bit_flags: Dictionary = {
		C.name : C,
		Z.name : Z,
		I.name : I,
		D.name : D,
		B.name : B,
		B2.name : B2,
		V.name : V,
		N.name : N
	}
