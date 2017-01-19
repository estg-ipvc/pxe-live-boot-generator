export ROOT_DIR=${PWD}

all: build start
.PHONY: all

build:
	@echo "building"
	docker run --privileged --name live_builder -it \
		-v ${ROOT_DIR}/scripts:/scripts \
		-v ${ROOT_DIR}/tftp:/tftp debian:jessie-slim /scripts/build.sh;
	docker rm -f live_builder;

start:
	@echo "Starting up virtualized test"
	vagrant up;

stop:
	@echo "Stoping test"
	vagrant halt;

destroy:
	vagrant halt;
	vagrant destroy -f;

clean:
	@echo "Cleaning...";
	vagrant halt;
	vagrant destroy -f;
	rm -Rf .vagrant;
	rm -Rf .cache;
	rm -Rf tftp/vmlinuz tftp/initrd.img tftp/filesystem.squashfs;
	docker rm -f live_builder;
