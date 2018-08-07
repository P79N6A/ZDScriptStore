#!/bin/bash

# 编译阶段在warning或error中把TODO、FIXME等标记的地方显示出来
# Reference: https://www.tuicool.com/articles/fQ7jQjm

TAGS="\/\/TODO:|\/\/FIXME:|\/\/WARNING:"
ERRORTAG="\/\/ERROR:"
find "${SRCROOT}" \( -name "*.h" -or -name "*.m" -or -name "*.swift" \) -print0 | xargs -0 egrep --with-filename --line-number --only-matching "($TAGS).*\$|($ERRORTAG).*\$" | perl -p -e "s/($TAGS)/ warning: \$1/"| perl -p -e "s/($ERRORTAG)/ error: \$1/"