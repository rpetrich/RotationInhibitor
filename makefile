OBJECTS=Toggle
TARGET=fs/Library/MobileSubstrate/DynamicLibraries/RotationInhibitor.dylib

export NEXT_ROOT=/var/sdk

COMPILER=arm-apple-darwin9-gcc

LDFLAGS= \
		-dynamiclib \
		-Z \
		-F/var/sdk/System/Library/Frameworks \
		-F/var/sdk/System/Library/PrivateFrameworks \
		-L/var/sdk/lib \
		-L/var/sdk/usr/lib \
		-L/usr/lib \
		-Wall -Werror \
		-framework Foundation -framework UIKit -framework CoreFoundation -framework GraphicsServices -lobjc -lsubstrate \
		-multiply_defined suppress \
		-Wl,-x,-single_module

CFLAGS= -I/var/root/Headers -I/var/sdk/include -I/var/include \
		-fno-common \
		-g0 -O2 \
		-std=c99

all:	$(TARGET)

clean:
		rm -f $(OBJECTS) $(TARGET)
		rm -rf package

%:	%.m
		$(COMPILER) -c $(CFLAGS) $(filter %.m,$^) -o $@

$(TARGET): $(OBJECTS)
		$(COMPILER) $(LDFLAGS) -o $@ $^
		ldid -S $@
		
package: $(TARGET) control
		rm -rf package
		mkdir -p package/DEBIAN
		cp -a control preinst prerm package/DEBIAN
		cp -a fs/* package
		dpkg-deb -b package $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
		
install: package
		dpkg -i $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
		respring