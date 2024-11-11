#!/bin/bash

# minify the script

bash ./minify.sh sycamore.sh

# rename to min

mv sycamore.sh.tmp sycamore.min.sh

# minify the autocomplete script

bash ./minify sycamore-completion.bash

# rename to min

mv sycamore-completion.bash.tmp sycamore-completion.min.bash
