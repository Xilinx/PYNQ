pipeline {
    agent none
    environment {
        SDBUILD_DIR = "./sdbuild"
        BOARDS_DIR = "./boards"
        DOCS_DIR = "./docs"
        UBUNTU_RELEASE = "bionic"
        VERSION = "2.4"
    }
    stages {
        stage("Build documentation and board-agnostic images") {
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
                        label "image-build-2018.3"
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
                                        source /xilinx-2018.3/Vivado/2018.3/settings64.sh
                                        source /xilinx-2018.3/SDx/2018.3/settings64.sh
                                        source /petalinux-2018.3/settings.sh 
                                        petalinux-util --webtalk off
                                        make images ARCH_ONLY=${ARCH}
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
                stage("Board-agnostic image for aarch64") {
                    agent {
                        label 'image-build-2018.3'
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
                                        source /xilinx-2018.3/Vivado/2018.3/settings64.sh
                                        source /xilinx-2018.3/SDx/2018.3/settings64.sh
                                        source /petalinux-2018.3/settings.sh 
                                        petalinux-util --webtalk off
                                        make images ARCH_ONLY=${ARCH}
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
        stage("Build board-specific images and software components for SDx platform") {
            parallel {
                stage("PYNQ-Z1") {
                    agent {
                        label 'image-build-2018.3'
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
                                        source /xilinx-2018.3/Vivado/2018.3/settings64.sh
                                        source /xilinx-2018.3/SDx/2018.3/settings64.sh
                                        source /petalinux-2018.3/settings.sh 
                                        petalinux-util --webtalk off
                                        make sdx_sw all PREBUILT=${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img BOARDS=${BOARD}
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
                            }
                        }
                    }
                }
                stage("PYNQ-Z2") {
                    agent {
                        label 'image-build-2018.3'
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
                                        source /xilinx-2018.3/Vivado/2018.3/settings64.sh
                                        source /xilinx-2018.3/SDx/2018.3/settings64.sh
                                        source /petalinux-2018.3/settings.sh 
                                        petalinux-util --webtalk off
                                        make sdx_sw all PREBUILT=${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img BOARDS=${BOARD}
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
                            }
                        }
                    }
                }
                stage("ZCU104") {
                    agent {
                        label 'image-build-2018.3'
                    }
                    environment {
                        ARCH = "aarch64"
                        BOARD = "ZCU104"
                    }
                    stages {
                        stage("Fetch ZCU104 Petalinux BSP") {
                            steps {
                                sh 'cp /petalinux-bsp/xilinx-zcu104-v2018.3-final-v2.bsp ${BOARDS_DIR}/${BOARD}/'
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
                                        source /xilinx-2018.3/Vivado/2018.3/settings64.sh
                                        source /xilinx-2018.3/SDx/2018.3/settings64.sh
                                        source /petalinux-2018.3/settings.sh 
                                        petalinux-util --webtalk off
                                        make sdx_sw all PREBUILT=${UBUNTU_RELEASE}.${ARCH}.${VERSION}.img BOARDS=${BOARD}
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
                            }
                        }
                    }
                }
            }
        }
    }
}