#!/usr/bin/env bash
# Open a floating scratch-notes window: ~/.notes.txt in vim.
# Opens the file if it exists, or creates it on first save if it doesn't.
# The "notes-float" app-id is matched by a float/size/center windowrule in hyprland.conf.

exec foot --app-id=notes-float \
    --window-size-pixels=800x500 \
    vim "$HOME/.notes.txt"
