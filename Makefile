# Specify bash for shell.
SHELL:=sh
SHELL:=$(shell which bash)
# Disable implicit tasks and variable
MAKEFLAGS += --no-builtin-rules --no-builtin-variables --no-print-directory
# help make
_MKHELP := @$(MAKE) -j1 -s indnt='$(indnt)\t'
################################################################
# Fixed parameters
_IMGS := u22 u20 u18 u16
_CMDS := build clean rebuild start stop restart stopall enter
_TRGS := $(foreach img,$(_CMDS),$(_IMGS:%=%_$(img)))
.PHONY: $(_TRGS) $(_IMGS) $(_CMDS)
.DEFAULT_GOAL = $(IMG)_$(CMD)
# docker image map
_IMG_u22 := ubuntu:22.04
_IMG_u20 := ubuntu:20.04
_IMG_u18 := ubuntu:18.04
_IMG_u16 := ubuntu:16.04
# describe commands
_help_cmd_describe_build := build docker image if need.
_help_cmd_describe_clean := clean docker image if need.
_help_cmd_describe_rebuild := clean and build docker.
_help_cmd_describe_start := start docker container. build if need.
_help_cmd_describe_stop := stop docker container.
_help_cmd_describe_restart := restart docker container.
_help_cmd_describe_stopall := stop all docker container.
_help_cmd_describe_enter := enter docker container. build and start if need.
################################################################
# overridable variablse
IMG ?= u22
CMD ?= enter
CUSER ?= user
INAME ?= $*
CNAME ?= $(INAME).$(notdir $(CURDIR))
_VALS := IMG CMD CUSER INAME CNAME
_help_val_describe_IMG := Default image keywords.
_help_val_describe_CMD := Default Command.
_help_val_describe_CUSER := User name in conatainer.
_help_val_describe_INAME := Operation target image name.
_help_val_describe_CNAME := Operation target container name.
################################################################
.PHONY: help _help_describe _help_imgs _help_cmds
define _help_describe
    $(indnt)make           : Run same as $(.DEFAULT_GOAL).
    $(indnt)make <os>      : Run same as <os>_$(CMD).
    $(indnt)make <cmd>     : Run same as $(IMG)_<cmd>.
    $(indnt)make <os>_<cmd>: Run <cmd> by <os> docker image.
    $(indnt)make help      : Show this help.
endef
export _help_describe
help:
	@echo -e '$(indnt)Build and run docker image image.\n'
	@echo -e "$${_help_describe}"
	@echo
	@echo -e '$(indnt)<os>: A Keyword that specifies docker base. You can choose either:'
	$(_MKHELP) _help_imgs
	@echo
	@echo -e '$(indnt)<cmd>: A command. You can choose either:'
	$(_MKHELP) _help_cmds
	@echo
	@echo -e '$(indnt)Overwritable variables:'
	$(_MKHELP) _help_vals
_help_imgs:
	@printf '$(indnt) %10.10s | %s\n' 'keywords' 'base images'
	@printf '$(indnt)================================================================\n'
	@printf '$(indnt) %10.10s | %s\n' $(foreach x,$(_IMGS),"$(x)" "$(_IMG_$(x))")
_help_cmds:
	@printf '$(indnt)%10.10s : %s\n' 'Command' 'Description'
	@printf '$(indnt)================================================================\n'
	@printf '$(indnt)%10.10s : %s\n' $(foreach x,$(_CMDS),"$(x)" "$(_help_cmd_describe_$(x))")
_help_vals:
	@printf '$(indnt)%10.10s   %-16.16s  %s\n' "Variable" "Default" "Description"
	@printf '$(indnt)================================================================\n'
	@printf '$(indnt)%10.10s = %-16.16s: %s\n' \
		$(foreach x,$(_VALS),"$(x)" "$($(x))" "$(_help_val_describe_$(x))")
################################################################
dbg = @echo $@: $^
ifimg = $(if $(shell docker image ls -q $(1)),$(2),$(3))
ifcnt = $(if $(shell docker ps -qf name=$(1)),$(2),$(3))
CWD ?= $(PWD)
################################################################
build: $(IMG)_build
$(_IMGS:%=%_build): %_build:
	$(call ifimg,$(INAME),,\
		docker build -q -t $(INAME) --build-arg BASE_IMAGE=$(_IMG_$*) .)
clean: $(IMG)_clean
$(_IMGS:%=%_clean): %_clean: %_stop
	$(call ifimg,$(INAME),	docker rmi $(INAME))
rebuild: $(IMG)_rebuild
$(_IMGS:%=%_rebuild): %_rebuild:
	$(MAKE) $*_clean
	$(MAKE) $*_build
################################################################
start: $(IMG)_start
$(_IMGS:%=%_start): %_start: %_build
	$(call ifcnt,$(CNAME),, 			\
		docker run --rm -itd --name $(CNAME) 	\
			-v $(CWD):/work:ro		\
			-e "TERM=$(TERM)"		\
			-e "CUSER=$(CUSER)"		\
			--workdir=/work			\
			"$(INAME)")
	@while [[ -z "$$(docker ps -qf name=$(INAME))" ]]; do	\
		echo wait start...; sleep 0.5; 			\
	done
stop: $(IMG)_stop
$(_IMGS:%=%_stop): %_stop:
	$(call ifcnt,$(CNAME),docker stop $(CNAME))
	@while [[ -n "$$(docker ps -qf name=$(INAME))" ]]; do	\
		echo wait stop...; sleep 0.5; 			\
	done
stopall: $(_IMGS:%=%_stop)
restart: $(IMG)_restart
$(_IMGS:%=%_restart): %_restart:
	$(MAKE) $*_stop
	$(MAKE) $*_start
################################################################
$(_IMGS): %: %_enter
enter: $(IMG)_enter
$(_IMGS:%=%_enter): %_enter: %_start
	docker exec -u $(CUSER) --workdir=/home/$(CUSER) -it $(CNAME) /bin/bash
