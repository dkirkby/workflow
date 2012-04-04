#!/bin/bash

###########################################################################################
## Creates a set of git repositories for the same package to exercise the
## gitopic script for managing topic branches in a collaborative environment.
##
## Usage: ./sandbox.sh <name> <stage>
##
## where <name> is the package name to use (creates repos <name>.alice,
## <name>.bob and <name>.remote) and <stage> = 1-9 specifies how far to go through the
## scripted stages of building the package. See the comments below for a description
## of what each stage does. Uses gitopic from the current directory.
##
## Created 4-Apr-2012 by David Kirkby (University of California, Irvine) <dkirkby@uci.edu>
###########################################################################################

pkg=$1
stage=$2
root=$PWD
seqno=0

set +o noclobber

## Macro to commit a change to the specified file in the specified repo
commit() {
    file=$1
    repo=$2
    cd $repo
    if [ ! -f $file ]
    then
        touch $file
    fi
    let "seqno += 1"
    echo $seqno >> $file
    git add $file
    git commit --quiet -m "Commit $seqno"
}

###############################################################################
## Stage 1: create a new package for bob and a remote repo that he uses
## to collaborate with alice.
###############################################################################

# create bob's repo
bob="$root/$pkg.bob"
if [ -d $bob ]
then
    rm -rf $bob
fi
git init $bob

# create the remote repo
remote="$root/$pkg.remote"
if [ -d $remote ]
then
    rm -rf $remote
fi
git init --bare $remote

# bob does some initial commits to the new package
commit file $bob
commit file $bob

# link bob's repo to the remote repo
cd $bob
git remote add origin $remote

# bob pushes his initial commits to the remote repo
git push --quiet origin master

# set our local pointer to the remote's default branch (now it has one)
# (if you don't do this, you won't see origin/HEAD in bob's SourceTree view)
git remote set-head origin --auto

# alice clones the remote repo
alice="$root/$pkg.alice"
if [ -d $alice ]
then
    rm -rf $alice
fi
git clone $remote $alice

if [ "$stage" -eq 1 ] ; then exit ; fi

###############################################################################
## Stage 2: bob and alice both create topic branches
###############################################################################

sleep 1

cd $bob
../gitopic --open Topic_A

commit fileA $bob
commit fileA $bob
git push --quiet

sleep 1

# similarly for alice

cd $alice
../gitopic --open Topic_B

commit fileBC $alice
commit fileBC $alice
git push --quiet

cd $bob
git fetch --quiet --prune

if [ "$stage" -eq 2 ] ; then exit ; fi

###############################################################################
## Stage 3: bob merges his completed topic A back into master
###############################################################################

sleep 1

cd $bob
cat > /tmp/topicA.txt <<EOT
Add feature set A

More details about feature set A here...
EOT
../gitopic -d --close /tmp/topicA.txt

cd $alice
git fetch --quiet --prune

if [ "$stage" -eq 3 ] ; then exit ; fi

###############################################################################
## Stage 4: bob creates a new topic C starting from the updated master
###############################################################################

sleep 1

cd $bob
../gitopic --open Topic_C

commit fileBC $bob
commit fileBC $bob
git push --quiet

cd $alice
git fetch --quiet --prune

if [ "$stage" -eq 4 ] ; then exit ; fi

###############################################################################
## Stage 5: alice rebases her topic B on top of the newly completed topic A
###############################################################################

sleep 1

cd $alice
../gitopic --update

commit fileBC $alice
git push --quiet

cd $bob
git fetch --quiet --prune

if [ "$stage" -eq 5 ] ; then exit ; fi

###############################################################################
## Stage 6: alice merges her completed topic B back into master
###############################################################################

sleep 1

cd $alice
cat >topicB.txt <<EOT
Add feature set B

More details about feature set B here...
EOT
../gitopic --close topicB.txt

cd $bob
git fetch --quiet --prune

if [ "$stage" -eq 6 ] ; then exit ; fi

###############################################################################
## Stage 7: bob tries to rebase his topic C on top of topic B,
## which leads to a conflict
###############################################################################

sleep 1

cd $bob
../gitopic --update

if [ "$stage" -eq 7 ] ; then exit ; fi

###############################################################################
## Stage 8: resolve the conflict between topics B and C and finish the rebase
###############################################################################

cd $bob
git checkout --theirs fileBC
git add fileBC
git rebase --continue

git push --force origin Topic_C

cd $alice
git fetch --quiet --prune

if [ "$stage" -eq 8 ] ; then exit ; fi

###############################################################################
## Stage 9: alice merges her completed topic B back into master
###############################################################################

sleep 1

cd $bob
cat >topicC.txt <<EOT
Add feature set C

More details about feature set C here...
EOT
../gitopic --close topicC.txt

cd $alice
git fetch --quiet --prune
