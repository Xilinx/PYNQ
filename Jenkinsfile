pipeline {
    agent none
    environment {
        SDBUILD_DIR = "sdbuild"
        BOARDS_DIR = "boards"
        DOCS_DIR = "docs"
        UBUNTU_RELEASE = "bionic"
        VERSION = "2.5"
        OLD_BUILD_COUNT = 3
    }
    stages {
        stage("Build board-agnostic images and documentation") {
            parallel {
                stage("Documentation") {
                    when {
                        changeset "docs/**"
                    }
                    agent {
                        label "sphinx-doc"
                    }
                    environment {
                        SPHINXOPTS = "-q -w sphinx-build.log"
                    }
                    stages {
                        stage("Install dependencies") {
                            steps {
                                dir("${DOCS_DIR}") {
                                    sh '''
                                        virtualenv --system-site-packages pyenv
                                        . pyenv/bin/activate
                                        pip3 install pandas pillow sphinx_rtd_theme
                                        pip3 install -r requirements.txt
                                    '''
                                }
                            }
                        }
                        stage("Build") {
                            steps {
                                dir("${DOCS_DIR}") {
                                    // activate virtualenv and invoke compilation
                                    sh '''
                                        . pyenv/bin/activate
                                        make SPHINXOPTS="${SPHINXOPTS}" html
                                    '''
                                }
                            }
                            post {
                                failure {
                                    dir("${DOCS_DIR}") {
                                        sh 'cat sphinx-build.log'
                                    }
                                }
                            }
                        }
                        stage("Generate HTML preview") {
                            steps {
                                dir("${DOCS_DIR}") {
                                    publishHTML([allowMissing: false,
                                                 alwaysLinkToLastBuild: false, 
                                                 keepAll: false, 
                                                 reportDir: 'build/html/', 
                                                 reportFiles: 'index.html', 
                                                 reportName: 'Generated Documentation Preview', 
                                                 reportTitles: ''])
                                }
                            }
                        }
                    }
                }
                stage("Board-agnostic image for arm") {
                    agent {
                        label "image-build"
                    }
                    environment {
                        ARCH = "arm"
                    }
                    stages {
                        stage("Build") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    // setup and invoke compilation
                                    sh '''
                                        source /opt/xilinx/2019.1/Vivado/2019.1/settings64.sh
                                        source /opt/xilinx/2019.1/SDx/2019.1/settings64.sh
                                        source /opt/petalinux/2019.1/settings.sh 
                                        petalinux-util --webtalk off
                                        make images ARCH_ONLY=${ARCH}
                                    '''
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "${SDBUILD_DIR}/output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img", onlyIfSuccessful: true
                                }
                                failure {
                                    // Print all log files produced during build process
                                    sh '''
                                        for logfile in $(find ${SDBUILD_DIR} -type f -name "*.log"); do
                                            echo "== $logfile =="
                                            echo "=============================="
                                            sudo cat $logfile
                                            echo -e "==============================\n"
                                        done
                                    '''
                                }
                            }
                        }
                        stage("Collect generated image") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    stash includes: "output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img", name: "${ARCH}-img"
                                }
                            }
                        }
                    }
                }
                stage("Board-agnostic image for aarch64 ") {
                    agent {
                        label 'image-build'
                    }
                    environment {
                        ARCH = "aarch64"
                    }
                    stages {
                        stage("Build") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    // setup and invoke compilation
                                    sh '''
                                        source /opt/xilinx/2019.1/Vivado/2019.1/settings64.sh
                                        source /opt/xilinx/2019.1/SDx/2019.1/settings64.sh
                                        source /opt/petalinux/2019.1/settings.sh 
                                        petalinux-util --webtalk off
                                        make images ARCH_ONLY=${ARCH}
                                    '''
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "${SDBUILD_DIR}/output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img", onlyIfSuccessful: true
                                }
                                failure {
                                    // Print all log files produced during build process
                                    sh '''
                                        for logfile in $(find ${SDBUILD_DIR} -type f -name "*.log"); do
                                            echo "== $logfile =="
                                            echo "=============================="
                                            sudo cat $logfile
                                            echo -e "==============================\n"
                                        done
                                    '''
                                }
                            }
                        }
                        stage("Save generated image") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    stash includes: "output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img", name: "${ARCH}-img"
                                }
                            }
                        }
                    }
                }
            }
        }
        stage("Build board-specific images") {
            parallel {
                stage("PYNQ-Z1") {
                    agent {
                        label 'image-build'
                    }
                    environment {
                        ARCH = "arm"
                        BOARD = "Pynq-Z1"
                    }
                    stages {
                        stage("Retrieve generated board-agnostic image") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    unstash "${ARCH}-img"
                                }
                            }
                        }
                        stage("Build") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    // setup and invoke compilation
                                    sh '''
                                        source /opt/xilinx/2019.1/Vivado/2019.1/settings64.sh
                                        source /opt/xilinx/2019.1/SDx/2019.1/settings64.sh
                                        source /opt/petalinux/2019.1/settings.sh 
                                        petalinux-util --webtalk off
                                        make sdx_sw all PREBUILT=output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img BOARDS=${BOARD}
                                    '''
                                }
                            }
                            post {
                                failure {
                                    // Print all log files produced during build process
                                    sh '''
                                        for logfile in $(find ${SDBUILD_DIR} -type f -name "*.log"); do
                                            echo "== $logfile =="
                                            echo "=============================="
                                            sudo cat $logfile
                                            echo -e "==============================\n"
                                        done
                                    '''
                                }
                                success {
                                    // Copy build result into build folder, move previous version in /builds/old, and
                                    // remove older builds if more than OLD_BUILD_COUNT are kept in /builds/old
                                    sh'''
                                        boardname=$(echo ${BOARD} | tr '[:upper:]' '[:lower:]' | tr - _)
                                        timestamp=$(date +'%Y_%m_%d')
                                        imagefile=${boardname}_${timestamp}.img
                                        zipfile=${boardname}_${timestamp}.zip
                                        mv ${SDBUILD_DIR}/output/${BOARD}-${VERSION}.img $imagefile
                                        zip -j $zipfile $imagefile
                                        if [ -f /builds/${boardname}_*.zip ] ; then
                                           mv /builds/${boardname}_*.zip /builds/old
                                        fi
                                        mv $zipfile /builds
                                        old_zipfiles=($(find /builds/old -type f -name "${boardname}_*.zip" | sort | cut -d' ' -f2))
                                        while [ ${#old_zipfiles[@]} -gt ${OLD_BUILD_COUNT} ] ; do
                                           rm ${old_zipfiles[0]}
                                           old_zipfiles=($(find /builds/old -type f -name "${boardname}_*.zip" | sort | cut -d' ' -f2))
                                        done
                                    '''
                                }
                            }
                        }
                    }
                }
                stage("PYNQ-Z2") {
                    agent {
                        label 'image-build'
                    }
                    environment {
                        ARCH = "arm"
                        BOARD = "Pynq-Z2"
                    }
                    stages {
                        stage("Retrieve generated board-agnostic image") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    unstash "${ARCH}-img"
                                }
                            }
                        }
                        stage("Build") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    // setup and invoke compilation
                                    sh '''
                                        source /opt/xilinx/2019.1/Vivado/2019.1/settings64.sh
                                        source /opt/xilinx/2019.1/SDx/2019.1/settings64.sh
                                        source /opt/petalinux/2019.1/settings.sh 
                                        petalinux-util --webtalk off
                                        make sdx_sw all PREBUILT=output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img BOARDS=${BOARD}
                                    '''
                                }
                            }
                            post {
                                failure {
                                    // Print all log files produced during build process
                                    sh '''
                                        for logfile in $(find ${SDBUILD_DIR} -type f -name "*.log"); do
                                            echo "== $logfile =="
                                            echo "=============================="
                                            sudo cat $logfile
                                            echo -e "==============================\n"
                                        done
                                    '''
                                }
                                success {
                                    // Copy build result into build folder, move previous version in /builds/old, and
                                    // remove older builds if more than OLD_BUILD_COUNT are kept in /builds/old
                                    sh'''
                                        boardname=$(echo ${BOARD} | tr '[:upper:]' '[:lower:]' | tr - _)
                                        timestamp=$(date +'%Y_%m_%d')
                                        imagefile=${boardname}_${timestamp}.img
                                        zipfile=${boardname}_${timestamp}.zip
                                        mv ${SDBUILD_DIR}/output/${BOARD}-${VERSION}.img $imagefile
                                        zip -j $zipfile $imagefile
                                        if [ -f /builds/${boardname}_*.zip ] ; then
                                           mv /builds/${boardname}_*.zip /builds/old
                                        fi
                                        mv $zipfile /builds
                                        old_zipfiles=($(find /builds/old -type f -name "${boardname}_*.zip" | sort | cut -d' ' -f2))
                                        while [ ${#old_zipfiles[@]} -gt ${OLD_BUILD_COUNT} ] ; do
                                           rm ${old_zipfiles[0]}
                                           old_zipfiles=($(find /builds/old -type f -name "${boardname}_*.zip" | sort | cut -d' ' -f2))
                                        done
                                    '''
                                }
                            }
                        }
                    }
                }
                stage("ZCU104") {
                    agent {
                        label 'image-build'
                    }
                    environment {
                        ARCH = "aarch64"
                        BOARD = "ZCU104"
                    }
                    stages {
                        stage("Fetch ZCU104 Petalinux BSP") {
                            steps {
                                sh 'cp /opt/petalinux-bsp/xilinx-zcu104-v2019.1-final.bsp ${BOARDS_DIR}/${BOARD}/'
                            }
                        }
                        stage("Retrieve generated board-agnostic image") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    unstash "${ARCH}-img"
                                }
                            }
                        }
                        stage("Build") {
                            steps {
                                dir("${SDBUILD_DIR}") {
                                    // setup and invoke compilation
                                    sh '''
                                        source /opt/xilinx/2019.1/Vivado/2019.1/settings64.sh
                                        source /opt/xilinx/2019.1/SDx/2019.1/settings64.sh
                                        source /opt/petalinux/2019.1/settings.sh 
                                        petalinux-util --webtalk off
                                        make sdx_sw all PREBUILT=output/${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img BOARDS=${BOARD}
                                    '''
                                }
                            }
                            post {
                                failure {
                                    // Print all log files produced during build process
                                    sh '''
                                        for logfile in $(find ${SDBUILD_DIR} -type f -name "*.log"); do
                                            echo "== $logfile =="
                                            echo "=============================="
                                            sudo cat $logfile
                                            echo -e "==============================\n"
                                        done
                                    '''
                                }
                                success {
                                    // Copy build result into build folder, move previous version in /builds/old, and
                                    // remove older builds if more than OLD_BUILD_COUNT are kept in /builds/old
                                    sh'''
                                        boardname=$(echo ${BOARD} | tr '[:upper:]' '[:lower:]' | tr - _)
                                        timestamp=$(date +'%Y_%m_%d')
                                        imagefile=${boardname}_${timestamp}.img
                                        zipfile=${boardname}_${timestamp}.zip
                                        mv ${SDBUILD_DIR}/output/${BOARD}-${VERSION}.img $imagefile
                                        zip -j $zipfile $imagefile
                                        if [ -f /builds/${boardname}_*.zip ] ; then
                                           mv /builds/${boardname}_*.zip /builds/old
                                        fi
                                        mv $zipfile /builds
                                        old_zipfiles=($(find /builds/old -type f -name "${boardname}_*.zip" | sort | cut -d' ' -f2))
                                        while [ ${#old_zipfiles[@]} -gt ${OLD_BUILD_COUNT} ] ; do
                                           rm ${old_zipfiles[0]}
                                           old_zipfiles=($(find /builds/old -type f -name "${boardname}_*.zip" | sort | cut -d' ' -f2))
                                        done
                                    '''
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}