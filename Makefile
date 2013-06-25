# Makefile for Sphinx documentation
#
MAKEFLAGS += -s
SHELL = bash

# You can set these variables from the command line.
PLUGIN_NAME   = dreamobjects.lrplugin
NAME          = DreamObjects
BUILDDIR      = build

# Locations and files
BUILD_OUT     = $(BUILDDIR)/$(PLUGIN_NAME)
LUA_FILES     = $(shell ls $(PLUGIN_NAME)/*.lua)
NONLUA_FILES  = $(shell ls $(PLUGIN_NAME)/ | grep -v ".lua")
VERSION       = $(shell cat $(PLUGIN_NAME)/Info.lua|grep VERSION)
MAJOR         = $(shell python -c "print '$(VERSION)'.split(',')[0].split('=')[-1]")
MINOR         = $(shell python -c "print '$(VERSION)'.split(',')[1].split('=')[-1]")
REVISION      = $(shell python -c "print '$(VERSION)'.split(',')[2].split('=')[-1]")
BUILD         = $(shell python -c "print '$(VERSION)'.split(',')[3].split('=')[-1]")

# Beautiful colours
NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
GREEN = OK_COLOR
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

OK_STRING=$(OK_COLOR)[OK]$(NO_COLOR)
ERROR_STRING=$(ERROR_COLOR)[ERRORS]$(NO_COLOR)
WARN_STRING=$(WARN_COLOR)[WARNINGS]$(NO_COLOR)

.PHONY: help clean compile init rmtmp

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  release    to make a plugin release"
	@echo "  clean      remove build directory before creating release"
	@echo "  compile    compiles only lua files into the build dir"

clean:
	-rm -rf $(BUILDDIR)/*

init:
	-mkdir -p $(BUILD_OUT)

release: init compile rmtmp
	@echo
	@echo "copying non lua files..."
	for file in $(NONLUA_FILES); do \
		echo -n "copying $$file ..." && cp -r $(PLUGIN_NAME)/$$file $(BUILD_OUT) && echo -e "$(OK_STRING)"; \
	done
	@echo -n "creating zip..."
	cd $(BUILDDIR) && zip -r $(NAME)-$(MAJOR).$(MINOR).$(REVISION).$(BUILD).zip $(PLUGIN_NAME)
	@echo -e "$(OK_STRING)"
	@echo
	@echo -e "$(OK_COLOR)Build finished. The plugin is located in $(BUILD_OUT)$(NO_COLOR)"

rmtmp:
	@echo
	@echo removing temporary files...
	echo -n "removing pyc files... " && find . -type f -name "*.py[co]" -exec rm -f \{\} \; \
		&& echo -e "$(OK_STRING)"
	echo -n "removing __pycache__ files ... " && find . -type d -name "__pycache__" -exec rm -f \{\} \; \
		&& echo -e "$(OK_STRING)"

compile:
	@echo
	@echo compiling lua files...
	mkdir -p $(BUILD_OUT)
	for file in $(LUA_FILES); do \
		echo -n "compiling $$file ..." && luac -o $(BUILDDIR)/$$file ./$$file && echo -e "$(OK_STRING)"; \
	done
