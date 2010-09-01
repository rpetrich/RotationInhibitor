TWEAK_NAME = RotationInhibitor
RotationInhibitor_OBJC_FILES = Toggle.m
RotationInhibitor_FRAMEWORKS = Foundation UIKit
RotationInhibitor_PRIVATE_FRAMEWORKS = GraphicsServices

ADDITIONAL_CFLAGS = -std=c99

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
