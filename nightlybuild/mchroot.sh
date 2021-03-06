#! /bin/bash

#Le repertoire racine
ROOT_DIR="/root/compilation"

#Les systeme à compiler
CHROOT_DIR="$ROOT_DIR/chroot"
#repertoire cible des compilations
BUILD_AREA="$ROOT_DIR/build-area"
#le repertoire contenant les sources
SRC_DIR="/root/vcs"
#repertoire local (dans chroot) contenant les builds area
LOCAL_BUILD_AREA="/root/build-area"
#Le depôt formaté pour le web
DEPOT_DIR="$ROOT_DIR/depot"


#SOURCES[x]='vcs url_ressource target_directory_in_chroot'
SOURCES[0]='svn https://www.alternc.org/svn/ /root/vcs/'

function prepare_chroot() {

	#Traiter dans les chroot
        for dir in $(ls $CHROOT_DIR); do
                if [[ ! -d $CHROOT_DIR/$dir ]]; then
                        continue
                fi
                dist=$(echo $dir | sed 's/-.*//' )
                arch=$(echo $dir | sed 's/.*-//' )

                #Ouvrir un chroot
                SCHROOT_SESSION=$(schroot -b -c $dir)
                if [[ ! $SCHROOT_SESSION ]]; then
                        continue
                fi

       	        #Nettoyer les chroot
                chroot_run $SCHROOT_SESSION "find /tmp/ -type f -exec rm {} \;" "./"
	done;

	#Nettoyer les build-area dans les sources
#	find $SRC_DIR -iname build-area -exec rm -r {} \;

	#Purger le depot de transition
	rm -r $DEPOT_DIR
}

function get_sources() {

	 for CHROOT in $(ls $CHROOT_DIR); do
		#CHROOT=${1:-"etch-i386"}
		ELEMENTS=${#SOURCES[@]}
		for ((i=0;i<$ELEMENTS;i++)); do
			SOURCE=( `echo ${SOURCES[${i}]}` )
			VCS=${SOURCE[0]}
			SOURCE=${SOURCE[1]}
			TARGET=${SOURCE[2]}
			chroot_run $CHROOT "mkdir -p $TARGET" '/root/'
			get_$VCS $CHROOT $SOURCE $TARGET
		done
	done;
}

function get_svn() {
	chroot_run ${1} "svn cleanup ${3}" ${3}
	command="echo t |svn --force --no-auth-cache co ${2} ${3}"
	chroot_run "$1" "$command" '/root/'
}

function chroot_run() {
	SCHROOT_SESSION="${1}"
	COMMAND="${2}"
	DIR="${3}"

	echo "$COMMAND" | \
	schroot \
		-p \
		-r \
		--chroot $SCHROOT_SESSION \
		-d $DIR \
}

function create_packages() {
	rm -r $BUILD_AREA
	rm -r $DEPOT_DIR

	for dir in $(ls $CHROOT_DIR); do
        	if [[ ! -d $CHROOT_DIR/$dir ]]; then
                	continue
	        fi
	        dist=$(echo $dir | sed 's/-.*//' )
	        arch=$(echo $dir | sed 's/.*-//' )

		#Ouvrir un chroot
		SCHROOT_SESSION=$(schroot -b -c $dir)
		if [[ ! $SCHROOT_SESSION ]]; then
			continue
		fi

		CHROOT_SRC=$CHROOT_DIR/$dist-$arch$SRC_DIR
		CHROOT_BUILD_AREA=$CHROOT_DIR/$dist-$arch/$LOCAL_BUILD_AREA

		mkdir -p $BUILD_AREA/$dist-$arch
		mkdir -p $CHROOT_SRC
		mkdir -p $CHROOT_BUILD_AREA

		umount $CHROOT_BUILD_AREA
		mount --bind $BUILD_AREA/$dist-$arch $CHROOT_BUILD_AREA

		#Trouver les paquets
		for paquet in $(find $CHROOT_SRC -ipath \*/debian -printf %h\\n); do
			SVN_DIR=${paquet#$CHROOT_SRC}
			STATUT=$(basename $SVN_DIR)

			chroot_run $SCHROOT_SESSION "svn revert ./ -R" $SRC_DIR/$SVN_DIR


			if [[ $STATUT != "trunk" ]]; then
				STATUT=$(basename $(dirname $SVN_DIR))
			else
				version=( `schroot -p -r --chroot $SCHROOT_SESSION -d $SRC_DIR/$SVN_DIR -- egrep -o '\(.*\)' -m 1 debian/changelog | sed 's/(//'|sed s'/)//'` )
				chroot_run $SCHROOT_SESSION "dch -v ${version}.1~`date +%Y-%m-%d` nightly" $SRC_DIR/$SVN_DIR
				#echo "dch -l \"`date +%Y-%m-%d`\" nightly" | \
			fi

			#Construire le package
			echo $STATUT
			mkdir -p "$CHROOT_BUILD_AREA/$STATUT"
			chroot_run $SCHROOT_SESSION "svn-buildpackage -us -uc -rfakeroot --svn-move-to=$LOCAL_BUILD_AREA/$STATUT --svn-ignore" $SRC_DIR/$SVN_DIR
			chroot_run $SCHROOT_SESSION "svn revert ./ -R" $SRC_DIR/$SVN_DIR

		done

		#Fermer le chroot
		schroot -e \
			--chroot=$SCHROOT_SESSION

#		umount $CHROOT_BUILD_AREA

	done;
}

function create_apt() {
	#Création du depot
	mkdir -p $DEPOT_DIR

	for dir in $(ls $BUILD_AREA); do
        	if [[ ! -d $CHROOT_DIR/$dir ]]; then
                	continue
	        fi
        	dist=$(echo $dir | sed 's/-.*//' )
	        arch=$(echo $dir | sed 's/.*-//' )

		DEPOT_DIST=$DEPOT_DIR/dists/$dist

        	CHROOT_BUILD_AREA=$BUILD_AREA/$dist-$arch

		for dir in $(ls $CHROOT_BUILD_AREA); do

			echo $dir

			DEPOT_SRC=$DEPOT_DIST/$dir/source
			DEPOT_BIN=$DEPOT_DIST/$dir/binary-$arch/

			mkdir -p $DEPOT_SRC
			mkdir -p $DEPOT_BIN

			cd $CHROOT_BUILD_AREA/$dir
			cp *.dsc $DEPOT_BIN
			cp *.deb $DEPOT_BIN

			cp *.dsc $DEPOT_SRC
			cp *.diff.gz $DEPOT_SRC
			cp *.tar.gz $DEPOT_SRC

			cd $DEPOT_DIST/$dir/
			dpkg-scanpackages binary-$arch /dev/null dists/$dist/$dir/ | gzip -f9 > binary-$arch/Packages.gz
			dpkg-scansources source /dev/null dists/$dist/$dir/ | gzip -f9 > source/Sources.gz
			apt-ftparchive -c $ROOT_DIR/$dist-$arch-apt-ftparchive.conf release $DEPOT_BIN > $DEPOT_BIN/Release
			apt-ftparchive -c $ROOT_DIR/$dist-$arch-apt-ftparchive.conf release $DEPOT_SRC > $DEPOT_SRC/Release
		done
	done
}

prepare_chroot
get_sources
create_packages
create_apt
