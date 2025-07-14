#!/bin/bash

# Toggle between Go source files and their corresponding test files
toggle_go_test() {
    local current_file="$ZED_FILE"

    if [[ "$current_file" != *.go ]]; then
        echo "Current file is not a Go file, only Go files supported"
        exit 1
    fi

    local target_file

    if [[ "$current_file" == *_test.go ]]; then
        target_file="${current_file%_test.go}.go"
    else
        target_file="${current_file%.go}_test.go"
    fi

    if [[ -f "$target_file" ]]; then
        echo "Switching to $target_file"
        zed "$target_file"
    else
        # If target is a test file and doesn't exist, create it with boilerplate
        if [[ "$target_file" == *_test.go ]]; then
            echo "Creating $target_file with boilerplate..."
            local package_name=$(head -n 1 "$current_file" | grep -o 'package [a-zA-Z0-9_]*' | cut -d' ' -f2)
            cat > "$target_file" << EOF
package $package_name

import (
	"testing"
	"github.com/stretchr/testify/require"
)

func TestExample(t *testing.T) {
	t.Parallel()
	// TODO: Add test implementation
	require.Fail(t, "Not implemented")
}
EOF
            echo "Created $target_file with boilerplate"
        else
            echo "Creating $target_file..."
            touch "$target_file"
        fi
        zed "$target_file"
    fi
}

toggle_go_test
