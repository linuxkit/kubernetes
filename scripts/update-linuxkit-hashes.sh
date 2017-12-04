#!/bin/sh
set -eu

lkurl="https://github.com/linuxkit/linuxkit"

tdir=$(mktemp -d)
trap 'if [ -d "$tdir" ] ; then rm -rf $tdir; fi' EXIT

git clone $lkurl $tdir/lk

lkrev=$(git -C $tdir/lk show --oneline -s HEAD)

for i in $tdir/lk/pkg/* ; do
    if [ ! -d "$i" ] ; then
	continue
    fi

    if [ ! -f "$i/build.yml" ] ; then
	echo "$i does not contain a build.yml" >&2
	continue
    fi

    tag=$(linuxkit pkg show-tag "$i")
    echo "Updating to $tag"

    image=${tag%:*}
    sed -i -e "s,$image:[[:xdigit:]]\{40\}\(-dirty\)\?,$tag,g" yml/*.yml
done

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

git commit --only -F $tdir/commit-msg yml/*.yml
