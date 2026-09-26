#!/bin/sh
# Build one small audiobible-shmueloff-original-<book>-<chapter> deb per
# chapter present, plus the audiobible-shmueloff-original meta package that
# carries the (small) duration CSV and Depends on every chapter package
# pinned to its exact built version. Editing one chapter's audio only
# touches that chapter's deb -- never the whole corpus.
# Usage: packaging/deb/build.sh
set -eu

cd "$(dirname "$0")/../.."
REPO_ROOT="$(pwd)"
PKG_DIR="$REPO_ROOT/debian-pkg"
rm -rf "$PKG_DIR"

DEPENDS=""
for group in $(ls *.mp3 | cut -d. -f1,2 | sort -u); do
	book=${group%.*}
	chapter=${group#*.}
	pkg="audiobible-shmueloff-original-${book}-${chapter}"
	ver="0.$(git rev-list --count HEAD -- "${group}".*.mp3)"

	CH_DIR="$PKG_DIR/${pkg}"
	mkdir -p "$CH_DIR/DEBIAN" "$CH_DIR/var/lib/audiobible/original"
	cp "${group}".*.mp3 "$CH_DIR/var/lib/audiobible/original/"
	sed -e "s/%PKG%/${pkg}/g" -e "s/%VERSION%/${ver}/g" \
	    -e "s/%BOOK%/${book}/g" -e "s/%CHAPTER%/${chapter}/g" \
	    packaging/deb/control-chapter > "$CH_DIR/DEBIAN/control"
	dpkg-deb --build --root-owner-group "$CH_DIR" "${pkg}_${ver}_all.deb"
	echo "Built ${pkg}_${ver}_all.deb"

	DEPENDS="${DEPENDS}${DEPENDS:+, }${pkg} (= ${ver})"
done

META_VERSION="0.$(git rev-list --count HEAD)"
META_DIR="$PKG_DIR/audiobible-shmueloff-original"
mkdir -p "$META_DIR/DEBIAN" "$META_DIR/var/lib/audiobible/original"
cp *.csv "$META_DIR/var/lib/audiobible/original/"
sed -e "s/^Version: .*/Version: ${META_VERSION}/" packaging/deb/control \
    | sed "/^Architecture:/a Depends: ${DEPENDS}" > "$META_DIR/DEBIAN/control"
dpkg-deb --build --root-owner-group "$META_DIR" "audiobible-shmueloff-original_${META_VERSION}_all.deb"

rm -rf "$PKG_DIR"
echo "Built audiobible-shmueloff-original_${META_VERSION}_all.deb (meta package)"
