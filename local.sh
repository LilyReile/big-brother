#!/bin/bash
set -eu

sam local invoke BigBrotherFunction --no-event -n .env.json
