# USAGE
# docker build -t fantom .
#
# The following build args are accepted, with documentation:
# - JDK_VERSION: The version of the JDK to use. Defaults to 17.
# - SWT_DL_URL: The URL to download the SWT jar from. Defaults to 4.27. Be sure that this is compatible with your JDK version.
# - REL_VERSION: The version name of Fantom to use to bootstrap. Defaults to fantom-1.0.77.
# - REL_TAG: The tag of Fantom to use to bootstrap. Be sure that matches REL_VERSION. Defaults to v1.0.77.


# ================================
# Bootstrap image
# ================================
# This image builds the local Fantom installation using the Fantom Bootstrap process.
#
# It mirrors the Bootstrap.fan script, but does not use it (since we want to use the 
# local fantom, not one pulled via git).

ARG JDK_VERSION=17

FROM eclipse-temurin:$JDK_VERSION AS bootstrap

WORKDIR /work

ARG FAN_REL_VER=1.0.82

# Build Fantom from source
RUN <<EOF
  apt-get -q update
  apt-get -q install -y curl unzip
  curl -fsSL https://github.com/fantom-lang/fantom/releases/download/v${FAN_REL_VER}/fantom-${FAN_REL_VER}.zip -o fantom.zip
  unzip fantom.zip
  mv fantom-${FAN_REL_VER} rel
  chmod +x rel/bin/*
  chmod +x rel/adm/*
EOF

COPY . ./fan/

RUN <<EOF
  echo "\n\njdkHome=${JAVA_HOME}/\ndevHome=/work/fan/\n" >> rel/etc/build/config.props
  echo "\n\njdkHome=${JAVA_HOME}/" >> fan/etc/build/config.props
  rel/bin/fan fan/src/buildall.fan superclean
  rel/bin/fan fan/src/buildboot.fan compile
  fan/bin/fan fan/src/buildpods.fan compile
EOF

# The /work/fan directory now contains a compiled version of the local Fantom

# ================================
# Run image
# ================================
# This simply copies the new Fantom into a fresh container and sets up the path.

FROM eclipse-temurin:$JDK_VERSION AS run

COPY --from=bootstrap /work/fan/ /opt/fan/

ENV PATH=$PATH:/opt/fan/bin

# Return Fantom's version
CMD ["fan","-version"]