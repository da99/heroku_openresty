
# Based on: lua_setup install openresty
#           and on:
#           https://github.com/geoffleyland/heroku-buildpack-openresty/blob/master/bin/compile

latest-ver () {
  git ls-remote -t https://github.com/openresty/openresty | cut -d'/' -f 3 | sort -r | grep -P '^v[0-9\.]+$' | head -n 1 | cut -d'v' -f2
}

current-ver () {
  $PREFIX/nginx/sbin/nginx -v 2>&1 | cut -d'/' -f2 || :
} # current-ver ()

latest-openresty-archive () {
  local VER="$1"; shift
  if [[ -z "$VER" ]]; then
    echo "-----> !!! Latest OpenResty version not found." >&2
    exit 1
  fi
  echo ""
  return 0
}

upgrade-openresty () {
  export PREFIX="$(readlink -m "$PWD/progs")"
  export LOG_PREFIX="$(readlink -m "$PWD/tmp")"

  local +x PREFIX_URL="https://openresty.org/download"

  echo "-----> Using PREFIX for OpenResty: $PREFIX"

  local +x CURRENT_VER=$(current-ver)
  local +x LATEST_VER=$(latest-ver)
  if [[ -z "$LATEST_VER" ]]; then
    exit 1
  fi

  if [[ "$CURRENT_VER" == "$LATEST_VER" ]]; then
    echo "-----> Already installed: $CURRENT_VER in $PREFIX" >&2
    exit 0
  fi

  local +x LATEST_ARCHIVE="openresty-${LATEST_VER}.tar.gz"
  local +x LATEST_DIR=$(basename "$LATEST_ARCHIVE" ".tar.gz")
  echo "-----> Downloading $LATEST_ARCHIVE... "

	cd "$CACHE_DIR"
  echo "-----> in cache directory: $PWD ["
  ls -1
  echo "-----> ]"

  if [[ ! -d ${LATEST_DIR} ]]; then
    if [[ ! -s $LATEST_ARCHIVE ]]; then
      wget --quiet $PREFIX_URL/${LATEST_ARCHIVE}
    fi
		tar -xvf ${LATEST_ARCHIVE} >/dev/null || { rm $LATEST_ARCHIVE; upgrade-openresty "$PREFIX"; exit 0; }
	fi

  cd $LATEST_DIR
  echo "-----> in openresty source directory: $PWD"

  local +x PROCS="$(grep -c '^processor' /proc/cpuinfo)"

  # NOTE: /sbin in PATH is needed because OpenResty
  # compilation requires ldconfig in PATH.
  PATH="$PATH:/sbin" ./configure                      \
    --prefix="$PREFIX"             \
    --with-http_iconv_module       \
    --without-http_redis2_module   \
    --with-pcre-jit                \
    --with-ipv6                    \
    --with-http_ssl_module         \
    --error-log-path="$LOG_PREFIX/startup.error.log" \
    --http-log-path="$LOG_PREFIX/startup.access.log"  \
    -j$(($PROCS - 1))

  make
  make install

  set "-x"
  ln -s "$PREFIX"/luajit/lib/libluajit-5.1.so.2.1.0 "$PREFIX"/luajit/lib/libluajit-5.1.so.2

} # === end function
