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

all:
	cd src && $(MAKE) $(PLAT)

# FIXME
test: all
	mv src/llb.dylib tests/llb.dylib
	cd tests && lua test_llb.lua && lua test_module.lua

clean:
	cd src && $(MAKE) $@
