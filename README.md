# TDT4230 - Graphics and Visualization Project

This is a project I made for TDT4230 - Graphics and Visualization Project. In this project, I have implemented a landscape consisting of a grassy field. The field is flat, making it possible to see the horizon when the camera is facing straight ahead. You can see the sky with some clouds around the field. In addition, there is a breeze that makes the grass blades sway in the wind. The breeze also makes clouds move, casting shadows on the field. The clouds are not visible, but there is possible to see the shadows translate over the field. 




### Windows

Install Microsoft Visual Studio Express and CMake.
You may use CMake-gui or the command-line cmake to generate a Visual Studio solution.

### Linux:

Make sure you have a C/C++ compiler such as  GCC, CMake and Git. The command below will run the program.

	make run

which is equivalent to

	git submodule update --init
	cd build
	cmake ..
	make
	./glowbox


### Controls

Keybinds to move freely around the scene:

- W : Move forward
- S: Move backwards
- A: Move towards the left
- D: Move towards the right
- Space: Moves up
- LShift: Moves down
- Up: Look up
- Down: Look down
- Left: Look left
- Right: Look right


