#
# Makefile for installing LLB
#

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Your platform. See PLATS for possible values.
PLAT= none

# Install.
BIN= bin/

# Other utilities.
FMT= clang-format -i -style=file
MKDIR= mkdir -p
RM= rm -f

# == END OF USER SETTINGS -- NO NEED TO CHANGE ANYTHING BELOW THIS LINE =======

# Convenience platforms targets.
PLATS= linux macosx

# LLB version.
V= 0.1

# Targets start here.
all: $(PLAT)

$(PLATS): format
	$(MKDIR) $(BIN)
	cd src && $(MAKE) $@
	cp src/*.lua bin/

none:
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "    $(PLATS)"

test:
	cd tests && $(MAKE)

format:
	$(FMT) ./src/*.c ./src/*.h

clean:
	$(RM) -r ./bin
	cd src && $(MAKE) $@
	cd tests && $(MAKE) $@

# list targets that do not create files (but not all makes understand .PHONY)
.PHONY: all $(PLATS) none test format clean

# (end of Makefile)
