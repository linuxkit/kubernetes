#!/bin/sh
set -eu

lkurl="https://github.com/linuxkit/linuxkit"

tdir=$(mktemp -d)
trap 'if [ -d "$tdir" ] ; then rm -rf $tdir; fi' EXIT

git clone $lkurl $tdir/lk

case $# in
    0) ;;
    1)
	git -C $tdir/lk reset --hard $1
	;;
    *)
	echo "Invalid arguments" >&2
	exit 1
	;;
esac

lkrev=$(git -C $tdir/lk show --oneline -s HEAD)

update_hash() {
    local tag=$1; shift
    echo "Updating to $tag"

    image=${tag%:*}
    sed -i -e "s,$image:[[:xdigit:]]\{40\}\(-dirty\)\?,$tag,g" $@
}

# First update alpine build bases

# Alpine base image does not use linuxkit pkg, grab the tag from versions.x86_64 instead.
if [ ! -f "$tdir/lk/tools/alpine/versions.x86_64" ] ; then
    echo "tools/alpine lacks versions.x86_64 file" >&2
    exit 1
fi
tag=$(sed -n -e '1s,^\# \(linuxkit/alpine:[[:xdigit:]]\{40\}\)-amd64$,\1,p' $tdir/lk/tools/alpine/versions.x86_64)
if [ ! -n "$tag" ] ; then
    echo "Failed to extract tools/alpine tag" >&2
    exit 1
fi
update_hash $tag pkg/*/Dockerfile

for i in $tdir/lk/pkg/* ; do
    if [ ! -d "$i" ] ; then
	continue
    fi

    if [ ! -f "$i/build.yml" ] ; then
	echo "$i does not contain a build.yml" >&2
	continue
    fi

    tag=$(linuxkit pkg show-tag "$i")
    update_hash "$tag" yml/*.yml
done

# Kernel doesn't use `linuxkit pkg` and uses a different
# tagging strategy, so we do it manually by extracting the
# "recommended" one from the toplevel linuxkit.yml
# example.
# TODO: add a target to kernel/Makefile which will show
# the recommended kernel.
tag=$(sed -n -e 's,^\s*image: \(linuxkit/kernel:.\+\)\s*,\1,p' $tdir/lk/linuxkit.yml)
if [ ! -n "$tag" ] ; then
    echo "Failed to extract kernel tag" >&2
    exit 1
fi
# Not update_hash since the tag is not a hash in this case

echo "Updating to $tag"
sed -i -e "s,linuxkit/kernel:.\+,$tag,g" yml/*.yml

# We manually construct the S-o-b because -F strips the trailing blank
# lines, meaning that with -s there is no blank between the "Commit:
# ..." and the S-o-b.
uname=$(git config --get user.name)
email=$(git config --get user.email)

cat >$tdir/commit-msg <<EOF
Updated hashes from https://github.com/linuxkit/linuxkit

Commit: $lkrev

Signed-off-by: $uname <$email>
EOF

git commit --only -F $tdir/commit-msg yml/*.yml pkg/*/Dockerfile

# Now update for the result of changes to pkg/*/Dockerfile, this is
# defered until now so we get the new hash instead of the old hash
# with a -dirty suffix.
make update-hashes
git commit --amend --only --no-edit yml/*.yml
