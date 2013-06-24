# Makefile for Sphinx documentation
#
MAKEFLAGS += -s
SHELL = bash

# You can set these variables from the command line.
PLUGIN_NAME   = dreamobjects.lrplugin
BUILDDIR      = build
BUILD_OUT     = $(BUILDDIR)/$(PLUGIN_NAME)
LUA_FILES     = $(shell ls $(PLUGIN_NAME)/*.lua)

# Beautiful colours
NO_COLOR=\x1b[0m
OK_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

OK_STRING=$(OK_COLOR)[OK]$(NO_COLOR)
ERROR_STRING=$(ERROR_COLOR)[ERRORS]$(NO_COLOR)
WARN_STRING=$(WARN_COLOR)[WARNINGS]$(NO_COLOR)

.PHONY: help clean compile init

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  release    to make a plugin release"
	@echo "  clean      remove build directory before creating release"
	@echo "  compile    compiles only lua files into the build dir"

clean:
	-rm -rf $(BUILDDIR)/*

init:
	-mkdir -p $(BUILD_OUT)

release: init compile
	@echo
	@echo "Build finished. The plugin is located in $(BUILD_OUT)"


compile:
	@echo compiling lua files...
	mkdir -p $(BUILD_OUT)
	for file in $(LUA_FILES); do \
		echo -n "compiling $$file ..." && luac -o $(BUILDDIR)/$$file ./$$file && echo -e "$(OK_STRING)"; \
	done
