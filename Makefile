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

BIN= ./bin
MKDIR_P= mkdir -p

.PHONY: clean format create_dir copy_lua_files linux macosx test test_set

none:
	@echo "invalid platform"

format:
	clang-format -i -style=file ./src/*.c ./src/*.h

create_dir:
	@- ${MKDIR_P} $(BIN)

copy_lua_files:
	@- cp ./src/llb.lua ./bin/
	@- cp ./src/set.lua ./bin/

linux: format create_dir copy_lua_files
	cd src && $(MAKE) $@

macosx: format create_dir copy_lua_files
	cd src && $(MAKE) $@

# FIXME
test: copy_lua_files
	@- cd tests && lua test_renan.lua

# FIXME
test_set: copy_lua_files
	@- cd tests && lua test_set.lua

clean:
	rm -rf ./bin
	cd src && $(MAKE) $@
