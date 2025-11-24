CROSS:=arm-linux-gnueabihf-
DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
obj-m:=bbserial.o
ccflags-y:=-std=gnu99 -Wno-declaration-after-statement

KTAG=stable_20240529
KPKG=$(KTAG).tar.gz
KURL=https://github.com/raspberrypi/linux/archive/refs/tags/$(KPKG)
KDIR=linux-$(KTAG)
export KERNEL=kernel7

KOPTS=ARCH=arm CROSS_COMPILE=$(CROSS) -C $(KDIR)

all: $(KDIR)
	$(MAKE) $(KOPTS) M=$(DIR) modules

$(KDIR): $(KPKG)
	tar xf $(KPKG)
	$(MAKE) $(KOPTS) bcm2709_defconfig
	$(MAKE) $(KOPTS) modules_prepare
	touch $(KDIR)/Module.symvers

$(KPKG):
	wget -q  $(KURL)

clean:
	$(MAKE) $(KOPTS) M=$(DIR) clean
	rm -rf $(KDIR) $(KPKG)
