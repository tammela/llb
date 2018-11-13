#
# Lua binding for LLVM C API.
# Copyright (C) 2018 Matheus Ambrozio, Pedro Tammela, Renan Almeida.
#
# This file is part of lua-llvm-binding.
#
# lua-llvm-binding is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# lua-llvm-binding is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with lua-llvm-binding. If not, see <http://www.gnu.org/licenses/>.
#

none:
	@echo "invalid platform"

linux:
	cd src && $(MAKE) $@

macosx:
	cd src && $(MAKE) $@

format:
	clang-format -i -style=file ./src/*.c ./src/*.h

# FIXME
test: macosx
	@- mv src/llbcore.dylib tests/llbcore.dylib
	@- cp src/llb.lua       tests/llb.lua
	@- cp src/function.lua  tests/function.lua
	@- cp src/set.lua       tests/set.lua

	@- # cd tests && lua test_llb.lua
	@- # cd tests && lua test_module.lua
	@- cd tests && lua test_renan.lua

	@- rm -f tests/llbcore.dylib
	@- rm -f tests/llb.lua
	@- rm -f tests/function.lua
	@- rm -f tests/set.lua

# FIXME
test_set:
	@- cp src/set.lua tests/set.lua
	@- cd tests && lua test_set.lua
	@- rm -f tests/set.lua

clean:
	cd src && $(MAKE) $@
