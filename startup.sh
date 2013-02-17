#!/bin/bash

ruby src/startup.rb >> weather.log &
exit $?