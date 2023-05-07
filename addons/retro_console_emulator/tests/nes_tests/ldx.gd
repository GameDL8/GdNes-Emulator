extends "res://addons/retro_console_emulator/tests/base_test.gd"


func test():
	test_0xa2_ldx_immediate_load_register_x()
	test_0xa6_ldx_zeropage_load_register_x()
	test_0xb6_ldx_zeropage_y_load_register_x()
	test_0xae_ldx_absolute_load_register_x()
	test_0xbe_ldx_absolute_y_load_register_x()


func test_0xa2_ldx_immediate_load_register_x():
	var cpu = NesCPU.new()
	cpu.load_and_run([0xa2, 0x05, 0x00])
	assert(cpu.register_x.value == 0x05)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa2, 0b10000001, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa2, 0x00, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa2_ldx_immediate_load_register_x PASSED!")


func test_0xa6_ldx_zeropage_load_register_x():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x10, 0x15)
	cpu.memory.mem_write(0x11, 0b10000001)
	cpu.memory.mem_write(0x12, 0x00)
	cpu.load_and_run([0xa6, 0x10, 0x00])
	assert(cpu.register_x.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa6, 0x11, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa6, 0x12, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xa6_ldx_zeropage_load_register_x PASSED!")


func test_0xb6_ldx_zeropage_y_load_register_x():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x10, 0x15)
	cpu.memory.mem_write(0x11, 0b10000001)
	cpu.memory.mem_write(0x12, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb6, 0x00, 0x00])
	assert(cpu.register_x.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb6, 0x01, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xb6, 0x02, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xb6_ldx_zeropage_y_load_register_x PASSED!")


func test_0xae_ldx_absolute_load_register_x():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xae, 0x10, 0x01, 0x00])
	assert(cpu.register_x.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xae, 0x11, 0x01, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xae, 0x12, 0x01, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xae_ldx_absolute_load_register_x PASSED!")


func test_0xbe_ldx_absolute_y_load_register_x():
	var cpu = NesCPU.new()
	cpu.memory.mem_write(0x0110, 0x15)
	cpu.memory.mem_write(0x0111, 0b10000001)
	cpu.memory.mem_write(0x0112, 0x00)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xbe, 0x00, 0x01, 0x00])
	assert(cpu.register_x.value == 0x15)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == false)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xbe, 0x01, 0x01, 0x00])
	assert(cpu.register_x.value == 0b10000001)
	assert(cpu.flags.Z.value == false)
	assert(cpu.flags.N.value == true)
	cpu.load_and_run([0xa9, 0x10, 0xa8, 0xbe, 0x02, 0x01, 0x00])
	assert(cpu.register_x.value == 0x00)
	assert(cpu.flags.Z.value == true)
	assert(cpu.flags.N.value == false)
	print("test_0xbe_ldx_absolute_y_load_register_x PASSED!")
