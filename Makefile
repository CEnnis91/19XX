all:
	# assemble rom
	tools/_bass -o roms/19XXCE.z64 19XXCE.asm -sym CE.log
	tools/_bass -o roms/19XXTE.z64 19XXTE.asm -sym TE.log

	# update checksum
	tools/n64crc roms/19XXCE.z64 > /dev/null
	tools/n64crc roms/19XXTE.z64 > /dev/null

build:
	# clean
	make clean

	# build tools
	cd tools; make
	cp tools/bass/bass/bass tools/_bass

	# remove bass git repository
	rm -rf tools/bass

scrub:
	# remove patches
	rm -rf patches/*.xdelta

clean:
	# remove roms
	rm -rf roms/19XX*.z64

	# remove patches
	rm -rf patches/19XX*.xdelta

	# remove log files
	rm -rf *.log

	# remove bass github repository
	rm -rf tools/bass

	# remove executables
	rm -rf tools/*.exe
	rm -rf tools/_bass
	rm -rf tools/n64crc

	# remove patches
	make scrub

release:
	# create patch files
	xdelta3 -e -f -s roms/original.z64 roms/19XXCE.z64 patches/19XXCE.xdelta
	xdelta3 -e -f -s roms/original.z64 roms/19XXTE.z64 patches/19XXTE.xdelta