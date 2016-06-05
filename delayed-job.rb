#!/usr/bin/env ruby

require "./crucible/config/environment"
require "delayed/worker"

Delayed::Worker.new().start
