#!/bin/bash

function confirm {
    message=${1:-"Please, enter Y or y to confirm: "}
    confirmvalues=${2:-"[Yy]"}
    read -r -p "$message" response
    [[ $response =~ $confirmvalues ]] || return 1
}