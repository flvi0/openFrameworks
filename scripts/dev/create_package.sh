#!/bin/bash
# $1 -> platform: win_cb, linux, linux64, vs, osx, ios, all
# $2 -> version number: 006
#
# This script removes folders clones the openFrameworks repo 
# and deletes parts of it to create the final package.
# Do not try to modify it to run over your local install of
# openFrameworks or it'll remove it along with any projects it
# might contain.

platform=$1
version=$2
of_root=$(readlink -f "$(dirname "$(readlink -f "$0")")/../..")

if [ $# -eq 3 ]; then
branch=$3
else
branch=stable
fi

REPO=../..
REPO_ALIAS=originlocal
BRANCH=$branch

PG_REPO=https://github.com/openframeworks/projectGenerator.git
PG_REPO_ALIAS=originhttps
PG_BRANCH=master

hostArch=`uname`

if [ "$platform" != "win_cb" ] && [ "$platform" != "linux" ] && [ "$platform" != "linux64" ] && [ "$platform" != "linuxarmv6l" ] && [ "$platform" != "linuxarmv7l" ] && [ "$platform" != "vs" ] && [ "$platform" != "osx" ] && [ "$platform" != "android" ] && [ "$platform" != "ios" ]; then
    echo usage: 
    echo ./create_package.sh platform version
    echo platform:
    echo win_cb, linux, linux64, linuxarmv6l, linuxarmv7l, vs, osx, android, ios, all
    exit 1
fi

if [ "$version" == "" ]; then
    echo usage: 
    echo ./create_package.sh platform version [branch]
    echo platform:
    echo win_cb, linux, linux64, vs, osx, android, ios, all
    echo 
    echo branch:
    echo master, stable
    exit 1
fi

echo
echo
echo
echo --------------------------------------------------------------------------
echo "Creating package $version for $platform"
echo --------------------------------------------------------------------------
echo

libsnotinmac="glu quicktime videoInput kiss"
libsnotinlinux="quicktime videoInput glut glu cairo glew openssl rtAudio"
libsnotinvs="kiss"
libsnotinmingw="kiss glut cairo glew openssl"
libsnotinandroid="glut quicktime videoInput fmodex glee rtAudio kiss cairo"
libsnotinios="glut quicktime videoInput fmodex glee rtAudio kiss cairo"

# This script removes folders clones the openFrameworks repo 
# and deletes parts of it to create the final package.
# Do not try to modify it to run over your local install of
# openFrameworks or it'll remove it along with any projects it
# might contain.
# Instead we download it in a folder with a different name so it's
# safe to delete it completely at the end
pkgfolder=openFrameworks_pkg_creation

rm -rf ${pkgfolder}
echo "Cloning OF from $REPO $BRANCH" 
git clone $REPO --depth=1 --branch=$BRANCH ${pkgfolder} 2> /dev/null
gitfinishedok=$?
if [ $gitfinishedok -ne 0 ]; then
    echo "Error connecting to github"
    exit
fi

cd ${pkgfolder}
packageroot=$PWD

cd apps
echo "Cloning project generator from $PG_REPO $PG_BRANCH" 
git clone $PG_REPO --depth=1 --branch=$PG_BRANCH 2> /dev/null
gitfinishedok=$?
if [ $gitfinishedok -ne 0 ]; then
    echo "Error connecting to github"
    exit
fi

cd $packageroot


function deleteCodeblocks {
    #delete codeblock files
    rm *.cbp
    rm *.workspace
}

function deleteMakefiles {
    #delete makefiles
    rm Makefile
    rm *.make
}

function deleteVS {
    #delete VS files
    rm *.vcxproj
    rm *.vcxproj.user
    rm *.vcxproj.filters
    rm *.sln
}

function deleteXcode {
    #delete osx files
    rm -Rf *.xcodeproj
    rm openFrameworks-Info.plist
    rm Project.xcconfig
}

function deleteEclipse {
    #delete eclipse project
    rm $(find . -name .*project)
}


function createProjectFiles {
    if [ "$pkg_platform" == "win_cb" ]; then	
        echo "Creating project files"
	    # copy config.make and Makefile into every subfolder
	    for example in $pkg_ofroot/examples/*/*; do
	        cp $pkg_ofroot/scripts/templates/win_cb/config.make ${example}
	        cp $pkg_ofroot/scripts/templates/win_cb/Makefile ${example}
	    done
    elif [ "$pkg_platform" != "android" ]; then
        cd ${main_ofroot}/apps/projectGenerator
        git pull origin master
        cd commandLine
        echo "Recompiling command line PG"
        PROJECT_OPTIMIZATION_CFLAGS_RELEASE=-O3 make -j2 > /dev/null
        cd ${pkg_ofroot}
        echo "Creating project files for $pkg_platform"
        ${main_ofroot}/apps/projectGenerator/commandLine/bin/projectGenerator --recursive -p ${pkg_platform} -o $pkg_ofroot $pkg_ofroot/examples > /dev/null
    fi
    cd ${pkg_ofroot}
}

function createPackage {
    pkg_platform=$1
    pkg_version=$2
    pkg_ofroot=$3
    main_ofroot=$4
    
    #remove previously created package 
    cd $pkg_ofroot/..
	rm -Rf of_v${pkg_version}_${pkg_platform}.*
	rm -Rf of_v${pkg_version}_${pkg_platform}_*
    echo "Creating package $pkg_platform $version in $pkg_ofroot"
    
    #remove devApps folder
    rm -r $pkg_ofroot/apps/devApps
    
    #remove projectGenerator folder
    if [ "$pkg_platform" = "android" ] || [ "$pkg_platform" = "win_cb" ]; then
    	rm -rf $pkg_ofroot/apps/projectGenerator
    fi

	cd $pkg_ofroot/examples

	#delete ios examples in other platforms
	if [ "$pkg_platform" != "ios" ]; then 
		rm -Rf ios
	fi

	#delete android examples in other platforms
	if [ "$pkg_platform" != "android" ]; then 
		rm -Rf android
	fi

	#delete desktop examples in mobile packages
	if [ "$pkg_platform" == "android" ] || [ "$pkg_platform" == "ios" ]; then 
		rm -Rf 3d
		rm -Rf addons
		rm -Rf communication
		rm -Rf empty
		rm -Rf events
		rm -Rf gl
		rm -Rf graphics
		rm -Rf math
		rm -Rf sound
		rm -Rf utils
		rm -Rf video
		rm -Rf gles
		rm -Rf gui
	fi 
	
	#delete osx examples in linux
	if [ "$pkg_platform" == "linux" ] || [ "$pkg_platform" == "linux64" ] || [ "$pkg_platform" == "linuxarmv6l" ] || [ "$pkg_platform" == "linuxarmv7l" ]; then
	    rm -Rf video/osxHighPerformanceVideoPlayerExample
	    rm -Rf video/osxVideoRecorderExample
	fi
	
	if [ "$pkg_platform" == "linux" ] || [ "$pkg_platform" == "linux64" ]; then
	    rm -Rf gles
	fi
	
	if [ "$pkg_platform" == "linuxarmv6l" ] || [ "$pkg_platform" == "linuxarmv7l" ]; then
	    rm -Rf addons/3DModelLoaderExample
        rm -Rf addons/allAddonsExample
        rm -Rf addons/assimpExample
        rm -Rf addons/kinectExample
        rm -Rf addons/vectorGraphicsExample
        
	    rm -Rf gl/glInfoExample
        rm -Rf gl/alphaMaskingShaderExample
        rm -Rf gl/billboardExample
        rm -Rf gl/billboardRotationExample
        rm -Rf gl/multiLightExample
        rm -Rf gl/multiTextureShaderExample
        rm -Rf gl/pointsAsTextures
        rm -Rf gl/gpuParticleSystemExample
        rm -Rf gl/vboMeshDrawInstancedExample
        rm -Rf gl/shaderExample
        rm -Rf gl/computeShaderParticlesExample
        rm -Rf gl/computeShaderTextureExample
        rm -Rf gl/pixelBufferExample
        rm -Rf gl/textureBufferInstancedExample
        rm -Rf gl/threadedPixelBufferExample
  
        rm -Rf utils/systemSpeakExample
        rm -Rf utils/fileBufferLoadingCSVExample
        
        rm -Rf 3d/modelNoiseExample
    fi
    
    if [ "$pkg_platform" == "linuxarmv6l" ]; then
        rm -Rf utils/dragDropExample
        rm -Rf utils/fileOpenSaveDialogExample
	fi
	
	if [ "$pkg_platform" == "win_cb" ] || [ "$pkg_platform" == "vs" ]; then
	    rm -Rf video/osxHighPerformanceVideoPlayerExample
	    rm -Rf video/osxVideoRecorderExample
	    rm -Rf gles
	fi
	
	if [ "$pkg_platform" == "osx" ]; then
	    rm -Rf gles
	    rm -Rf gl/computeShaderParticlesExample
	    rm -Rf gl/computeShaderTextureExample
	fi
	
	
	
	#delete tutorials by now
	rm -Rf $pkg_ofroot/tutorials
    
	
	
    #create project files for platform
    createProjectFiles $pkg_platform $pkg_ofroot
	

    #delete other platform libraries
    if [ "$pkg_platform" = "linux" ]; then
        otherplatforms="linux64 linuxarmv6l linuxarmv7l osx win_cb vs ios android"
    fi

    if [ "$pkg_platform" = "linux64" ]; then
        otherplatforms="linux linuxarmv6l linuxarmv7l osx win_cb vs ios android"
    fi

    if [ "$pkg_platform" = "linuxarmv6l" ]; then
        otherplatforms="linux64 linux linuxarmv7l osx win_cb vs ios android"
    fi
    
    if [ "$pkg_platform" = "linuxarmv7l" ]; then
        otherplatforms="linux64 linux linuxarmv6l osx win_cb vs ios android"
    fi
    
    if [ "$pkg_platform" = "osx" ]; then
        otherplatforms="linux linux64 linuxarmv6l linuxarmv7l win_cb vs ios android"
    fi

    if [ "$pkg_platform" = "win_cb" ]; then
        otherplatforms="linux linux64 linuxarmv6l linuxarmv7l osx vs ios android"
    fi

    if [ "$pkg_platform" = "vs" ]; then
        otherplatforms="linux linux64 linuxarmv6l linuxarmv7l osx win_cb ios android"
    fi

    if [ "$pkg_platform" = "ios" ]; then
        otherplatforms="linux linux64 linuxarmv6l linuxarmv7l win_cb vs android"
    fi

    if [ "$pkg_platform" = "android" ]; then
        otherplatforms="linux linux64 linuxarmv6l linuxarmv7l osx win_cb vs ios"
    fi
    
    
	#download and uncompress PG
	echo "Creating projectGenerator"
	mkdir -p $HOME/.tmp
	export TMPDIR=$HOME/.tmp
    if [ "$pkg_platform" = "vs" ]; then
		cd ${pkg_ofroot}/apps/projectGenerator/projectGeneratorElectron
		npm install > /dev/null
		npm run build:vs > /dev/null
		mv dist/projectGenerator-win32-ia32 ${pkg_ofroot}/projectGenerator-vs
		cd ${pkg_ofroot}
		rm -rf apps/projectGenerator
		cd ${pkg_ofroot}/projectGenerator-vs/resources/app/app/
		wget http://192.237.185.151/projectGenerator/projectGenerator-vs.zip 2> /dev/null
		unzip projectGenerator-vs.zip 2> /dev/null
		rm projectGenerator-vs.zip
		cd ${pkg_ofroot}
		sed -i "s/osx/vs/g" projectGenerator-vs/resources/app/settings.json
	fi
    if [ "$pkg_platform" = "osx" ]; then
		cd ${pkg_ofroot}/apps/projectGenerator/projectGeneratorElectron
		npm install > /dev/null
		npm run build:osx > /dev/null
		mv dist/projectGenerator-darwin-x64 ${pkg_ofroot}/projectGenerator-osx
		cd ${pkg_ofroot}
		rm -rf apps/projectGenerator
		wget http://192.237.185.151/projectGenerator/projectGenerator_osx -O projectGenerator-osx/projectGenerator.app/Contents/Resources/app/app/projectGenerator 2> /dev/null
		sed -i "s/osx/osx/g" projectGenerator-osx/projectGenerator.app/Contents/Resources/app/settings.json
	fi
    if [ "$pkg_platform" = "ios" ]; then
		cd ${pkg_ofroot}/apps/projectGenerator/projectGeneratorElectron
		npm install > /dev/null
		npm run build:osx > /dev/null
		mv dist/projectGenerator-darwin-x64 ${pkg_ofroot}/projectGenerator-ios
		cd ${pkg_ofroot}
		rm -rf apps/projectGenerator
		wget http://192.237.185.151/projectGenerator/projectGenerator_osx -O projectGenerator-ios/projectGenerator.app/Contents/Resources/app/app/projectGenerator 2> /dev/null
		sed -i "s/osx/ios/g" projectGenerator-ios/projectGenerator.app/Contents/Resources/app/settings.json
	fi
	
	if [ "$pkg_platform" = "linux" ]; then
		cd ${pkg_ofroot}/apps/projectGenerator/projectGeneratorElectron
		npm install > /dev/null
		npm run build:linux > /dev/null
		mv dist/projectGenerator-linux-ia32 ${pkg_ofroot}/projectGenerator-linux
		cd ${pkg_ofroot}
		sed -i "s/osx/linux/g" projectGenerator-linux/resources/app/settings.json
	fi
	
	if [ "$pkg_platform" = "linux64" ]; then
		cd ${pkg_ofroot}/apps/projectGenerator/projectGeneratorElectron
		npm install > /dev/null
		npm run build:linux64 > /dev/null
		mv dist/projectGenerator-linux-x64 ${pkg_ofroot}/projectGenerator-linux64
		cd ${pkg_ofroot}
		sed -i "s/osx/linux64/g" projectGenerator-linux64/resources/app/settings.json
	fi
	
	# linux remove other platform projects from PG source and copy ofxGui
	if [ "$pkg_platform" = "linux" ] || [ "$pkg_platform" = "linux64" ] || [ "$pkg_platform" = "linuxarmv6l" ] || [ "$pkg_platform" = "linuxarmv7l" ]; then
	    cd ${pkg_ofroot}
		mv apps/projectGenerator/commandLine .
		rm -rf apps/projectGenerator
		mkdir apps/projectGenerator
		mv commandLine apps/projectGenerator/
		cd apps/projectGenerator/commandLine
		deleteCodeblocks
		deleteVS
		deleteXcode
	fi

    #delete libraries for other platforms
    echo "Deleting core libraries from other platforms"
    cd $pkg_ofroot/libs  
    for lib in $( find . -maxdepth 1 -mindepth 1 -type d )
    do
        if [ -d $lib/lib ]; then
            #echo deleting $lib/lib
            cd $lib/lib
            rm -Rf $lib/lib/$otherplatforms
            cd $pkg_ofroot/libs
        fi
    done
    if [ "$pkg_platform" = "osx" ]; then
        rm -Rf $libsnotinmac
    elif [ "$pkg_platform" = "linux" ] || [ "$pkg_platform" = "linux64" ] || [ "$pkg_platform" = "linuxarmv6l" ] || [ "$pkg_platform" = "linuxarmv7l" ]; then
        rm -Rf $libsnotinlinux
    elif [ "$pkg_platform" = "win_cb" ]; then
        rm -Rf $libsnotinmingw
    elif [ "$pkg_platform" = "vs" ]; then
        rm -Rf $libsnotinvs
    elif [ "$pkg_platform" = "android" ]; then
        rm -Rf $libsnotinandroid
    elif [ "$pkg_platform" = "ios" ]; then
        rm -Rf $libsnotinios
    fi
    
    cd ${pkg_ofroot}/addons
    echo "Deleting addon libraries from other platforms"
    for lib in $( ls -d */libs/*/lib/ )
    do
        cd ${lib}
        #echo deleting $lib
        rm -Rf $otherplatforms
        cd $pkg_ofroot/addons
    done
    
	#delete ofxAndroid in non android
	if [ "$pkg_platform" != "android" ]; then
		rm -Rf ofxAndroid
		rm -Rf ofxUnitTests
	fi
	#delete ofxiPhone in non ios
	if [ "$pkg_platform" != "ios" ]; then
		rm -Rf ofxiPhone
		rm -Rf ofxiOS
		rm -Rf ofxUnitTests
	fi
	
	#delete ofxMultiTouch & ofxAccelerometer in non mobile
	if [ "$pkg_platform" != "android" ] && [ "$pkg_platform" != "ios" ]; then
		rm -Rf ofxMultiTouch
		rm -Rf ofxAccelerometer
		rm -Rf ofxUnitTests
	fi
	
	if [ "$pkg_platform" == "ios" ] || [ "$pkg_platform" == "android" ]; then
	    rm -Rf ofxVectorGraphics
   	    rm -Rf ofxKinect
		rm -Rf ofxUnitTests
	fi
	
	#delete unit tests by now
	rm -Rf ${pkg_ofroot}/tests

	#delete eclipse projects
	if [ "$pkg_platform" != "android" ] && [ "$pkg_platform" != "linux" ] && [ "$pkg_platform" != "linux64" ] && [ "$pkg_platform" != "linuxarmv6l" ] && [ "$pkg_platform" != "linuxarmv7l" ]; then
		cd ${pkg_ofroot}
		deleteEclipse
		if [ -f libs/openFrameworks/.settings ]; then
    		rm -R libs/openFrameworks/.settings
    	fi
	fi
	
	#android, move paths.default.make to paths.make
	if [ "$pkg_platform" == "android" ]; then
	    cd ${pkg_ofroot}
	    mv libs/openFrameworksCompiled/project/android/paths.default.make libs/openFrameworksCompiled/project/android/paths.make
	fi

    #delete other platforms OF project files
    cd ${pkg_ofroot}/libs/openFrameworksCompiled/lib
    rm -Rf $otherplatforms
    cd ${pkg_ofroot}/libs/openFrameworksCompiled/project
    rm -Rf $otherplatforms
    
    #remove osx in ios from openFrameworksCompiled 
    #(can't delete by default since it needs to keep things in libs for the simulator)
    if [ "$pkg_platform" = "ios" ]; then
	    rm -Rf ${pkg_ofroot}/libs/openFrameworksCompiled/lib/osx
    	rm -Rf ${pkg_ofroot}/libs/openFrameworksCompiled/project/osx
    fi

	cd ${pkg_ofroot}/libs
	#delete specific include folders non-android
	if [ "$pkg_platform" != "android" ] && [ -d */include_android ]; then
		rm -Rf $( ls -d */include_android )
	fi

	#delete specific include folders for non-ios
	if [ "$pkg_platform" != "ios" ] && [ -d */include_ios ]; then
		rm -Rf $( ls -d */include_ios )
	fi

	#delete generic includes for libs that has specific ones in android
	if [ "$pkg_platform" == "android" ] || [ "$pkg_platform" == "ios" ]; then
		rm -Rf glu/include
	fi

    #delete dynamic libraries for other platforms
    cd $pkg_ofroot/export
    rm -Rf $otherplatforms

    #delete scripts
    cd $pkg_ofroot/scripts
	if [ "$pkg_platform" != "linux64" ] && [ "$pkg_platform" != "linuxarmv6l" ] && [ "$pkg_platform" != "linuxarmv7l" ]; then
    	rm -Rf $otherplatforms
	else
    	rm -Rf win_cb vs osx ios
	fi
	
    #delete omap4 scripts for non armv7l
	if [ "$pkg_platform" = "linux64" ] || [ "$pkg_platform" = "linux" ] || [ "$pkg_platform" = "linuxarmv6l" ]; then
	    rm -Rf linux/ubuntu-omap4
	fi
	
	if [ "$pkg_platform" == "ios" ]; then
		rm -Rf osx
	fi

    #delete .svn dirs
    cd $pkg_ofroot
    rm -Rf $(find . -type d -name .svn)
    
    #delete .gitignore 
    cd $pkg_ofroot
    rm -Rf $(find . -name .gitignore)
    
    #delete dev folders
    cd ${pkg_ofroot}/scripts
    rm -Rf dev

	#delete xcode templates in other platforms
	cd $pkg_ofroot
	if [ "$pkg_platform" != "osx" ] && [ "$pkg_platform" != "ios" ]; then
		rm -Rf "xcode templates"
	fi
    echo ----------------------------------------------------------------------
    echo
    echo
    
    #choose readme
    cd $pkg_ofroot
    if [ "$platform" = "linux" ] || [ "$platform" = "linux64" ] || [ "$platform" = "linuxarmv6l" ] || [ "$platform" = "linuxarmv7l" ]; then
        cp docs/linux.md INSTALL.md
    fi
    
    if [ "$platform" = "vs" ]; then
        cp docs/visualstudio.md INSTALL.md
    fi
    
    if [ "$platform" = "win_cb" ]; then
        cp docs/codeblocks.md INSTALL.md
    fi
    
    if [ "$platform" = "osx" ] || [ "$platform" = "ios" ]; then
        cp docs/osx.md INSTALL.md
    fi

    if [ "$platform" = "android" ]; then
        cp docs/android_eclipse.md INSTALL_ECLIPSE.md
        cp docs/android_studio.md INSTALL_ANDROID_STUDIO.md
    fi
    
    rm CONTRIBUTING.md

    #copy empty example
    cd $pkg_ofroot
    mkdir -p apps/myApps 
    if [ "$pkg_platform" = "android" ]; then
        cp -r examples/android/androidEmptyExample apps/myApps/
    elif [ "$pkg_platform" = "ios" ]; then
        cp -r examples/ios/emptyExample apps/myApps/
    else
        cp -r examples/empty/emptyExample apps/myApps/
    fi
    
    #create compressed package
    if [ "$pkg_platform" = "linux" ] || [ "$pkg_platform" = "linux64" ] || [ "$pkg_platform" = "android" ] || [ "$pkg_platform" = "linuxarmv6l" ] || [ "$pkg_platform" = "linuxarmv7l" ]; then
        echo "compressing package to of_v${pkg_version}_${pkg_platform}_release.tar.gz"
        cd $pkg_ofroot/..
        mkdir of_v${pkg_version}_${pkg_platform}_release
        mv ${pkgfolder}/* of_v${pkg_version}_${pkg_platform}_release
        COPYFILE_DISABLE=true tar czf of_v${pkg_version}_${pkg_platform}_release.tar.gz of_v${pkg_version}_${pkg_platform}_release
        rm -Rf of_v${pkg_version}_${pkg_platform}_release
    else
        echo "compressing package to of_v${pkg_version}_${pkg_platform}_release.zip"
        cd $pkg_ofroot/..
        mkdir of_v${pkg_version}_${pkg_platform}_release
        mv ${pkgfolder}/* of_v${pkg_version}_${pkg_platform}_release
        zip -r of_v${pkg_version}_${pkg_platform}_release.zip of_v${pkg_version}_${pkg_platform}_release > /dev/null
        rm -Rf of_v${pkg_version}_${pkg_platform}_release
    fi
}

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   # set -u : exit the script if you try to use an uninitialized variable
set -o errexit   # set -e : exit the script if any statement returns a non-true return value

cleanup() {
    cd $packageroot/..  
    rm -rf ${pkgfolder} 
}
trap cleanup 0

error() {
  local parent_lineno="$1"
  if [[ "$#" = "3" ]] ; then
    local message="$2"
    local code="${3:-1}"
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    local code="${2:-1}"
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}
trap 'error ${LINENO}' ERR

createPackage $platform $version $packageroot $of_root    

 
